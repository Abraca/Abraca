/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	enum PlaylistColumn {
		ID = 0,
		CoverArt,
		Info,
		Total
	}

	public class PlaylistTree : Gtk.TreeView {
		construct {
			enable_search = true;
			search_column = 1;
			headers_visible = false;
			show_expanders = false;

			create_columns ();

			model = new Gtk.ListStore(
				PlaylistColumn.Total,
				typeof(uint), typeof(string), typeof(string)
			);
			show_all();
		}

		private void create_columns() {
 			insert_column_with_attributes(
				-1, null, new Gtk.CellRendererPixbuf(),
				"stock-id", PlaylistColumn.CoverArt, null
			);

 			insert_column_with_attributes(
				-1, null, new Gtk.CellRendererText(),
				"markup", PlaylistColumn.Info, null
			);
		}
	}
}
