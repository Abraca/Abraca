env = AbracaEnvironment(APPNAME = 'abraca', VERSION = '0.4-WiP')

env.VariantDir('build', '.')

env.Append(VALAPKGPATH = ['vapi'])

conf = env.Configure('build/build-config.h')
conf.CheckVala('0.5.6')
conf.CheckCCompiler()
conf.CheckPkgConfig()
conf.CheckApp('msgfmt')
conf.CheckApp('gdk-pixbuf-csource')

for pkg in ['gtk+-2.0', 'xmms2-client', 'xmms2-client-glib']:
	if conf.CheckPkg(pkg):
		env.AppendPkg(pkg)
		env.Append(VALAPKGS = [pkg])

conf.Define('APPNAME', env.subst('"$APPNAME"'))
conf.Define('VERSION', env.subst('"$VERSION"'))
conf.Define('DATADIR', '"' + env.subst(env['DATADIR']) + '"')

conf.Finish()

env.Append(VALAPKGS = ['playlist-map', 'build-config', 'gdk-keysyms'])
env.Append(CCFLAGS = ['-Wall', '-Wno-unused-variable'])
env.Append(CPPPATH = Dir('build'))

if env.DebugVariant():
	env.Append(CCFLAGS = ['-g'])
else:
	env.Append(CCFLAGS = ['-O2'])

env.SConscript('build/data/SConscript', exports='env', duplicate=0)
env.SConscript('build/src/SConscript', exports='env', duplicate=0)

if env['HAVE_MSGFMT']:
	env.SConscript('build/po/SConscript', exports='env', duplicate=0)
