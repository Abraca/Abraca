# Copyright (c) 2008-2010, Abraca Team
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
	class Dependency(object):
		Mandatory = True
		Optional = False

	def __init__(self, *args, **kwargs):
		variables = [
			'VALAC', 'CC', 'AS', 'LINKFLAGS', 'PKG_CONFIG_FLAGS',
			'PKG_CONFIG', 'PROGSUFFIX', 'CPPPATH', 'MSGFMT',
		]
		for key in variables:
			val = self._import_variable(key)
			if val:
				kwargs[key] = [val]

		kwargs['tools'] = ['gcc', 'gnulink', 'gas']

		SConsEnvironment.__init__(self, *args, **kwargs)

		self._merge_path_from_environment()

		# Import pkg-config path into shell environment.
		for name in ['PKG_CONFIG_LIBDIR', 'PKG_CONFIG_PATH']:
			val = self._import_variable(name)
			if val:
				self['ENV'][name] = val
				break

		# Oldest usable SCons version.
		self.EnsureSConsVersion(0, 97)

		# Load the custom vala builder
		self.Tool('vala')
		self.Tool('gzip')
		self.Tool('msgfmt')
		self.Tool('gdkpixbufcsource')
		self.Tool('binaryblob')

		# Beef up performance a bit by caching implicit deps
		self.SetOption('implicit_cache', True)

		# Add some build options
		opts = Options(['.scons_options'], ARGUMENTS)
		opts.AddOptions(
			BoolOption('verbose', 'verbose output', 'no'),
			BoolOption('debug', 'build debug variant', 'yes'),
			PathOption('DESTDIR', 'staged install prefix', None,
			           PathOption.PathAccept),
			PathOption('PREFIX', 'install prefix', '/usr/local',
			           PathOption.PathAccept),
			PathOption('BINDIR', 'bin dir', '$PREFIX/bin',
			           PathOption.PathAccept),
			PathOption('DATADIR', 'data dir', '$PREFIX/share',
			           PathOption.PathAccept),
			PathOption('LOCALEDIR', 'locale dir', '$DATADIR/locale',
			           PathOption.PathAccept),
			PathOption('MANDIR', 'man page dir', '$DATADIR/man',
			           PathOption.PathAccept),
		)
		opts.Update(self)
		opts.Save('.scons_options', self)

		self.Help(opts.GenerateHelpText(self))

		# Hide compiler command line if silent mode on
		if not self['verbose']:
			self['VALADEFINESCOMSTR'] = '    Defines: $TARGET'
			self['VALACOMSTR']        = ' Generating: $TARGETS'
			self['CCCOMSTR']          = '   Building: $TARGET'
			self['SHCCCOMSTR']        = '   Building: $TARGET'
			self['LINKCOMSTR']        = '    Linking: $TARGET'
			self['MSGFMTCOMSTR']      = '   Localize: $TARGET'
			self['STRIPCOMSTR']       = '  Stripping: $TARGET'
			self['GDKPBUFCOMSTR']     = '  Embedding: $SOURCES'
			self['BINARYBLOBCOMSTR']  = '  Embedding: $SOURCES'
			self['ASCOMSTR']          = ' Assembling: $SOURCES'
			self['GZIPCOMSTR']        = 'Compressing: $SOURCE'

		self.SConsInstall = self.Install
		self.Install = self._install

		self.SConsInstallAs = self.InstallAs
		self.InstallAs = self._install_as

		self['BUILDERS']['SConsProgram'] = self['BUILDERS']['Program']
		self['BUILDERS']['Program'] = self._program

		self._update_worker_count()

	def _merge_path_from_environment(self):
		scons_env = set(self["ENV"]["PATH"].split(os.path.pathsep))
		host_env = set(os.environ["PATH"].split(os.path.pathsep))

		scons_env.update(host_env)

		self["ENV"]["PATH"] = os.path.pathsep.join(scons_env)

	def _update_worker_count(self):
		try:
			fd = file("/proc/cpuinfo", "r")
			data = fd.read()
			fd.close()

			cpus = len(re.findall("processor\t: \d+", data))
			if cpus > 1:
				cpus += 1

			self.SetOption('num_jobs', cpus)
		except Exception, e:
			pass

	def _to_define(self, name):
		return 'HAVE_' + ''.join(x.isalnum() and x or '_' for x in name).upper()

	def _program(self, target, source, *args, **kwargs):
		prog = self['BUILDERS']['SConsProgram'](target, source, *args, **kwargs)

		if not self.DebugVariant():
			self.AddPostAction(prog, self.Strip)

		if kwargs.get('install'):
			if isinstance(kwargs.get('install'), basestring):
				destdir = kwargs['install']
			else:
				destdir = '$BINDIR'
			self.Alias('install', self.Install(destdir, prog))

	def _install(self, dst, src):
		if self.has_key('DESTDIR') and self['DESTDIR']:
			dst = os.path.join(self['DESTDIR'], dst)
		return self.SConsInstall(dst, src)

	def _install_as(self, dst, src):
		if self.has_key('DESTDIR') and self['DESTDIR']:
			dst = os.path.join(self['DESTDIR'], dst)
		return self.SConsInstallAs(dst, src)

	def InstallMan(self, source):
		assert(str(source).count('.') == 2)
		name, section, ext = str(source).split('.', 2)
		self.Alias('install', self.Install(os.path.join('$MANDIR/man%s' % section), source))

	def InstallData(self, target, source):
		self.Alias('install', self.Install(os.path.join('$DATADIR', target), source))

	def InstallLocale(self, target, source):
		self.Alias('install', self.InstallAs(os.path.join('$LOCALEDIR', target), source))

	def InstallGladeUiModule(self, source):
		cmd = self.subst('pkg-config $PKG_CONFIG_FLAGS --variable=moduledir gladeui-1.0')
		target = AbracaEnvironment.Run(cmd)
		if not target:
			raise SCons.Errors.UserError('Glade module directory could not be determined')
		self.Alias('install', self.Install(target, source))

	def InstallGladeUiCatalog(self, source):
		cmd = self.subst('pkg-config $PKG_CONFIG_FLAGS --variable=catalogdir gladeui-1.0')
		target = AbracaEnvironment.Run(cmd)
		if not target:
			raise SCons.Errors.UserError('Glade catalog directory could not be determined')
		self.Alias('install', self.Install(target, source))

	def InstallGladeUiPixmap(self, size, source):
		if size not in ('16x16', '22x22'):
			raise SCons.Errors.UserError('Unsupported size for glade pixmap: %r' % size)
		cmd = self.subst('pkg-config $PKG_CONFIG_FLAGS --variable=pixmapdir gladeui-1.0')
		target = AbracaEnvironment.Run(cmd)
		if not target:
			raise SCons.Errors.UserError('Glade pixmap directory could not be determined')
		self.Alias('install', self.Install(os.path.join(target, 'hicolor', size, 'actions'), source))

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
				'CheckGitVersion' : AbracaEnvironment.CheckGitVersion,
				'CheckPkgConfig' : AbracaEnvironment.CheckPkgConfig,
				'CheckPkg' : AbracaEnvironment.CheckPkg,
				'CheckVala' : AbracaEnvironment.CheckVala,
				'CheckCCompiler' : AbracaEnvironment.CheckCCompiler,
				'CheckApp' : AbracaEnvironment.CheckApp,
				'CheckOS': AbracaEnvironment.CheckOS,
			}
		)
		return conf

	def DebugVariant(self):
		return self['debug']

	def AppendPkg(self, pkg, version):
		cmd = self.subst('pkg-config $PKG_CONFIG_FLAGS --libs --cflags "%s >= %s"')
		self.ParseConfig(cmd % (pkg, version))
		define = self._to_define(pkg)
		self.Append(VALAFLAGS = ['--define=' + define])
		self.Append(CPPDEFINES = [define])

	def CheckGitVersion(ctx, fail=True):
		ctx.Message('Checking for git version... ')
		output = AbracaEnvironment.Run("git describe")
		ctx.Result(output)
		if output and (output != ctx.env['VERSION']):
			ctx.env.Replace(VERSION = output)
		return output
	CheckGitVersion = staticmethod(CheckGitVersion)

	def CheckPkgConfig(ctx, fail=True):
		ctx.Message('Checking for pkg-config... ')
		cmd = ctx.env.subst('pkg-config $PKG_CONFIG_FLAGS --version')
		exit_code, output = ctx.TryAction(cmd)
		ctx.Result(exit_code)
		if not exit_code and fail:
			raise SCons.Errors.UserError('The pkg-config tool is required to build')
		return exit_code
	CheckPkgConfig = staticmethod(CheckPkgConfig)

	def CheckPkg(ctx, pkg, version='0.0', fail=True):
		if not fail:
			optional = ' (optional)'
		else:
			optional = ''
		ctx.Message('Checking for %s >= %s%s... ' % (pkg, version, optional))
		cmd = ctx.env.subst('pkg-config $PKG_CONFIG_FLAGS --exists "%s >= %s"')
		if not fail:
			cmd += ' --silence-errors'
		exit_code, output = ctx.TryAction(cmd % (pkg, version))
		ctx.Result(exit_code)
		if not exit_code and fail:
			raise SCons.Errors.UserError('The %s package and its dependencies are required to build' % pkg)
		define = ctx.env._to_define(pkg)
		ctx.env[define] = exit_code and True
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
		min_version_breakdown = map(int, re.findall('[0-9]+', min_version))

		if not SCons.Util.is_String(min_version):
			raise SCons.Errors.UserError('valac min version needs to be a string')
		ctx.Message('Checking for valac >= %s... ' % min_version)
		cmd = ctx.env.subst('$VALAC --version')
		try:
			output = AbracaEnvironment.Run(cmd)
			res = map(int, re.findall('[0-9]+', output))
		except OSError:
			ctx.Result(0)
			raise SCons.Errors.UserError('No vala compiler found')

		if res >= min_version_breakdown:
			ctx.Result(1)
		else:
			ctx.Result(0)
			if fail:
				raise SCons.Errors.UserError('The vala compiler needs to be of version %s or newer' % min_version)
		return False
	CheckVala = staticmethod(CheckVala)

	def CheckOS(ctx):
		ctx.Message('Checking for operating system... ')
		for macro in ('G_OS_UNIX', 'G_OS_WIN32', 'G_OS_BEOS'):
			code = '''
#include <glib.h>

int main() {
#ifndef %s
	#error Wrong operating system
#endif
	return 0;
}''' % macro
			if ctx.TryCompile(code, '.c'):
				ctx.env['VALAFLAGS'] += ['--define=' + macro]
				ctx.Result(macro.split('_')[-1].lower())
				return
		ctx.Result('unknown')
	CheckOS = staticmethod(CheckOS)

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
		AbracaEnvironment.Run(['strip', target[0].path])
	Strip = SCons.Action.Action(Strip, '$STRIPCOMSTR')

	def Run(cmd, shell=False):
		proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
		return proc.communicate()[0].strip()
	Run = staticmethod(Run)

SCons.Script._SConscript.BuildDefaultGlobals()
SCons.Script._SConscript.GlobalDict["AbracaEnvironment"] = AbracaEnvironment
