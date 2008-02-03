import SCons

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

if env['debug']:
	env.Append(CCFLAGS = ['-g'])
else:
	env.Append(CCFLAGS = ['-O2'])

env.Append(VALAPKGPATH = ['vapi'])

for pkg in ['gtk+-2.0', 'xmms2-client', 'xmms2-client-glib']:
	if not env.ParseConfig('pkg-config --libs --cflags ' + pkg):
		raise SCons.Errors.UserError(pkg + ' required to build Abraca')
	
	env.Append(VALAPKGS = [pkg])

env.Append(VALAPKGS = ['playlist-map'])

env.Append(CCFLAGS = ['-Wall', '-Wno-unused-variable'])

env.BuildDir('build', '.')

env.SConscript('build/src/SConscript', exports='env', duplicate=0)
env.SConscript('build/data/SConscript', exports='env', duplicate=0)
