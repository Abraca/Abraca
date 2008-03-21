/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */

namespace Abraca {
	enum PlaylistColumn {
		ID = 0,
		PositionIndicator,
		Artist,
		Album,
		Genre,
		Info,
		Total
	}

	public class PlaylistTree : Gtk.TreeView {
		/** context menu */
		private Gtk.Menu _playlist_menu;

		/** current playback status */
		private int _status;

		/** current playlist displayed */
		private string _playlist;

		/** keep track of current playlist position */
		private Gtk.TreeRowReference _position = null;

		/** keep track of playlist position <-> medialib id */
		private PlaylistMap playlist_map;

		/* metadata properties we're interested in */
		private const string[] _properties = {
			"artist", "album", "title", "duration"
		};

		/** allowed drag-n-drop variants */
		private const Gtk.TargetEntry[] _target_entries = {
			DragDropTarget.PlaylistRow,
			DragDropTarget.TrackId
		};

		construct {
			Client c = Client.instance();

			enable_search = true;
			search_column = 1;
			headers_visible = false;
			show_expanders = false;
			rules_hint = true;
			fixed_height_mode = true;

			weak Gtk.TreeSelection sel = get_selection();
			sel.set_mode(Gtk.SelectionMode.MULTIPLE);

			playlist_map = new PlaylistMap();

			create_columns ();

			model = new Gtk.ListStore(
				PlaylistColumn.Total,
				typeof(int), typeof(string), typeof(string),
				typeof(string), typeof(string), typeof(string)
			);

			row_activated += on_row_activated;
			key_press_event += on_key_press_event;
			button_press_event += on_button_press_event;

			c.playlist_loaded += on_playlist_loaded;

			c.playlist_add += on_playlist_add;
			c.playlist_move += on_playlist_move;
			c.playlist_insert += on_playlist_insert;
			c.playlist_remove += on_playlist_remove;
			c.playlist_position += on_playlist_position;

			c.playback_status += on_playback_status;

			c.media_info += on_media_info;

			create_context_menu();
			create_dragndrop();

			show_all();
		}


		private bool on_button_press_event(Gtk.Widget w, Gdk.Event e) {
			weak Gdk.EventButton button_event = (Gdk.EventButton) e;

			/* we're only interested in the 3rd mouse button */
			if (button_event.button != 3) {
				return false;
			}

			_playlist_menu.popup(
				null, null, null, button_event.button,
				Gtk.get_current_event_time()
			);

			return true;
		}


		private bool on_key_press_event(Gtk.Widget w, Gdk.EventKey e) {
			int KEY_DELETE = 65535;

			if (e.keyval == KEY_DELETE) {
				weak GLib.List<weak Gtk.TreePath> paths;
				weak Gtk.TreeSelection sel;
				GLib.List<uint> lst;


				sel = get_selection();
				paths = sel.get_selected_rows(null);
				lst = new GLib.List<uint>();

				foreach (weak Gtk.TreePath path in paths) {
					lst.prepend(path.get_indices()[0]);
				}

				Client c = Client.instance();

				foreach (uint id in lst) {
					c.xmms.playlist_remove_entry(_playlist, id);
				}

				return true;
			}

			return false;
		}


		/**
		 * Create metadata and coverart columns.
		 */
		private void create_columns() {
			Gtk.CellRendererText text_renderer;
			Gtk.CellRendererPixbuf pbuf_renderer;
			Gtk.TreeViewColumn column;
			weak Gtk.Settings settings;
			Pango.FontDescription desc;
			weak Pango.Context ctx;
			Pango.Layout layout;
			int w, h;


			pbuf_renderer = new Gtk.CellRendererPixbuf();
			pbuf_renderer.stock_size = Gtk.IconSize.SMALL_TOOLBAR;

			column = new Gtk.TreeViewColumn.with_attributes (
				null, pbuf_renderer,
				"stock-id", PlaylistColumn.PositionIndicator,
				null
			);

			column.set_min_width(20);
			column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);

			append_column (column);


			text_renderer = new Gtk.CellRendererText();

			/* Find out the current font height */
			settings = Gtk.Settings.get_default();

			desc = new Pango.FontDescription();
			desc.set_family (settings.gtk_font_name);

			ctx = get_pango_context();

			layout = new Pango.Layout(ctx);
			layout.set_text("look behind you! a three-headed monkey!\0", -1);
			layout.set_font_description (desc);

			layout.get_pixel_size(out w, out h);

			/* Two rows, plus some extra height */
			text_renderer.height = h * 2 + 4;

 			insert_column_with_attributes(
				-1, null, text_renderer,
				"markup", PlaylistColumn.Info, null
			);
		}


		private void create_context_menu() {
			Gtk.ImageMenuItem img_item;
			Gtk.MenuItem item;
			Gtk.Menu submenu;

			_playlist_menu = new Gtk.Menu();

			/* Sorting submenu */
			submenu = new Gtk.Menu();
			item = new Gtk.MenuItem.with_label("Artist");
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_artist);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Album");
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_album);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Title");
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_title);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Year");
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_year);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Path");
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_path);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Custom");
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_custom);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Sort");
			item.set_submenu(submenu);
			_playlist_menu.append(item);

			/* Filter submenu */
			submenu = new Gtk.Menu();

			item = new Gtk.MenuItem.with_label("Artist");
			item.activate += i => {
				on_menu_playlist_filter("artist");
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Album");
			item.activate += i => {
				on_menu_playlist_filter("album");
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Genre");
			item.activate += i => {
				on_menu_playlist_filter("genre");
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label("Filter for...");
			item.set_submenu(submenu);
			_playlist_menu.append(item);

			item = new Gtk.MenuItem.with_label("Shuffle");
			item.activate += i => {
				Client c = Client.instance();
				c.xmms.playlist_shuffle(_playlist);
			};
			_playlist_menu.append(item);

			item = new Gtk.MenuItem.with_label("Clear");
			item.activate += i => {
				Client c = Client.instance();
				c.xmms.playlist_clear(_playlist);
			};
			_playlist_menu.append(item);

			_playlist_menu.show_all();
		}


		private void on_menu_playlist_sort(string type) {
			Client c = Client.instance();
			string[] sort = type.split(",");

			c.xmms.playlist_sort(_playlist, (string[]) sort);
		}

		private void on_menu_playlist_filter(string key) {
			Client c = Client.instance();
			weak GLib.List<Gtk.TreePath> list;
			Gtk.TreeSelection sel;
			Gtk.TreeIter iter;
			string val;
			int column;
			bool empty = true;

			if (key == "artist") {
				column = PlaylistColumn.Artist;
			} else if (key == "album") {
				column = PlaylistColumn.Album;
			} else if (key == "genre") {
				column = PlaylistColumn.Genre;
			} else {
				return;
			}

			sel = get_selection();
			list = sel.get_selected_rows(null);

			Xmms.Collection union = new Xmms.Collection(Xmms.CollectionType.UNION);
			Xmms.Collection universe = Xmms.Collection.universe();
			Xmms.Collection coll;

			foreach(weak Gtk.TreePath path in list) {
				model.get_iter(out iter, path);
				model.get(iter, column, out val);

				if (val == "Unknown") {
					continue;
				}

				if (empty) {
					empty = false;
				}

				coll = new Xmms.Collection(Xmms.CollectionType.EQUALS);

				coll.attribute_set("field", key);
				coll.attribute_set("value", val);
				coll.add_operand(universe);

				union.add_operand(coll);
			}

			if (!empty) {
				Abraca.instance().main_window.main_hpaned.
					right_hpaned.filter_tree.query_collection(union);
			}
		}

		/**
		 * Setup dragndrop for the playlist.
		 */
		private void create_dragndrop() {
			enable_model_drag_dest(_target_entries,
			                       Gdk.DragAction.MOVE);

			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         _target_entries,
			                         Gdk.DragAction.MOVE);

			drag_data_received += on_drag_data_receive;
			drag_data_get += on_drag_data_get;
		}

		[InstanceLast]
		private bool on_drag_data_get(Gtk.Widget w, Gdk.DragContext ctx,
		                              Gtk.SelectionData selection_data,
		                              uint info, uint time) {
			weak Gtk.TreeSelection sel = get_selection();
			weak GLib.List<weak Gtk.TreePath> lst = sel.get_selected_rows(null);
			GLib.List<uint> pos_list = new GLib.List<uint>();

			string buf = null;

			foreach (weak Gtk.TreePath p in lst) {
				pos_list.prepend(p.get_indices()[0]);
			}

			uint len = pos_list.length();
			uint[] pos_array = new uint[len];

			int pos = 0;
			foreach (uint position in pos_list) {
				pos_array[pos++] = position;
			}

			/* This should be removed as #515409 gets fixed. */
			weak uchar[] data = (uchar[]) pos_array;
			data.length = pos_array.length * 32;

			selection_data.set(
					Gdk.Atom.intern(_target_entries[0].target, true),
					8, data
			);

			return true;
		}

		/**
		 * Take care of the various types of drops.
		 */
		[InstanceLast]
		private void on_drag_data_receive(Gtk.Widget w, Gdk.DragContext ctx, int x, int y,
		                              Gtk.SelectionData sel, uint info,
		                              uint time) {

			Gtk.TargetList target_list;
			bool success = false;

			if (info == (uint) DragDropTargetType.ROW) {
				success = on_drop_playlist_entries(sel, x, y);
			} else if (info == (uint) DragDropTargetType.MID) {
				success = on_drop_medialib_id(sel, x, y);
			} else if (info == (uint) DragDropTargetType.URI) {
				GLib.stdout.printf("Drop from filesystem not implemented\n");
			} else if (info == (uint) DragDropTargetType.INTERNET) {
				GLib.stdout.printf("Drop from intarweb not implemented\n");
			} else {
				GLib.stdout.printf("Nogle gange går der kuk i maskineriet\n");
			}

			/* success, but do not remove from source */
			Gtk.drag_finish(ctx, success, false, time);
		}

		/**
		 * Handle dropping of playlist entries.
		 */

		private bool on_drop_playlist_entries(Gtk.SelectionData sel, int x, int y) {
			Gtk.TreeViewDropPosition align;
			Gtk.TreePath path;

			Client c = Client.instance();

			weak uint[] source = (uint[]) sel.data;

			/* TODO: Check if store is empty to get rid of assert */
			if (get_dest_row_at_pos(x, y, out path, out align)) {
				int dest = path.get_indices()[0];

				if (align == Gtk.TreeViewDropPosition.AFTER
						|| align ==  Gtk.TreeViewDropPosition.INTO_OR_AFTER) {
					dest++;
				}

				int downward = 0;
				int upward = 0;

				for (int i = sel.length/32 - 1; i >= 0; i--) {
					if (source[i] < dest) {
						c.xmms.playlist_move_entry(_playlist, source[i]-downward, (uint) dest-1);
						downward++;
					} else {
						c.xmms.playlist_move_entry(_playlist, source[i], (uint) dest+upward);
						upward++;
					}
				}
			}

			return false;
		}
		/**
		 * Handle dropping of medialib ids.
		 */
		private bool on_drop_medialib_id(Gtk.SelectionData sel, int x, int y) {
			Gtk.TreeViewDropPosition align;
			Gtk.TreePath path;

			Client c = Client.instance();

			weak uint[] ids = (uint[]) sel.data;

			/* TODO: Check if store is empty to get rid of assert */
			if (get_dest_row_at_pos(x, y, out path, out align)) {
				int pos = path.get_indices()[0];

				for (int i; i < sel.length / 32; i++) {
					c.xmms.playlist_insert_id(_playlist, pos, ids[i]);
				}
			} else {
				for (int i; i < sel.length / 32; i++) {
					c.xmms.playlist_add_id(_playlist, ids[i]);
				}
			}

			return true;
		}

		/**
		 * Insert a row when a new entry has been inserted in the playlist.
		 */
		private void on_playlist_insert(Client c, string playlist, uint mid, int pos) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreePath path;
			Gtk.TreeIter iter;

			if (playlist != _playlist) {
				return;
			}

			path = new Gtk.TreePath.from_indices(pos, -1);
			if (model.get_iter(out iter, path)) {
				Gtk.TreeIter added;

				store.insert_before (out added, iter);

				Gtk.TreePath path = store.get_path(added);
				Gtk.TreeRowReference row = new Gtk.TreeRowReference(store, path);
				playlist_map.insert(mid, row);

				/* TODO: Cast shouldn't be needed here */
				c.get_media_info(mid, (string[]) _properties);
			}
		}

		/**
		 * Removes the row when an entry has been removed from the playlist.
		 */
		private void on_playlist_remove(Client c, string playlist, int pos) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreePath path;
			Gtk.TreeIter iter;

			if (playlist != _playlist) {
				return;
			}

			path = new Gtk.TreePath.from_indices(pos, -1);
			if (model.get_iter(out iter, path)) {
				uint mid;

				model.get(iter, PlaylistColumn.ID, out mid);

				playlist_map.remove(mid, path);
				store.remove(iter);
			}
		}

		/**
		 * TODO: Move row x to pos y.
		 */
		private void on_playlist_move(Client c, string playlist, int pos, int npos) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter, niter;
			if (store.iter_nth_child (out iter, null, pos) &&
			    store.iter_nth_child(out niter, null, npos)) {
				if (pos < npos) {
					store.move_after (iter, niter);
				} else {
					store.move_before (iter, niter);
				}
			}
		}


		/**
		 * Update the position indicator to point at the
		 * current playing entry.
		 */
		private void on_playlist_position(Client c, string playlist, uint pos) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter;

			/* Remove the old position indicator */
			if (_position.valid()) {
				model.get_iter(out iter, _position.get_path());
				store.set(iter, PlaylistColumn.PositionIndicator, 0);
			}

			/* Add the new position indicator */
			if (store.iter_nth_child (out iter, null, (int) pos)) {
				uint mid;

				/* Notify the Client of the current medialib id */
				model.get(iter, PlaylistColumn.ID, out mid);
				c.set_playlist_id(mid);

				store.set(
					iter,
					PlaylistColumn.PositionIndicator,
					Gtk.STOCK_GO_FORWARD
				);

				_position = new Gtk.TreeRowReference (
					model, model.get_path(iter)
				);
			}
		}


		/**
		 * When clicking a row, perform a jump to that song and start
		 * playback if not already playing.
		 */
		[InstanceLast]
		private void on_row_activated(Gtk.TreeView tree, Gtk.TreePath path,
		                              Gtk.TreeViewColumn column) {
			Client c = Client.instance();
			int pos = path.get_indices()[0];

			c.xmms.playlist_set_next(pos);
			c.xmms.playback_tickle();

			if (_status != Xmms.PlaybackStatus.PLAY) {
				c.xmms.playback_start();
			}
		}

		/**
		 * Keep track of status so we know what to do when an item has been clicked.
		 */
		private void on_playback_status(Client c, int status) {
			_status = status;

			/* Notify the Client of the current medialib id */
			if (_position.valid()) {
				Gtk.TreeIter iter;
				uint mid;

				model.get_iter(out iter, _position.get_path());
				model.get(iter, PlaylistColumn.ID, out mid);

				c.set_playlist_id(mid);
			}
		}

		/**
		 * Called when xmms2 has loaded a new playlist, simply requests
		 * the mids of that playlist.
		 */
		private void on_playlist_loaded(Client c, string name) {
			_playlist = name;

			c.xmms.playlist_list_entries(name).notifier_set(
				on_playlist_list_entries
			);
		}

		private void on_playlist_add(Client c, string playlist, uint mid) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeRowReference row;
			Gtk.TreePath path;
			Gtk.TreeIter iter;

			if (playlist != _playlist) {
				return;
			}

			store.append(out iter);

			path = store.get_path(iter);
			row = new Gtk.TreeRowReference(store, path);

			playlist_map.insert(mid, row);

			/* TODO: Cast shouldn't be needed here */
			c.get_media_info(mid, (string[]) _properties);
		}

		/**
		 * Refresh the whole playlist.
		 */
		[InstanceLast]
		private void on_playlist_list_entries(Xmms.Result #res) {
			Client c = Client.instance();
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter, sibling;
			bool first = true;

			playlist_map.clear();
			store.clear();

			/* disconnect our model while the shit hits the fan */
			set_model(null);

			for (res.list_first(); res.list_valid(); res.list_next()) {
				Gtk.TreeRowReference row;
				Gtk.TreePath path;
				uint mid;
				int pos;

				if (!res.get_uint(out mid))
					continue;

				if (first) {
					store.insert_after(out iter, null);
					first = !first;
				} else {
					store.insert_after(out iter, sibling);
				}

				store.set(iter, PlaylistColumn.ID, mid);

				sibling = iter;

				path = store.get_path(iter);
				row = new Gtk.TreeRowReference(store, path);

				playlist_map.insert(mid, row);
			}

			/* reconnect the model again */
			set_model(store);

			foreach (uint mid in playlist_map.get_ids()) {
				c.get_media_info(mid, (string[]) _properties);
			}
		}

		/**
		 * TODO: Should check the future hash[mid] = [row1, row2, row3] and
		 *       update the rows accordingly.
		 *       Should also update the current coverart image.
		 */
		private void on_media_info(Client c, weak GLib.HashTable<string,pointer> m) {
			Gtk.ListStore store = (Gtk.ListStore) model;

			weak GLib.SList<Gtk.TreeRowReference> lst;

			string info;
			weak string artist, album, title, genre;
			int duration, dur_min, dur_sec, pos, id;
			uint mid;

			mid = m.lookup("id").to_int();

			lst = playlist_map.lookup(mid);
			if (lst == null) {
				/* the given mid doesn't match any of our rows */
				return;
			}

			duration = m.lookup("duration").to_int();

			artist = (string) m.lookup("artist");
			album = (string) m.lookup("album");
			genre = (string) m.lookup("genre");
			title = (string) m.lookup("title");

			dur_min = duration / 60000;
			dur_sec = (duration % 60000) / 1000;

			info = GLib.Markup.printf_escaped(
				"<b>%s</b> - <small>%d:%02d</small>\n" +
				"<small>by</small> %s <small>from</small> %s",
				title, dur_min, dur_sec, artist, album
			);

			foreach (weak Gtk.TreeRowReference row in lst) {
				Gtk.TreePath path;
				Gtk.TreeIter iter;

				path = row.get_path();

				if (!row.valid() || !model.get_iter(out iter, path)) {
					GLib.stdout.printf("row not valid\n");
					continue;
				}

				store.set(iter, PlaylistColumn.Info, info,
						PlaylistColumn.Artist, artist,
						PlaylistColumn.Album, album,
						PlaylistColumn.Genre, genre);
			}
		}
	}
}
