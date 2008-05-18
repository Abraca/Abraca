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
import re
import subprocess

def variable_name_fixup(name):
	if not name[0].isalpha() and name[0] != '_':
		name[0] = '_'

	for pos, char in enumerate(name):
		if not char.isalnum() and char != '_':
			name = name[:pos] + '_' + name[pos + 1:]
	return name


def _gnormalize(sources):
	"""
	Half-assed attempt at normalising filenames
	for use in C variable names.
	"""
	lst = []
	for src in sources:
		lst.append('resource_' + variable_name_fixup(src.filebase.lstr))
		lst.append(src.path)

	return ' '.join(lst)


def gdk_pixbuf_csource_action(target, source, env):
	cmd = env.subst('$GDKPBUFCOM', source=source)
	proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)

	tgt_content = proc.stdout.read()

	proc.wait()

	# Write the C file
	fd = file(target[0].path, 'w')
	fd.write('/* Generated file, do not edit */\n\n')
	fd.write('#include <gdk-pixbuf/gdk-pixdata.h>\n')
	fd.write(tgt_content)
	fd.close()

	decls = list(set(re.findall('const guint8 ([^\[]+)', tgt_content)))

	# Write the header file
	fd = file(target[1].path, 'w')

	name = variable_name_fixup(target[1].name).upper()
	fd.write('/* Generated file, do not edit */\n\n')
	fd.write('#ifndef __GDK_PIXBUF_CSOURCE_%s__\n' % name)
	fd.write('#define __GDK_PIXBUF_CSOURCE_%s__\n' % name)
	fd.write('#include <glib.h>\n')

	for decl in decls:
		fd.write('extern const guint8 ' + decl + '[];\n')

	fd.write('#endif\n')
	fd.close()

	# Write the vapi file
	fd = file(target[2].path, 'w')
	fd.write('/* Generated file, do not edit */\n\n')
	fd.write('[CCode(cprefix="", cheader_filename="%s")]\n' % target[1].name)
	fd.write('namespace Resources {\n')

	for decl in decls:
		fd.write('\t[CCode(cname="%s")]\n' % decl)
		fd.write('\tpublic const uchar ' + decl[9:] + ';\n')

	fd.write('}')
	fd.close()


def gdk_pixbuf_csource_emitter(target, source, env):
	target.append(target[0].target_from_source('', '.h'))
	target.append(target[0].target_from_source('', '.vapi'))
	return target, source


def generate(env):
	env['GDKPBUF'] = env.get('GDKPBUF', 'gdk-pixbuf-csource')
	env['GDKPBUFCOM'] = '$GDKPBUF --extern --build-list ${_gnormalize(SOURCES)}'

	gdk_pixbuf_csource = SCons.Action.Action(
		gdk_pixbuf_csource_action,
		'$GDKPBUFCOMSTR'
	)
	gdk_pixbuf_csource_builder = SCons.Builder.Builder(
		action = [
			gdk_pixbuf_csource
		],
		emitter = gdk_pixbuf_csource_emitter,
		suffix = '.c'
	)

	env['_gnormalize'] = _gnormalize

	env['BUILDERS']['GdkPixBufCSource'] = gdk_pixbuf_csource_builder


def exists(env):
	return env.Detect(env.get('GDKPBUF', 'gdk-pixbuf-csource'))
