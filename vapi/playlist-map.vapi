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
			uint id, Gtk.TreeRowReference row
		);
		public void remove (
			uint id, Gtk.TreePath path
		);
		public void clear (
		);
		public unowned GLib.SList<Gtk.TreeRowReference> lookup (
			uint id
		);
		public unowned GLib.List<uint>get_ids (
		);
	}
}
