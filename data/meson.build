datadir = get_option('datadir')

# Application icon + scalable variant.
install_data(
  ['abraca.svg', 'abraca-192.png'],
  install_dir : join_paths(datadir, 'icons'),
)

# Desktop entry (validated at install time by gnome.post_install / d-f-u).
install_data('abraca.desktop',
  install_dir : join_paths(datadir, 'applications'),
)

# AppStream metadata.
install_data('org.xmms2.abraca.appdata.xml',
  install_dir : join_paths(datadir, 'metainfo'),
)

# Man page.
install_man('abraca.1')
