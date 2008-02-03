import SCons

def CheckPkgConfig(ctx):
	ctx.Message('Checking for pkg-config... ')
	exit_code, output = ctx.TryAction('pkg-config --version')
	ctx.Result(exit_code)
	return exit_code

def CheckPkg(ctx, name):
	ctx.Message('Checking for %s... ' % name)
	exit_code, output = ctx.TryAction('pkg-config --exists \'%s\'' % name)
	ctx.Result(exit_code)
	return exit_code

def CheckGCC(ctx):
	ctx.Message('Checking for compiler... ')
	code = 'int main (int argc, char **argv) { return 0; }'
	exit_code = ctx.TryCompile(code, '.c')
	ctx.Result(exit_code)
	return exit_code

def CheckVala(ctx):
	ctx.Message('Checking for valac... ')
	code = 'public class Test { public static void main (string[] args) { } }'
	exit_code = ctx.TryBuild(ctx.env.Vala, code, '.vala')
	ctx.Result(exit_code)
	return exit_code

env = Environment()

# Oldest usable SCons version.
env.EnsureSConsVersion(0, 97)

# Load the custom vala builder
env.Tool('vala', toolpath=['scons-tools'])

# Add some build options
opts = Options(['.scons_options'])
opts.AddOptions(
	BoolOption('silent', 'build silently', True),
	BoolOption('debug', 'build debug variant', True),
	PathOption('prefix', 'install prefix', '/usr/local'),
)
opts.Update(env)
opts.Save('.scons_options', env)

env.Help(opts.GenerateHelpText(env))

# Hide compiler command line if silent mode on
if env['silent']:
	env['VALADEFINESCOMSTR'] = '   Defines: $TARGET'
	env['VALACOMSTR']        = 'Generating: $TARGETS'
	env['CCCOMSTR']          = '  Building: $TARGET'
	env['LINKCOMSTR']        = '   Linking: $TARGET'

env.Append(VALAPKGPATH = ['vapi'])

conf = Configure(env, custom_tests = {
	'CheckPkgConfig' : CheckPkgConfig,
	'CheckPkg' : CheckPkg,
	'CheckVala' : CheckVala,
	'CheckGCC' : CheckGCC,
})

if not conf.CheckVala():
	raise SCons.Errors.UserError(pkg + ' required to build Abraca')
if not conf.CheckGCC():
	raise SCons.Errors.UserError(pkg + ' required to build Abraca')
if not conf.CheckPkgConfig():
	raise SCons.Errors.UserError(pkg + ' required to build Abraca')

for pkg in ['gtk+-2.0', 'xmms2-client', 'xmms2-client-glib']:
	if not conf.CheckPkg(pkg):
		raise SCons.Errors.UserError(pkg + ' required to build Abraca')
	env.ParseConfig('pkg-config --libs --cflags ' + pkg)
	env.Append(VALAPKGS = [pkg])

conf.Finish()

env.Append(VALAPKGS = ['playlist-map'])
env.Append(CCFLAGS = ['-Wall', '-Wno-unused-variable'])

if env['debug']:
	env.Append(CCFLAGS = ['-g'])
else:
	env.Append(CCFLAGS = ['-O2'])

env.BuildDir('build', '.')

env.SConscript('build/src/SConscript', exports='env', duplicate=0)
env.SConscript('build/data/SConscript', exports='env', duplicate=0)
