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
import os

def msgfmt_emitter(target, source, env):
	base, ext = SCons.Util.splitext(source[0].name)

	path = os.path.join(base, 'LC_MESSAGES', env.subst('${MSGFMT_NAME}.mo'))

	target[0].attributes.install_path = path

	return target, source

def generate(env):
	env['MSGFMT'] = 'msgfmt'
	env['MSGFMTCOM'] = '$MSGFMT -o $TARGET $SOURCE'

	msgfmt_action = SCons.Action.Action(
		'$MSGFMTCOM',
		'$MSGFMTCOMSTR'
	)
	msgfmt_builder = SCons.Builder.Builder(
		action = [
			msgfmt_action
		],
		emitter = msgfmt_emitter,
		src_suffix = '.po',
		suffix = '.mo'
	)
	env['BUILDERS']['MsgFmt'] = msgfmt_builder

	env.Append(CPPDEFINES = [('GETTEXT_PACKAGE','\\"abraca\\"')])

def exists(env):
	return env.Detect('msgfmt')
