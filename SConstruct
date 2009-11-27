env = AbracaEnvironment(APPNAME = 'abraca', VERSION = '0.5.0')

env.VariantDir('build', '.')

env.Append(VALAPKGPATH = ['vapi'])

conf = env.Configure('build/build-config.h')
conf.CheckVala('0.9.4')
conf.CheckCCompiler()
conf.CheckPkgConfig()
conf.CheckApp('msgfmt')
conf.CheckApp('gdk-pixbuf-csource')
conf.CheckGitVersion()

dependencies = (
	('gtk+-2.0', '2.16.0'),
	('gmodule-2.0', '2.16.0'),
	('xmms2-client', '0.6'),
	('xmms2-client-glib', '0.6'),
	('gee-1.0', '0.5')
)

for pkg, version in dependencies:
	if conf.CheckPkg(pkg, version):
		env.AppendPkg(pkg, version)
		env.Append(VALAPKGS = [pkg])

if env['WITH_GLADEUI']:
	conf.CheckPkg('gladeui-1.0')

# Detect the operating system as indicated by the G_OS_* makros and pass them
# with --define to the vala compiler. Because of those macros are defined in the
# glib header files, this check must be done after adding the packages to the
# environment.
conf.CheckOS()

conf.Define('APPNAME', env.subst('"$APPNAME"'))
conf.Define('VERSION', env.subst('"$VERSION"'))
conf.Define('DATADIR', '"' + env.subst(env['DATADIR']) + '"')
conf.Define('LOCALEDIR', '"' + env.subst(env['LOCALEDIR']) + '"')

conf.Finish()

env.Append(VALAPKGS = ['build-config', 'gdk-keysyms'])
env.Append(CCFLAGS = ['-Wall', '-Wno-unused-variable'])
env.Append(CPPPATH = Dir('build'))

if env.DebugVariant():
	env.Append(CCFLAGS = ['-g'])
else:
	env.Append(CCFLAGS = ['-O2'])

env.SConscript('build/data/SConscript', exports='env', duplicate=0)
env.SConscript('build/data/ui/SConscript', exports='env', duplicate=0)
env.SConscript('build/src/SConscript', exports='env', duplicate=0)

if env['WITH_GLADEUI']:
	env.SConscript('build/gladeui/SConscript', exports='env', duplicate=0)

if env['HAVE_MSGFMT']:
	env.SConscript('build/po/SConscript', exports='env', duplicate=0)
