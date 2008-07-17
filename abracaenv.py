# Copyright (c) 2008, Abraca Team
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import SCons
from SCons.Script import ARGUMENTS
from SCons.Script.SConscript import SConsEnvironment
from SCons.Options import Options, PathOption, BoolOption

import os
import re
import subprocess

# We don't care about having Program for example
# accessible detached from an environment.
SCons.Defaults.DefaultEnvironment(tools = [])

class AbracaEnvironment(SConsEnvironment):
	def __init__(self, *args, **kwargs):
		variables = [
			'VALAC', 'CC', 'LINKFLAGS', 'PKG_CONFIG_FLAGS',
			'PROGSUFFIX', 'CPPPATH', 'MSGFMT',
		]
		for key in variables:
			val = self._import_variable(key)
			if val:
				kwargs[key] = [val]

		kwargs['tools'] = ['gcc', 'gnulink']

		SConsEnvironment.__init__(self, *args, **kwargs)

		# Import pkg-config path into shell environment.
		for name in ['PKG_CONFIG_LIBDIR', 'PKG_CONFIG_PATH']:
			val = self._import_variable(name)
			if val:
				self['ENV'][name] = val
				break

		# Oldest usable SCons version.
		self.EnsureSConsVersion(0, 97)

		# Load the custom vala builder
		self.Tool('vala', toolpath=['scons-tools'])
		self.Tool('msgfmt', toolpath=['scons-tools'])
		self.Tool('gdkpixbufcsource', toolpath=['scons-tools'])

		# Beef up performance a bit by caching implicit deps
		self.SetOption('implicit_cache', True)

		# Add some build options
		opts = Options(['.scons_options'], ARGUMENTS)
		opts.AddOptions(
			BoolOption('verbose', 'verbose output', 'no'),
			BoolOption('debug', 'build debug variant', 'no'),
			PathOption('DESTDIR', 'staged install prefix', None, PathOption.PathAccept),
			PathOption('PREFIX', 'install prefix', '/usr/local', PathOption.PathIsDirCreate),
			PathOption('BINDIR', 'bin dir', '$PREFIX/bin', PathOption.PathIsDirCreate),
			PathOption('DATADIR', 'data dir', '$PREFIX/share', PathOption.PathIsDirCreate),
			PathOption('LOCALEDIR', 'locale dir', '$DATADIR/locale', PathOption.PathIsDirCreate),
		)
		opts.Update(self)
		opts.Save('.scons_options', self)

		self.Help(opts.GenerateHelpText(self))

		# Hide compiler command line if silent mode on
		if not self['verbose']:
			self['VALADEFINESCOMSTR'] = '   Defines: $TARGET'
			self['VALACOMSTR']        = 'Generating: $TARGETS'
			self['CCCOMSTR']          = '  Building: $TARGET'
			self['LINKCOMSTR']        = '   Linking: $TARGET'
			self['MSGFMTCOMSTR']      = '  Localize: $TARGET'
			self['STRIPCOMSTR']       = ' Stripping: $TARGET'
			self['GDKPBUFCOMSTR']     = ' Embedding: $SOURCES'

		self.SConsInstall = self.Install
		self.Install = self._install

		self.SConsInstallAs = self.InstallAs
		self.InstallAs = self._install_as

	def _install(self, dst, src):
		if self.has_key('DESTDIR') and self['DESTDIR']:
			PathOption.PathIsDirCreate('DESTDIR', self['DESTDIR'], self)
			dst = os.path.join(self['DESTDIR'], dst)
		return self.SConsInstall(dst, src)

	def _install_as(self, dst, src):
		if self.has_key('DESTDIR') and self['DESTDIR']:
			PathOption.PathIsDirCreate('DESTDIR', self['DESTDIR'], self)
			dst = os.path.join(self['DESTDIR'], dst)
		return self.SConsInstallAs(dst, src)

	def _import_variable(self, name):
		if ARGUMENTS.has_key(name):
			value = ARGUMENTS.get(name)
		elif os.environ.has_key(name):
			value = os.environ.get(name)
		else:
			value = None

		return value

	def Configure(self, config_h):
		conf = SConsEnvironment.Configure(self,
			clean = False, help = False,
			config_h = config_h,
			custom_tests = {
				'CheckPkgConfig' : AbracaEnvironment.CheckPkgConfig,
				'CheckPkg' : AbracaEnvironment.CheckPkg,
				'CheckVala' : AbracaEnvironment.CheckVala,
				'CheckCCompiler' : AbracaEnvironment.CheckCCompiler,
				'CheckApp' : AbracaEnvironment.CheckApp,
			}
		)
		return conf

	def DebugVariant(self):
		return self['debug']

	def AppendPkg(self, pkg):
		cmd = self.subst('pkg-config $PKG_CONFIG_FLAGS --libs --cflags %s')
		self.ParseConfig(cmd % pkg)

	def CheckPkgConfig(ctx, fail=True):
		ctx.Message('Checking for pkg-config... ')
		cmd = ctx.env.subst('pkg-config $PKG_CONFIG_FLAGS --version')
		exit_code, output = ctx.TryAction(cmd)
		ctx.Result(exit_code)
		if not exit_code and fail:
			raise SCons.Errors.UserError('The pkg-config tool is required to build')
		return exit_code
	CheckPkgConfig = staticmethod(CheckPkgConfig)

	def CheckPkg(ctx, pkg, fail=True):
		ctx.Message('Checking for %s... ' % pkg)
		cmd = ctx.env.subst('pkg-config $PKG_CONFIG_FLAGS --exists \'%s\'')
		exit_code, output = ctx.TryAction(cmd % pkg)
		ctx.Result(exit_code)
		if not exit_code and fail:
			raise SCons.Errors.UserError('The %s package and its dependencies are required to build' % pkg)
		return exit_code
	CheckPkg = staticmethod(CheckPkg)

	def CheckCCompiler(ctx, fail=True):
		ctx.Message('Checking for compiler... ')
		code = 'int main (int argc, char **argv) { return 0; }'
		exit_code = ctx.TryCompile(code, '.c')
		ctx.Result(exit_code)
		if not exit_code and fail:
			raise SCons.Errors.UserError('The c compiler is required to build')
		return exit_code
	CheckCCompiler = staticmethod(CheckCCompiler)

	def CheckVala(ctx, min_version, fail=True):
		if not SCons.Util.is_String(min_version):
			raise SCons.Errors.UserError('valac min version needs to be a string')
		ctx.Message('Checking for valac >= %s... ' % min_version)
		cmd = ctx.env.subst('$VALAC')
		try:
			proc = subprocess.Popen([cmd, '--version'], stdout=subprocess.PIPE)
			proc.wait()
			res = re.findall('([0-9](\.[0-9])*)$', proc.stdout.read())
		except OSError:
			ctx.Result(0)
			raise SCons.Errors.UserError('No vala compiler found')

		if res and res[0] and res[0][0] >= min_version:
			ctx.Result(1)
		else:
			ctx.Result(0)
			if fail:
				raise SCons.Errors.UserError('The vala compiler needs to be of version %s or newer' % min_version)
		return False
	CheckVala = staticmethod(CheckVala)

	def CheckApp(ctx, app, fail=False):
		ctx.Message('Checking for %s... ' % app)
		key = 'HAVE_' + app.replace('-', '_').upper()
		if ctx.env.Detect(app):
			ctx.env[key] = True
		else:
			ctx.env[key] = False
		ctx.Result(ctx.env[key])
		return ctx.env[key]
	CheckApp = staticmethod(CheckApp)

	def Strip(source, target, env):
		proc = subprocess.Popen(['strip', target[0].path])
		proc.wait()
	Strip = SCons.Action.Action(Strip, '$STRIPCOMSTR')

