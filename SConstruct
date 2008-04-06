from abracaenv import AbracaEnvironment

env = AbracaEnvironment()

env.VariantDir('build', '.')

env.Append(VALAPKGPATH = ['vapi'])

conf = env.Configure('build/build-config.h')
conf.CheckVala()
conf.CheckCCompiler()
conf.CheckPkgConfig()

for pkg in ['gtk+-2.0', 'xmms2-client', 'xmms2-client-glib']:
	if conf.CheckPkg(pkg):
		env.AppendPkg(pkg)
		env.Append(VALAPKGS = [pkg])

conf.Define('APPNAME', '"Abraca"')
conf.Define('VERSION', '"0.3"')
conf.Define('DATADIR', '"' + env.subst(env['DATADIR']) + '"')

conf.Finish()

env.Append(VALAPKGS = ['playlist-map', 'build-config'])
env.Append(CCFLAGS = ['-Wall', '-Wno-unused-variable'])
env.Append(CPPPATH = Dir('build'))

if env.DebugVariant():
	env.Append(CCFLAGS = ['-g'])
else:
	env.Append(CCFLAGS = ['-O2'])


env.SConscript('build/src/SConscript', exports='env', duplicate=0)
env.SConscript('build/data/SConscript', exports='env', duplicate=0)
env.SConscript('build/po/SConscript', exports='env', duplicate=0)
