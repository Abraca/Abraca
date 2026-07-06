# subzero: small Vala mDNS/zeroconf browser used for XMMS2 server discovery.
# Vendored as a git submodule. Its sources are compiled straight into the
# abraca executable (see src/meson.build) to avoid cross-target header plumbing;
# it needs the platform-socket + posix vapis and the HAVE_SO_REUSEPORT define.

subzero_sources = files(
  'subzero/subzero/subzero-dns.vala',
  'subzero/subzero/subzero-dns-record-visitor.vala',
  'subzero/subzero/subzero-browser.vala',
  'subzero/subzero/subzero-util.vala',
)
