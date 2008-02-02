namespace Abraca {
	[CCode (
		cname = "playlist_map_t",
		cprefix = "playlist_map_",
		ref_function = "playlist_map_ref",
		unref_function = "playlist_map_unref",
		cheader_filename = "playlist_map.h"
	)]
	public class PlaylistMap {
		public PlaylistMap (
		);
		public void insert (
			uint id, weak Gtk.TreeRowReference row
		);
		public void remove (
			uint id, Gtk.TreePath path
		);
		public void clear (
		);
		public weak GLib.SList<Gtk.TreeRowReference> lookup (
			uint id
		);
		public weak GLib.List<uint>get_ids (
		);
	}
}
