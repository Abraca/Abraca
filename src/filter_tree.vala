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
				typeof(uint), typeof(string), typeof(string),
				typeof(string), typeof(string), typeof(string)
			);
		}

		public void query_collection(Xmms.Collection coll) {
			Xmms.Client xmms = Abraca.instance().xmms;

			xmms.coll_query_ids(coll, null, 0, 0).notifier_set(
				on_coll_query_ids, this
			);
		}

		[InstanceLast]
		private void on_coll_query_ids(Xmms.Result res) {
			Xmms.Client xmms = Abraca.instance().xmms;
			Gtk.ListStore store = (Gtk.ListStore) model;

			store.clear();

			for (res.list_first(); res.list_valid(); res.list_next()) {
				uint id;

				if (!res.get_uint(out id))
					continue;

				xmms.medialib_get_info(id).notifier_set(
					on_medialib_get_info, this
				);
			}
		}

		[InstanceLast]
		private void on_medialib_get_info(Xmms.Result res) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter;
			weak string artist, title, album;
			uint id;
			int pos;
			bool b;

			res.get_dict_entry_uint("id", out id);
			res.get_dict_entry_string("artist", out artist);
			res.get_dict_entry_string("album", out album);

			pos = store.iter_n_children(null);

			store.insert_with_values(
				ref iter, pos,
				FilterColumn.ID, id,
				FilterColumn.Artist, artist,
				FilterColumn.Title, title,
				FilterColumn.Album, album,
				-1
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
