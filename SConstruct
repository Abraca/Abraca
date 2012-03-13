env = AbracaEnvironment(APPNAME = 'abraca', VERSION = '0.6.0')

env.VariantDir('build', '.')

env.Append(VALAPKGPATH = ['vapi'])

conf = env.Configure('build/build-config.h')
conf.CheckVala('0.11.5')
conf.CheckCCompiler()
conf.CheckPkgConfig()
conf.CheckApp('msgfmt')
conf.CheckApp('gdk-pixbuf-csource')
conf.CheckGitVersion()

vala_dependencies = (
	('gtk+-3.0', '2.16.0', env.Dependency.Mandatory),
	('gmodule-2.0', '2.16.0', env.Dependency.Mandatory),
	('gio-2.0', '2.16.0', env.Dependency.Mandatory),
	('xmms2-client', '0.6', env.Dependency.Mandatory),
	('xmms2-client-glib', '0.6', env.Dependency.Mandatory),
	('gee-1.0', '0.5', env.Dependency.Mandatory),
	('avahi-gobject', '0.6.0', env.Dependency.Optional),
	('ige-mac-integration', '0.9.8', env.Dependency.Optional),
)

for pkg, version, option in vala_dependencies:
	if conf.CheckPkg(pkg, version, option):
		env.AppendPkg(pkg, version)
		env.Append(VALAPKGS = [pkg])

env.Append(VALAPKGS = ['posix'])

c_dependencies = (
	('gladeui-2.0', '3.6.0', env.Dependency.Optional),
#	('avahi-client', '0.6.0', env.Dependency.Optional),
#	('avahi-glib', '0.6.0', env.Dependency.Optional),
)

for pkg, version, option in c_dependencies:
	if conf.CheckPkg(pkg, version, option):
		env.AppendPkg(pkg, version)

# Detect the operating system as indicated by the G_OS_* makros and pass them
# with --define to the vala compiler. Because of those macros are defined in the
# glib header files, this check must be done after adding the packages to the
# environment.
conf.CheckOS()

conf.Define('APPNAME', env.subst('"$APPNAME"'))
conf.Define('VERSION', env.subst('"$VERSION"'))
conf.Define('DATADIR', '"' + env.subst(env['DATADIR']) + '"')
conf.Define('LOCALEDIR', '"' + env.subst(env['LOCALEDIR']) + '"')

api_version = conf.CheckDefine('XMMS_IPC_PROTOCOL_VERSION', ['xmmsclient/xmmsclient.h'])
if api_version and api_version.isdigit() and int(api_version) > 18:
	env.Append(VALAFLAGS=['--define=XMMS_API_COLLECTIONS_TWO_DOT_ZERO'])

conf.Finish()

env.Append(VALAPKGS = ['build-config'])
env.Append(CCFLAGS = ['-Wall', '-Wno-unused-variable'])
env.Append(CPPPATH = Dir('build'))

if env.DebugVariant():
	env.Append(CCFLAGS = ['-g'])
else:
	env.Append(CCFLAGS = ['-O2'])

env.SConscript('build/data/SConscript', exports='env', duplicate=0)
env.SConscript('build/data/ui/SConscript', exports='env', duplicate=0)
env.SConscript('build/src/SConscript', exports='env', duplicate=0)
env.SConscript('build/gladeui/SConscript', exports='env', duplicate=0)
env.SConscript('build/po/SConscript', exports='env', duplicate=0)
