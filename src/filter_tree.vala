/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	enum FilterColumn {
		ID = 0,
		Artist,
		Title,
		Album,
		Duration,
		Genre,
		Total
	}

	public class FilterTree : Gtk.TreeView {
		construct {
			show_expanders = true;

			create_columns ();
			model = new Gtk.ListStore(
				FilterColumn.Total,
				typeof(string), typeof(string), typeof(string),
				typeof(string), typeof(string), typeof(string),
				typeof(string)
			);
		}

		private void create_columns() {
			Gtk.CellRenderer cell = new Gtk.CellRendererText();

 			insert_column_with_attributes(
				-1, "ID", cell, "text", FilterColumn.ID, null
			);

 			insert_column_with_attributes(
				-1, "Artist", cell, "text", FilterColumn.Artist, null
			);

 			insert_column_with_attributes(
				-1, "Title", cell, "text", FilterColumn.Title, null
			);

 			insert_column_with_attributes(
				-1, "Album", cell, "text", FilterColumn.Album, null
			);

 			insert_column_with_attributes(
				-1, "Duration", cell, "text", FilterColumn.Duration, null
			);

 			insert_column_with_attributes(
				-1, "Genre", cell, "text", FilterColumn.Genre, null
			);
		}
	}
}
