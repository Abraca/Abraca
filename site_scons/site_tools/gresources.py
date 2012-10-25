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
import re
import subprocess

def gresources_get_preprocess(source):
	if any(source.path.endswith(x) for x in (".xml", ".svg")):
		return "xml-stripblanks"
	if any(source.path.endswith(x) for x in (".jpg", ".png")):
		return "to-pixdata"
	return False

def gresources_csource_action(target, source, env):
	resource_path = env.get("gresource_path", "/org/gtk/Example")
	fd = file(target[0].path, 'w')
	try:
		fd.write("""<?xml version="1.0" encoding="UTF-8"?>\n""")
		fd.write("""<gresources>\n""")
		fd.write("""  <gresource prefix="%s">\n""" % (resource_path))
		for source_entry in source:
			preprocess = gresources_get_preprocess(source_entry)
			if preprocess:
				fd.write("""    <file preprocess="%s">%s</file>\n""" % (preprocess, target[0].rel_path(source_entry)))
			else:
				fd.write("""    <file>%s</file>\n""" % (target[0].rel_path(source_entry)))
		fd.write("""  </gresource>\n""")
		fd.write("""</gresources>""")
	finally:
		fd.close()

	cmd = env.subst('$GRESOURCESCOM', source=target[0].abspath)
	proc = subprocess.Popen(cmd, shell=True, cwd=target[0].get_dir().abspath)
	proc.wait()

def gresources_csource_emitter(target, source, env):
	target.append(target[0].target_from_source('', '.c'))
	return target, source

def generate(env):
	env['GRESOURCES'] = env.get('GRESOURCES', 'glib-compile-resources')
	env['GRESOURCESCOM'] = '$GRESOURCES --generate-source $SOURCES'

	gresources_csource = SCons.Action.Action(
		gresources_csource_action,
		'$GRESOURCESCOMSTR'
	)
	gresources_csource_builder = SCons.Builder.Builder(
		action = [
			gresources_csource
		],
		emitter = gresources_csource_emitter,
		suffix = '.xml'
	)

	env['BUILDERS']['GResources'] = gresources_csource_builder


def exists(env):
	return env.Detect(env.get('GRESOURCES', 'glib-compile-resources'))
