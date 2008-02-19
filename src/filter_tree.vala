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
		/** context menu */
		private Gtk.Menu filter_menu;

		/** allowed drag-n-drop variants */
		private const Gtk.TargetEntry[] _target_entries = {
			DragDropTarget.TrackId
		};

		/* metadata properties we're interested in */
		private const string[] _properties = {
			"artist", "album", "title"
		};


		/* TODO: This is bogous, use a Hash<uint,List<uint>> instead
		 *       to allow for multiple rows <-> same medialib id.
		 */
		private GLib.HashTable<int,Gtk.TreeRowReference> pos_map;

		construct {
			show_expanders = true;
			fixed_height_mode = true;

			create_columns ();

			get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);

			model = new Gtk.ListStore(
				FilterColumn.Total,
				typeof(int), typeof(string), typeof(string),
				typeof(string), typeof(string), typeof(string)
			);

			create_context_menu();
			create_drag_n_drop();

			pos_map = new GLib.HashTable<int,Gtk.TreeRowReference>(GLib.direct_hash, GLib.direct_equal);
			Client c = Client.instance();
			c.media_info += on_media_info;

			button_press_event += on_button_press_event;
		}

		public void query_collection(Xmms.Collection coll) {
			Client c = Client.instance();

			c.xmms.coll_query_ids(coll, null, 0, 0).notifier_set(
				on_coll_query_ids
			);
		}

		[InstanceLast]
		private void on_coll_query_ids(Xmms.Result #res) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter, sibling;
			bool first = true;


			store.clear();

			/* disconnect our model while the shit hits the fan */
			set_model(null);

			for (res.list_first(); res.list_valid(); res.list_next()) {
				Gtk.TreeRowReference row;
				Gtk.TreePath path;
				uint id;
				int pos;

				if (!res.get_uint(out id))
					continue;

				if (first) {
					store.insert_after(out iter, null);
					first = !first;
				} else {
					store.insert_after(out iter, sibling);
				}

				store.set(iter, FilterColumn.ID, id);

				sibling = iter;

				path = store.get_path(iter);
				row = new Gtk.TreeRowReference(store, path);

				pos_map.insert(id.to_pointer(), #row);
			}

			/* reconnect the model again */
			set_model(store);

			pos_map.for_each((k,v,u) => {
				Client c = Client.instance();
				/* TODO: Cast shouldn't be needed here */
				c.get_media_info(k.to_int(), (string[]) _properties);
			}, null);
		}

		/**
		 * TODO: Should check the future hash[mid] = [row1, row2, row3] and
		 *       update the rows accordingly.
		 *       Should also update the current coverart image.
		 */
		private void on_media_info(Client c, weak GLib.HashTable<string,pointer> m) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			int mid, pos, id;
			weak string artist, album, title;
			weak Gtk.TreeRowReference row;
			string info;
			Gtk.TreeIter iter;
			weak Gtk.TreePath path;

			mid = m.lookup("id").to_int();

			row = (Gtk.TreeRowReference) pos_map.lookup(mid.to_pointer());
			if (row == null || !row.valid()) {
				/* the given mid doesn't match any of our rows */
				return;
			}

			artist = (string) m.lookup("artist");
			album = (string) m.lookup("album");
			title = (string) m.lookup("title");

			path = row.get_path();

			if (!model.get_iter(out iter, path)) {
				GLib.stdout.printf("couldn't get iter!!!\n");
			} else {
				store.set(iter,
					FilterColumn.Artist, artist,
					FilterColumn.Title, title,
					FilterColumn.Album, album
				);
			}
		}

		[InstanceLast]
		private bool on_button_press_event(Gtk.Widget widget, Gdk.Event e) {
			weak Gdk.EventButton event_button = (Gdk.EventButton) e;

			/* we're only interested in the 3rd mouse button */
			if (event_button.button != 3)
				return false;

			/* bail if the user didn't select any items */
			if (get_selection().count_selected_rows() == 0)
				return false;

			filter_menu.popup(
				null, null, null, null, event_button.button,
				Gtk.get_current_event_time()
			);

			return true;
		}

		/*
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
		*/

		private void create_columns() {
			Gtk.TreeViewColumn column;
			Gtk.CellRendererText cell;

			cell = new Gtk.CellRendererText();
			cell.ellipsize = Pango.EllipsizeMode.END;

			column = new Gtk.TreeViewColumn.with_attributes(
				"Artist", cell, "text", FilterColumn.Artist, null
			);
			column.resizable = true;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			column.min_width = 120;
			insert_column(column, -1);

			column = new Gtk.TreeViewColumn.with_attributes(
				"Title", cell, "text", FilterColumn.Title, null
			);
			column.resizable = true;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			column.min_width = 150;
			insert_column(column, -1);

			column = new Gtk.TreeViewColumn.with_attributes(
				"Album", cell, "text", FilterColumn.Album, null
			);
			column.resizable = true;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			column.min_width = 150;
			insert_column(column, -1);

			/*
			column = new Gtk.TreeViewColumn.with_attributes(
				"Duration", cell, "text", FilterColumn.Duration, null
			);
			column.resizable = true;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			column.min_width = 100;
			insert_column(column, -1);

			column = new Gtk.TreeViewColumn.with_attributes(
				"Genre", cell, "text", FilterColumn.Genre, null
			);
			column.resizable = true;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			column.min_width = 100;
			insert_column(column, -1);
			*/
		}

		private void create_context_menu() {
			/*
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
			*/
		}

		private void create_drag_n_drop() {
			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         _target_entries,
			                         Gdk.DragAction.MOVE);

			drag_data_get += on_drag_data_get;
		}

		[InstanceLast]
		private bool on_drag_data_get(Gtk.Widget w, Gdk.DragContext ctx,
		                              Gtk.SelectionData selection_data,
		                              uint info, uint time) {
			weak Gtk.TreeSelection sel = get_selection();
			weak List<weak Gtk.TreePath> lst = sel.get_selected_rows(null);
			List<uint> mid_list = new List<uint>();

			string buf = null;

			foreach (weak Gtk.TreePath p in lst) {
				Gtk.TreeIter iter;
				uint mid;

				model.get_iter(out iter, p);
				model.get(iter, 0, out mid, -1);

				mid_list.prepend(mid);
			}

			uint len = mid_list.length();
			uint[] mid_array = new uint[len];

			int pos = 0;
			foreach (uint mid in mid_list) {
				mid_array[pos++] = mid;
			}

			selection_data.set(
				Gdk.Atom.intern(_target_entries[0].target, true),
				8, (uchar[]) mid_array, (int) len * 32
			);

			return true;
		}
	}
}
