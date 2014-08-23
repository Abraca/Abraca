#! /usr/bin/env python
# encoding: utf-8
# Jaap Haitsma, 2008

# the following two variables are used by the target "waf dist"
VERSION = '0.1'
APPNAME = 'SubZero'

# these variables are mandatory ('/' are converted automatically)
top = '.'
out = 'build'

SO_REUSEPORT_FRAGMENT = """
#include <sys/socket.h>
int main(int argc, char **argv) {
	return SO_REUSEPORT;
}
"""

def options(opt):
	opt.load('compiler_c')
	opt.load('vala')

def configure(conf):
	conf.load('compiler_c vala')
	conf.check_cfg(package='gio-2.0', atleast_version='2.34.0', mandatory=1, args='--cflags --libs')
	conf.find_program('g-ir-compiler', var='G_IR_COMPILER', mandatory=0)

	conf.env.VALADEFINES = []
	if conf.check_cc(fragment=SO_REUSEPORT_FRAGMENT, execute=True, mandatory=False):
		conf.env.VALADEFINES = ['HAVE_SO_REUSEPORT']

def build(bld):
	bld.recurse('subzero examples')
