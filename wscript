#!/usr/bin/env python

import os, sys
import Params

VERSION='0.2'
APPNAME='abraca'

srcdir='.'
blddir = 'build'

def set_options(opt):
    opt.add_option ('--enable-debug', action = 'store_true',
            help = 'enable debugging stuff', dest = 'enable_debug')

def configure (conf):
    conf.check_tool ('gcc')
    if not conf.check_pkg ('gtk+-2.0', destvar = 'GTK', vnum = '2.8.0'):
        Params.fatal ("gtk+-2.0 is required")
    if not conf.check_pkg ('libglade-2.0', destvar = 'GLADE', vnum = '2.6.0'):
        Params.fatal ("libglade-2.0 is required")
    if not conf.check_pkg ('glib-2.0', destvar = 'GLIB', vnum = '2.12.0'):
        Params.fatal ("glib-2.0 is required")
    if not conf.check_pkg ('xmms2-client', destvar = 'XMMS', vnum = '0.2'):
        Params.fatal ("xmms2-client is required")
    if not conf.check_pkg ('xmms2-client-glib', destvar = 'XMMS_GLIB',
            vnum = '0.2'):
        Params.fatal ("xmms2-client-glib is required")

    conf.add_define ('VERSION', VERSION)
    conf.add_define ('PACKAGE_DATA_DIR',
            os.path.join (conf.env['PREFIX'], 'share', APPNAME))
    conf.add_define ('ENABLE_NLS', 0)
    conf.add_define ('LOCALE_DIR',
            os.path.join (conf.env['PREFIX'], 'share', 'locale'))

    if Params.g_options.enable_debug:
        conf.add_define ('DEBUG', 1)
        conf.env.append_value ('CCFLAGS', '-O0 -ggdb')
    else:
        conf.env.append_value ('CCFLAGS', '-O3')

    if sys.platform == 'win32':
        conf.add_define ('PATHSEP', '\\')
    else:
        conf.add_define ('PATHSEP', '/')

    conf.env.append_value ('CCFLAGS', '-DHAVE_CONFIG_H')
    # Make Glade happy
    conf.env.append_value ('LINKFLAGS', '-Wl,--export-dynamic')

    conf.write_config_header('config.h')

def build (bld):
    bld.add_subdirs ('src data')
