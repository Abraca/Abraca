#! /usr/bin/env python
# encoding: utf-8
import os

VERSION = '0.8.2'
APPNAME = 'Abraca'

top = '.'
out = 'build'

def options(opt):
	opt.load('compiler_c vala intltool')

def configure(conf):
	conf.load('compiler_c intltool')
	conf.load('gresource man about-generator', tooldir='waftools')
	conf.load('vala')
	conf.check_vala((0, 24, 0))

	if 'CFLAGS' not in os.environ:
		conf.env.append_unique("CFLAGS", ["-g", "-O0", "-fdiagnostics-show-option"])

	conf.check_cfg(package='gio-2.0', atleast_version='2.40', args='--cflags --libs')
	conf.check_cfg(package='gio-unix-2.0', atleast_version='2.40', args='--cflags --libs')
	conf.check_cfg(package='glib-2.0', atleast_version='2.40', args='--cflags --libs')
	conf.check_cfg(package='gmodule-2.0', atleast_version='2.40', args='--cflags --libs')
	conf.check_cfg(package='gtk+-3.0', atleast_version='3.12', args='--cflags --libs')
	conf.check_cfg(package='gee-0.8', atleast_version='0.10.5', args='--cflags --libs')
	conf.check_cfg(package='xmms2-client', atleast_version='0.8', args='--cflags --libs')
	conf.check_cfg(package='xmms2-client-glib', atleast_version='0.8', args='--cflags --libs')
	conf.check_cc(lib="m", uselib_store="math")

	conf.env.VALADEFINES = []

	if conf.check_cc(function_name='xmmsc_coll_query', header_name='xmmsclient/xmmsclient.h', uselib='XMMS2-CLIENT', mandatory=False):
		conf.env.VALADEFINES.append('XMMS_API_COLLECTIONS_TWO_DOT_ZERO')

	conf.env.VALADEFINES.append('DEST_OS_' + conf.env.DEST_OS.upper())

	conf.env.DEFINES.append('GETTEXT_PACKAGE=\"Abraca\"')

	conf.define('APPNAME', APPNAME)
	conf.define('VERSION', VERSION)
	conf.define('LOCALEDIR', '${LOCALEDIR}')

	conf.write_config_header('build-config.h')

	conf.recurse('external')

def build(bld):
	bld.recurse('external src data po')
