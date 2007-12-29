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
		private Gtk.Menu filter_menu;

		construct {
			show_expanders = true;

			create_columns ();

			get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);

			model = new Gtk.ListStore(
				FilterColumn.Total,
				typeof(uint), typeof(string), typeof(string),
				typeof(string), typeof(string), typeof(string)
			);

			create_context_menu();

			button_press_event += on_button_press_event;
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
			res.get_dict_entry_string("title", out title);
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

		[InstanceLast]
		private bool on_button_press_event(
			Gtk.Widget widget, Gdk.EventButton event
		) {
			/* we're only interested in the 3rd mouse button */
			if (event.button != 3)
				return false;

			/* bail if the user didn't select any items */
			if (get_selection().count_selected_rows() == 0)
				return false;

			filter_menu.popup(
				null, null, null, null, event.button,
				Gtk.get_current_event_time()
			);

			return true;
		}

		private void on_menu_add(Gtk.MenuItem item) {
			get_selection().selected_foreach(add_to_playlist, this);
		}

		private void on_menu_replace(Gtk.MenuItem item) {
			Xmms.Client xmms = Abraca.instance().xmms;

			xmms.playlist_clear("_active");
			get_selection().selected_foreach(add_to_playlist, this);
		}

		[InstanceLast]
		private void add_to_playlist(
			Gtk.TreeModel model, Gtk.TreePath path,
			out Gtk.TreeIter iter
		) {
			Xmms.Client xmms = Abraca.instance().xmms;
			uint id;

			model.get(ref iter, FilterColumn.ID, ref id);

			xmms.playlist_add_id("_active", id);
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

		private void create_context_menu() {
			Gtk.MenuItem item;
			Gtk.ImageMenuItem img_item;

			filter_menu = new Gtk.Menu();

			item = Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ADD, null);
			item.activate += on_menu_add;
			filter_menu.append(item);

			item = Gtk.MenuItem.with_label("Replace");
			item.activate += on_menu_replace;
			filter_menu.append(item);

			filter_menu.show_all();
		}
	}
}
