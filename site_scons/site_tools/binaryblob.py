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
import os


_code_template = """
const char %(full_name)s[] = {
%(bytes)s
};
"""


def variable_name_fixup(name):
    if not name[0].isalpha() and name[0] != '_':
        name[0] = '_'

    for pos, char in enumerate(name):
        if not char.isalnum() and char != '_':
            name = name[:pos] + '_' + name[pos + 1:]
    return name

def get_bytes(src):
    return ",\n".join("\t0x%x" % ord(x) for x in src.get_contents())

def binary_blob_asmsource_action(target, source, env):
    items = []

    for src in source:
        filename = os.path.basename(src.path)
        name, _ = os.path.splitext(filename)

        metadata = {
            "name": name,
            "full_name": "resource_%s" % name,
            "bytes": get_bytes(src),
        }
        items.append(metadata)

    # Write the ASM file
    fd = file(target[0].path, 'w')
    for item in items:
        fd.write(_code_template % item)
    fd.close()

    # Write the header file
    fd = file(target[1].path, 'w')

    name = variable_name_fixup(target[1].name).upper()
    fd.write('/* Generated file, do not edit */\n\n')
    fd.write('#ifndef __BINARY_BLOB_%s__\n' % name)
    fd.write('#define __BINARY_BLOB_%s__\n' % name)

    for item in items:
        fd.write('extern const char %(full_name)s[];\n' % item)

    fd.write('#endif\n')
    fd.close()

    # Write the vapi file
    fd = file(target[2].path, 'w')
    fd.write('/* Generated file, do not edit */\n\n')
    fd.write('[CCode(cprefix="", cheader_filename="%s")]\n' % target[1].name)
    fd.write('namespace Resources.XML {\n')

    for item in items:
        fd.write('\t[CCode(cname="%(full_name)s")]\n' % item)
        fd.write('\tpublic const string %(name)s;\n' % item)

    fd.write('}')
    fd.close()

def binary_blob_asmsource_emitter(target, source, env):
    target.append(target[0].target_from_source('', '.h'))
    target.append(target[0].target_from_source('', '.vapi'))
    return target, source

def generate(env):
    binary_blob_asmsource = SCons.Action.Action(
        binary_blob_asmsource_action,
        '$BINARYBLOBCOMSTR'
    )

    binary_blob_asmsource_builder = SCons.Builder.Builder(
        action = [
            binary_blob_asmsource
        ],
        emitter = binary_blob_asmsource_emitter,
        suffix = '.c'
    )

    env['BUILDERS']['BinaryBlob'] = binary_blob_asmsource_builder

def exists(env):
    return True
