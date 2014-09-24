from waflib import Task
from waflib.TaskGen import extension

import xml.dom.minidom

EXTENSION = '.gresource.xml'

class gresource(Task.Task):
    name    = 'gresource'
    run_str = '${GLIB_COMPILE_RESOURCES} --generate-source --sourcedir=${SRC[0].parent.get_src().abspath()} --sourcedir=${SRC[0].parent.get_bld().abspath()} --target=${TGT} ${SRC}'
    color   = 'BLUE'
    ext_out = '.c'
    shell   = True

    def scan(self):
        deps = []
        for node in self.inputs:
            dom = xml.dom.minidom.parseString(node.read())
            for resource in dom.getElementsByTagName("file"):
                for child in resource.childNodes:
                    resource = node.parent.find_resource(str(child.data))
                    if resource:
                        deps.append(resource)
        return (deps, None)

@extension(EXTENSION)
def add_gresource_file(self, node):
    c_node = node.change_ext('.c', EXTENSION)
    task = self.create_task('gresource', node, [c_node])
    self.source += task.outputs
    self.env.VALAFLAGS += ["--gresources=%s" % node.abspath()]

def configure(ctx):
    if not ctx.env.CC and not ctx.env.CXX:
        ctx.fatal('Load a C/C++ compiler first')
    ctx.find_program('glib-compile-resources', var='GLIB_COMPILE_RESOURCES')
