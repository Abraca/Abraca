import SCons

vala_action = SCons.Action.Action('$VALACOM', '$VALACOMSTR')

def vala_emitter(target, source, env):
	target = []
	for src in source:
		tgt = src.target_from_source('', '.c')
		env.SideEffect(src.target_from_source('', '.h'), src)
		target.append(tgt)

	return target, source

def generate(env):
	env['VALAC'] = 'valac'
	env['VALACOM'] = '$VALAC -C -d $TARGET.dir $VALAFLAGS $_VALAPKGPATHS $_VALAPKGS $SOURCES'
	env['VALAFLAGS'] = SCons.Util.CLVar('')

	env['VALAPKGS'] = SCons.Util.CLVar('')
	env['VALAPKGPREFIX'] = '--pkg='
	env['_VALAPKGS'] = '${_defines(VALAPKGPREFIX, VALAPKGS, None, __env__)}'

	env['VALAPKGPATH'] = SCons.Util.CLVar('')
	env['VALAPKGPATHPREFIX'] = '--vapidir='
	env['_VALAPKGPATHS'] = '${_defines(VALAPKGPATHPREFIX, VALAPKGPATH, None, __env__)}'

	vala_builder = SCons.Builder.Builder(
		action = vala_action,
		emitter = vala_emitter,
		multi = 1,
		src_suffix = '.vala',
		suffix = '.c'
	)

	env['BUILDERS']['Vala'] = vala_builder

def exists(env):
	return env.Detect('valac')
