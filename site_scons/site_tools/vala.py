# Copyright (C) 2008-2012 Abraca Team
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
import os

def vala_emitter(target, source, env):
	target = []

	for src in source:
		tmp = src.target_from_source('', '.c')
		target.append(tmp)

	# Scan for local .vapi files to depend on.
	for pkg in env['VALAPKGS']:
		for path in env['VALAPKGPATH']:
			if SCons.Util.is_String(path):
				path = env.Dir('#').Dir(path)

			if not isinstance(path, SCons.Node.FS.Dir):
				continue

			vapi_file = path.File(str(pkg) + '.vapi')
			if vapi_file.exists() or vapi_file.has_builder():
				env.Depends(target, vapi_file)
				break

	return target, source

def generate(env):
	env['VALAC'] = env.get('VALAC', 'valac')
	env['VALACOM'] = '$VALAC --quiet -C $VALAFLAGS $_VALAPKGPATHS $_VALAPKGS $SOURCES'

	env['HAVE_VALAC'] = env.Detect(env['VALAC'])

	env['VALAFLAGS'] = env.get('VALAFLAGS', SCons.Util.CLVar(''))

	env['VALAPKGS'] = env.get('VALAPKGS', SCons.Util.CLVar(''))
	env['VALAPKGPREFIX'] = '--pkg='
	env['_VALAPKGS'] = '${_defines(VALAPKGPREFIX, VALAPKGS, None, __env__)}'

	env['VALAPKGPATH'] = SCons.Util.CLVar('')
	env['VALAPKGPATHPREFIX'] = '--vapidir='
	env['_VALAPKGPATHS'] = '${_defines(VALAPKGPATHPREFIX, VALAPKGPATH, None, __env__)}'

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
	env['BUILDERS']['_Vala'] = vala_builder

	def _vala_wrapper(env, lst, *args, **kwargs):
		return [x for x in env._Vala(lst, *args, **kwargs) if str(x).endswith('.c')]

	env.AddMethod(_vala_wrapper, 'Vala')

def exists(env):
	return env.Detect(env.get('VALAC', 'valac'))
