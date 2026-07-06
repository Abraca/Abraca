# GResource bundles ------------------------------------------------------------
ui_resources = gnome.compile_resources(
  'abraca-ui-resources',
  'resources/abraca-ui.gresource.xml',
  source_dir : 'resources',
  c_name : 'abraca_ui',
)

img_resources = gnome.compile_resources(
  'abraca-img-resources',
  join_paths(meson.project_source_root(), 'data', 'abraca-img.gresource.xml'),
  source_dir : join_paths(meson.project_source_root(), 'data'),
  c_name : 'abraca_img',
)

# Credit lists for the About window, generated from AUTHORS.
about_credits = custom_target('about-credits.vala',
  input : [join_paths(meson.project_source_root(), 'AUTHORS')],
  output : 'about-credits.vala',
  command : [
    find_program('python3'),
    join_paths(meson.project_source_root(), 'utils', 'about-generator.py'),
    '@INPUT@', '@OUTPUT@',
  ],
)

# Vala sources -----------------------------------------------------------------
abraca_sources = files(
  'abraca-application.vala',
  'abraca-client.vala',
  'abraca-collections-model.vala',
  'abraca-collections-view.vala',
  'abraca-config.vala',
  'abraca-configurable.vala',
  'abraca-drag-and-drop.vala',
  'abraca-equalizer-model.vala',
  'abraca-equalizer-widget.vala',
  'abraca-filter-browser-model.vala',
  'abraca-filter-browser.vala',
  'abraca-filter-editor.vala',
  'abraca-filter-model.vala',
  'abraca-filter-searchbox.vala',
  'abraca-filter-view.vala',
  'abraca-filter-widget.vala',
  'abraca-medialib.vala',
  'abraca-nowplaying.vala',
  'abraca-playlist-model.vala',
  'abraca-playlist-view.vala',
  'abraca-playlist-widget.vala',
  'abraca-rating-entry.vala',
  'abraca-resolver.vala',
  'abraca-server-browser.vala',
  'abraca-server-browser-dialog.vala',
  'abraca-server-discover-tcp.vala',
  'abraca-server-discover-unix.vala',
  'abraca-server-discover.vala',
  'abraca-server-prober.vala',
  'abraca-stock.vala',
  'abraca-time-slider.vala',
  'abraca-transform.vala',
  'abraca-treeview.vala',
  'abraca-window.vala',
)

abraca_deps = [
  config_dep,
  glib_dep,
  gobject_dep,
  gio_dep,
  gio_unix_dep,
  gmodule_dep,
  gtk_dep,
  adw_dep,
  gee_dep,
  xmms2_dep,
  xmms2_glib_dep,
  math_dep,
]

# The XMMS2 GLib mainloop binding lives in a local vapi that pulls in the
# xmmsclient-glib header; make sure that package is on the Vala search path.
abraca_vala_args = [
  '--pkg', 'xmms2-client-glib',
  '--pkg', 'build-config',
  '--pkg', 'posix',
  '--pkg', 'platform-socket',
  '--target-glib', '2.66',
]

executable('abraca',
  abraca_sources,
  subzero_sources,
  about_credits,
  ui_resources,
  img_resources,
  dependencies : abraca_deps,
  vala_args : abraca_vala_args,
  install : true,
)
