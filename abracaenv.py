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

# We don't care about having Program for example
# accessible detached from an environment.
SCons.Defaults.DefaultEnvironment(tools = [])

class AbracaEnvironment(SConsEnvironment):
	def __init__(self, *args, **kwargs):
		variables = [
			'VALAC', 'CC', 'LINKFLAGS', 'PKG_CONFIG_FLAGS', 'PROGSUFFIX'
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

		# Beef up performance a bit by caching implicit deps
		self.SetOption('implicit_cache', True)

		# Add some build options
		opts = Options(['.scons_options'], ARGUMENTS)
		opts.AddOptions(
			BoolOption('verbose', 'build silently', 'yes'),
			BoolOption('debug', 'build debug variant', 'no'),
			PathOption('PREFIX', 'install prefix', '/usr/local'),
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

	def _import_variable(self, name):
		if ARGUMENTS.has_key(name):
			value = ARGUMENTS.get(name)
		elif os.environ.has_key(name):
			value = os.environ.get(name)
		else:
			value = None

		return value

	def Configure(self):
		conf = SConsEnvironment.Configure(self, custom_tests = {
			'CheckPkgConfig' : AbracaEnvironment.CheckPkgConfig,
			'CheckPkg' : AbracaEnvironment.CheckPkg,
			'CheckVala' : AbracaEnvironment.CheckVala,
			'CheckCCompiler' : AbracaEnvironment.CheckCCompiler,
		})
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

	def CheckVala(ctx, fail=True):
		ctx.Message('Checking for valac... ')
		code = 'public class Test { public static void main (string[] args) { } }'
		exit_code = ctx.TryBuild(ctx.env.Vala, code, '.vala')
		ctx.Result(exit_code)
		if not exit_code and fail:
			raise SCons.Errors.UserError('The valac compiler is required to build')
		return exit_code
	CheckVala = staticmethod(CheckVala)
