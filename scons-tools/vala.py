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

def vala_defines(target, source, env):
	defines = source[0].read()

	buffer = ''
	buffer += 'namespace Build {\n'
	buffer += '\tpublic class Config {\n'

	for pair in defines.items():
		buffer += '\t\tpublic const string %s = "%s";\n' % pair

	buffer += '\t}\n'
	buffer += '}\n'

	fd = file(str(target[0]), 'w+')
	fd.write(buffer)
	fd.close()

def vala_emitter(target, source, env):
	target = []

	defines = env.get('VALADEFINES')
	if defines:
		if not SCons.Util.is_Dict(defines):
			raise SCons.Errors.UserError('ValaDefines only support dict values')

		for k, v in defines.items():
			if not SCons.Util.is_String(v):
				raise SCons.Errors.UserError('Defines dict can only contain strings')
			defines[k] = env.subst(v)

		conf = SCons.Node.Python.Value(defines)
		source += env._ValaDefines('build-config.vala', conf)

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
