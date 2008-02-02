import SCons

def vala_defines(target, source, env):
	defines = env.get('VALADEFINES')
	if defines is not None:
		buffer = ''
		buffer += 'namespace Build {\n'
		buffer += '\tpublic class Config {\n'
		for k, v in defines.items():
			if SCons.Util.is_String(v):
				buffer += '\t\tpublic const string %s = "%s";\n' % (k, env.subst(v))
		buffer += '\t}\n'
		buffer += '}\n'

		fd = file(str(target[0]), 'w+')
		fd.write(buffer)
		fd.close()

def vala_defines_emitter(target, source, env):
	return target, []

def vala_emitter(target, source, env):
	target = []

	if env.get('VALADEFINES') and source:
		conf = env._ValaDefines('build-config.vala', VALADEFINES = env['VALADEFINES'])
		env.AlwaysBuild(conf)
		source += conf

	for src in source:
		tgt = src.target_from_source('', '.c')
		env.SideEffect(src.target_from_source('', '.h'), src)
		target.append(tgt)

	return target, source

def generate(env):
	env['VALAC'] = 'valac'
	env['VALACOM'] = '$VALAC -C -d $TARGET.dir $VALAFLAGS $_VALAPKGPATHS $_VALAPKGS $SOURCES'
	env['VALAFLAGS'] = SCons.Util.CLVar('')
	env['VALADEFINES'] = SCons.Util.CLVar('')

	env['VALAPKGS'] = SCons.Util.CLVar('')
	env['VALAPKGPREFIX'] = '--pkg='
	env['_VALAPKGS'] = '${_defines(VALAPKGPREFIX, VALAPKGS, None, __env__)}'

	env['VALAPKGPATH'] = SCons.Util.CLVar('')
	env['VALAPKGPATHPREFIX'] = '--vapidir='
	env['_VALAPKGPATHS'] = '${_defines(VALAPKGPATHPREFIX, VALAPKGPATH, None, __env__)}'

	vala_defines_action = SCons.Action.Action(
		vala_defines,
		'$VALADEFINESCOMSTR',
	)
	vala_defines_builder = SCons.Builder.Builder(
		action = vala_defines_action,
		emitter = vala_defines_emitter,
		suffix = '.vala'
	)
	env['BUILDERS']['_ValaDefines'] = vala_defines_builder

	vala_compiler_action = SCons.Action.Action(
		'$VALACOM',
		'$VALACOMSTR'
	)
	vala_builder = SCons.Builder.Builder(
		action = [
			vala_compiler_action
		],
		emitter = vala_emitter,
		multi = 1,
		src_suffix = '.vala',
		suffix = '.c'
	)
	env['BUILDERS']['Vala'] = vala_builder

def exists(env):
	return env.Detect('valac')
