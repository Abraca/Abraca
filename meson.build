project('abraca', ['c', 'vala'],
  version : '0.8.2',
  license : 'GPL-2.0-or-later',
  meson_version : '>= 0.59.0',
  default_options : [
    'buildtype=debugoptimized',
    'warning_level=1',
  ],
)

gnome = import('gnome')
i18n = import('i18n')

gettext_package = meson.project_name()

# Dependencies -----------------------------------------------------------------
glib_dep         = dependency('glib-2.0', version : '>= 2.66')
gobject_dep      = dependency('gobject-2.0')
gio_dep          = dependency('gio-2.0', version : '>= 2.66')
gio_unix_dep     = dependency('gio-unix-2.0')
gmodule_dep      = dependency('gmodule-2.0')
gtk_dep          = dependency('gtk4', version : '>= 4.10')
adw_dep          = dependency('libadwaita-1', version : '>= 1.4')
gee_dep          = dependency('gee-0.8', version : '>= 0.20')
xmms2_dep        = dependency('xmms2-client', version : '>= 0.9')
xmms2_glib_dep   = dependency('xmms2-client-glib', version : '>= 0.9')

cc = meson.get_compiler('c')
math_dep = cc.find_library('m', required : false)

# Generated build-config.h -----------------------------------------------------
prefix    = get_option('prefix')
localedir = join_paths(prefix, get_option('localedir'))

conf = configuration_data()
conf.set_quoted('APPNAME', 'Abraca')
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('LOCALEDIR', localedir)
conf.set_quoted('GETTEXT_PACKAGE', gettext_package)

config_h = configure_file(
  output : 'build-config.h',
  configuration : conf,
)
config_dep = declare_dependency(
  sources : config_h,
  include_directories : include_directories('.'),
)

# Vala compiler defines --------------------------------------------------------
add_project_arguments(
  ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
  ['--vapidir', join_paths(meson.current_source_dir(), 'external', 'subzero', 'vapi')],
  '--define=XMMS_API_COLLECTIONS_TWO_DOT_ZERO',
  '--define=HAVE_SO_REUSEPORT',
  '--define=DEST_OS_LINUX',
  language : 'vala',
)

# Vala emits <glib/gi18n-lib.h>, which needs GETTEXT_PACKAGE at C compile time.
add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_package), language : 'c')

subdir('external')
subdir('po')
subdir('src')
subdir('data')

gnome.post_install(
  gtk_update_icon_cache : true,
  update_desktop_database : true,
)
