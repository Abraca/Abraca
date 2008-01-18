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
		private Gtk.TargetEntry[] _target_entries;

		construct {
			show_expanders = true;

			create_columns ();

			get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);

			model = new Gtk.ListStore(
				FilterColumn.Total,
				typeof(int), typeof(string), typeof(string),
				typeof(string), typeof(string), typeof(string)
			);

			create_context_menu();
			create_drag_n_drop();

			button_press_event += on_button_press_event;
		}

		public void query_collection(Xmms.Collection coll) {
			Client c = Client.instance();

			c.xmms.coll_query_ids(coll, null, 0, 0).notifier_set(
				on_coll_query_ids
			);
		}

		[InstanceLast]
		private void on_coll_query_ids(Xmms.Result res) {
			Client c = Client.instance();
			Gtk.ListStore store = (Gtk.ListStore) model;

			store.clear();

			for (res.list_first(); res.list_valid(); res.list_next()) {
				uint id;

				if (!res.get_uint(out id))
					continue;

				c.xmms.medialib_get_info(id).notifier_set(
					on_medialib_get_info
				);
			}
		}

		[InstanceLast]
		private void on_medialib_get_info(Xmms.Result res) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter;
			weak string artist, title, album;
			int pos, id;
			bool b;

			res.get_dict_entry_int("id", out id);
			res.get_dict_entry_string("artist", out artist);
			res.get_dict_entry_string("title", out title);
			res.get_dict_entry_string("album", out album);

			pos = store.iter_n_children(null);

			store.insert_with_values(
				out iter, pos,
				FilterColumn.ID, id,
				FilterColumn.Artist, artist,
				FilterColumn.Title, title,
				FilterColumn.Album, album
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
			Client c = Client.instance();

			c.xmms.playlist_clear("_active");
			get_selection().selected_foreach(add_to_playlist, this);
		}

		[InstanceLast]
		private void add_to_playlist(
			Gtk.TreeModel model, Gtk.TreePath path,
			out Gtk.TreeIter iter
		) {
			Client c = Client.instance();
			uint id;

			model.get(iter, FilterColumn.ID, ref id);

			c.xmms.playlist_add_id("_active", id);
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

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ADD, null);
			item.activate += on_menu_add;
			filter_menu.append(item);

			item = new Gtk.MenuItem.with_label("Replace");
			item.activate += on_menu_replace;
			filter_menu.append(item);

			filter_menu.show_all();
		}

		private void create_drag_n_drop() {
			_target_entries = new Gtk.TargetEntry[1];

			_target_entries[0].target = "application/x-xmms2mlibid";
			_target_entries[0].flags = 0;
			_target_entries[0].info = 0;

			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         _target_entries, _target_entries.length,
			                         Gdk.DragAction.MOVE);

			drag_data_get += on_drag_data_get;
		}

		[InstanceLast]
		private bool on_drag_data_get(Gtk.Widget w, Gdk.DragContext ctx,
		                              Gtk.SelectionData selection_data,
		                              uint info, uint time) {
			weak Gtk.TreeSelection sel = get_selection();
			weak List<weak Gtk.TreeRowReference> lst = sel.get_selected_rows(null);
			List<uint> mid_list = new List<uint>();

			string buf = null;

			foreach (weak Gtk.TreePath p in lst) {
				Gtk.TreeIter iter;
				uint mid;

				model.get_iter(out iter, p);
				model.get(iter, 0, out mid, -1);

				mid_list.prepend((int) mid);
			}

			uint len = mid_list.length();
			uint[] mid_array = new uint[len];

			int pos = 0;
			foreach (int mid in mid_list) {
				mid_array[pos++] = mid;
			}

			selection_data.set(Gdk.Atom.intern("application/x-xmms2mlibid", true), 8,
			                   (uchar[]) mid_array, (int) len * 32);

			return true;
		}
	}
}
