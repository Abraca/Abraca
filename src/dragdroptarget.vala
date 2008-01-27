namespace Abraca {
	public enum DragDropTargetType {
		ROW,
		MID,
		COLL,
		URI,
		INTERNET,
	}

	public class DragDropTarget {
		public const Gtk.TargetEntry PlaylistRow = {
			"application/x-xmmsclient-playlist-row", 0, DragDropTargetType.ROW
		};

		public const Gtk.TargetEntry TrackId = {
			"application/x-xmmsclient-track-id", 0, DragDropTargetType.MID
		};

		public const Gtk.TargetEntry Collection = {
			"application/x-xmmsclient-collection", 0, DragDropTargetType.COLL
		};

		public const Gtk.TargetEntry UriList = {
			"text/uri-list", DragDropTargetType.URI
		};

		public const Gtk.TargetEntry Internet = {
			"_NETSCAPE_URL", DragDropTargetType.INTERNET
		};
	}
}
