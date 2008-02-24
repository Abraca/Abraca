from abracaenv import AbracaEnvironment
import os

env = AbracaEnvironment(
	tools = ['gcc', 'gnulink'],
	ENV = os.environ
)

env.Append(VALAPKGPATH = ['vapi'])

conf = env.Configure()
conf.CheckVala()
conf.CheckCCompiler()
conf.CheckPkgConfig()

for pkg in ['gtk+-2.0', 'xmms2-client', 'xmms2-client-glib']:
	if conf.CheckPkg(pkg):
		env.ParseConfig('pkg-config --libs --cflags ' + pkg)
		env.Append(VALAPKGS = [pkg])

conf.Finish()

env.Append(VALAPKGS = ['playlist-map'])
env.Append(CCFLAGS = ['-Wall', '-Wno-unused-variable'])

if env.DebugVariant():
	env.Append(CCFLAGS = ['-g'])
else:
	env.Append(CCFLAGS = ['-O2'])

env.BuildDir('build', '.')

env.SConscript('build/src/SConscript', exports='env', duplicate=0)
env.SConscript('build/data/SConscript', exports='env', duplicate=0)
