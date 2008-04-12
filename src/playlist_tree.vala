/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008  Abraca Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using GLib;

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

		/** have we scrolled to current position? */
		private bool _have_scrolled;

		/** current sorting order */
		private string[] _sort;

		/** keep track of current playlist position */
		private Gtk.TreeRowReference _position = null;

		/** keep track of playlist position <-> medialib id */
		private PlaylistMap playlist_map;

		/* metadata properties we're interested in */
		private const string[] _properties = {
			"artist", "album", "title", "duration"
		};

		/** drag-n-drop targets */
		private const Gtk.TargetEntry[] _target_entries = {
			DragDropTarget.PlaylistRow,
			DragDropTarget.Collection,
			DragDropTarget.TrackId,
			DragDropTarget.UriList,
			DragDropTarget.Internet
		};

		/** drag-n-drop sources */
		private const Gtk.TargetEntry[] _source_entries = {
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
			Gdk.Pixbuf pbuf;
			int w, h;


			pbuf_renderer = new Gtk.CellRendererPixbuf();
			pbuf_renderer.stock_size = Gtk.IconSize.MENU;

			column = new Gtk.TreeViewColumn.with_attributes (
				null, pbuf_renderer,
				"stock-id", PlaylistColumn.PositionIndicator,
				null
			);

			/* Find out the width of the position idicator icon */
			pbuf = render_icon(Gtk.STOCK_GO_FORWARD, Gtk.IconSize.MENU, null);

			/* Add some extra width otherwise it will not fit into the column */
			column.set_min_width(pbuf.width + 3 * 2);
			column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);

			append_column (column);


			text_renderer = new Gtk.CellRendererText();

			/* Find out the current font height */
			settings = Gtk.Settings.get_default();

			desc = new Pango.FontDescription();
			desc.set_family (settings.gtk_font_name);

			ctx = get_pango_context();

			layout = new Pango.Layout(ctx);
			layout.set_text("look behind you! a three-headed monkey!", -1);
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
			Gtk.Image img;

			_playlist_menu = new Gtk.Menu();

			/* Sorting submenu */
			submenu = new Gtk.Menu();
			item = new Gtk.MenuItem.with_label(_("Artist"));
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_artist);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Album"));
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_album);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Title"));
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_title);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Year"));
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_year);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Path"));
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_path);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Custom"));
			item.activate += i => {
				on_menu_playlist_sort(Abraca.instance().config.sorting_custom);
			};
			submenu.append(item);

			img = new Gtk.Image.from_stock(
				Gtk.STOCK_SORT_ASCENDING, Gtk.IconSize.MENU
			);

			img_item = new Gtk.ImageMenuItem.with_label(_("Sort"));
			img_item.set_image(img);
			img_item.set_submenu(submenu);
			_playlist_menu.append(img_item);

			/* Filter submenu */
			submenu = new Gtk.Menu();

			item = new Gtk.MenuItem.with_label(_("By Artist"));
			item.activate += i => {
				on_menu_playlist_filter("artist");
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("By Album"));
			item.activate += i => {
				on_menu_playlist_filter("album");
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("By Genre"));
			item.activate += i => {
				on_menu_playlist_filter("genre");
			};
			submenu.append(item);

			img_item = new Gtk.ImageMenuItem.from_stock(
				Gtk.STOCK_FIND, null
			);
			img_item.set_submenu(submenu);
			_playlist_menu.append(img_item);

			item = new Gtk.MenuItem.with_label(_("Shuffle"));
			item.activate += i => {
				Client c = Client.instance();
				c.xmms.playlist_shuffle(_playlist);
			};
			_playlist_menu.append(item);

			img_item = new Gtk.ImageMenuItem.from_stock(
				Gtk.STOCK_CLEAR, null
			);
			img_item.activate += i => {
				Client c = Client.instance();
				c.xmms.playlist_clear(_playlist);
			};
			_playlist_menu.append(img_item);

			_playlist_menu.show_all();
		}


		private void on_menu_playlist_sort(string type) {
			Client c = Client.instance();
			_sort = type.split(",");

			c.xmms.playlist_sort(_playlist, (string[]) _sort);
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
			                         _source_entries,
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
			Gdk.Atom dnd_atom;

			string buf = null;

			if (info == (uint) DragDropTargetType.ROW) {
				foreach (weak Gtk.TreePath p in lst) {
					pos_list.prepend(p.get_indices()[0]);
				}
				dnd_atom = Gdk.Atom.intern(_source_entries[0].target, true);
			} else {
				Gtk.TreeIter iter;
				uint mid;
				foreach (weak Gtk.TreePath p in lst) {
					model.get_iter(out iter, p);
					model.get(iter, PlaylistColumn.ID, out mid);
					pos_list.prepend(mid);
				}
				dnd_atom = Gdk.Atom.intern(_source_entries[1].target, true);
			}

			uint len = pos_list.length();
			uint[] pos_array = new uint[len];

			int pos = 0;
			foreach (uint position in pos_list) {
				pos_array[pos++] = position;
			}

			/* This should be removed as #515408 gets fixed. */
			weak uchar[] data = (uchar[]) pos_array;
			data.length = (int)(pos_array.length * sizeof(uint));

			selection_data.set(dnd_atom, 8, data);

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
				GLib.stdout.printf("apan1\n");
				success = on_drop_playlist_entries(sel, x, y);
			} else if (info == (uint) DragDropTargetType.MID) {
				GLib.stdout.printf("apan2\n");
				success = on_drop_medialib_id(sel, x, y);
			} else if (info == (uint) DragDropTargetType.COLL) {
				GLib.stdout.printf("apan3\n");
				success = on_drop_collection(sel, x, y);
			} else if (info == (uint) DragDropTargetType.URI) {
				GLib.stdout.printf("Drop from filesystem not implemented\n");
				// success = on_drop_files(sel, x, y);
			} else if (info == (uint) DragDropTargetType.INTERNET) {
				success = on_drop_files(sel, x, y, true);
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

			/* TODO: Updated when #515408 vala bug has been fixed */
			weak uint[] source = (uint[]) sel.data;
			source.length = (int)(sel.length / sizeof(uint));

			if (get_dest_row_at_pos(x, y, out path, out align)) {
				int dest = path.get_indices()[0];

				if (align == Gtk.TreeViewDropPosition.AFTER
						|| align ==  Gtk.TreeViewDropPosition.INTO_OR_AFTER) {
					dest++;
				}

				int downward = 0;
				int upward = 0;

				for (int i = source.length - 1; i >= 0; i--) {
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

			/* TODO: Updated when #515408 vala bug has been fixed */
			weak uint[] ids = (uint[]) sel.data;
			ids.length = (int)(sel.length / sizeof(uint));

			if (get_dest_row_at_pos(x, y, out path, out align)) {
				int pos = path.get_indices()[0];
				foreach (uint id in ids) {
					c.xmms.playlist_insert_id(_playlist, pos, id);
				}
			} else {
				foreach (uint id in ids) {
					c.xmms.playlist_add_id(_playlist, id);
				}
			}

			return true;
		}

		/**
		 * Handle dropping of urls.
		 * TODO: Handle coding of urls from nautilus.
		 * TODO: Handle inserting of directories.
		 */
		private bool on_drop_files(Gtk.SelectionData sel, int x, int y,
		                           bool internet = false) {
			string[] uri_list;

			Client c = Client.instance();

			uri_list = ((string) sel.data).split("\n");

			for (int i = 0; uri_list[i] != null; i++) {
				if (internet && (i % 2 != 0)) {
					continue;
				}

				if (((string)uri_list[i]).len() > 0) {
					Gtk.TreeViewDropPosition align;
					Gtk.TreePath path;

					if (get_dest_row_at_pos(x, y, out path, out align)) {
						int pos = path.get_indices()[0];

						c.xmms.playlist_insert_url(
							Xmms.ACTIVE_PLAYLIST, pos, uri_list[i]
						);
					} else {
						c.xmms.playlist_add_url(
							Xmms.ACTIVE_PLAYLIST, uri_list[i]
						);
					}
				}
			}

			return true;
		}

		private bool on_drop_collection(Gtk.SelectionData sel, int x, int y) {
			Client c = Client.instance();
			Xmms.Collection coll;
			Gtk.TreeViewDropPosition align;
			Gtk.TreePath path;

			string[] collection_data = ((string) sel.data).split("/");
			string coll_ns = collection_data[0];
			string coll_name = collection_data[1];

			coll = new Xmms.Collection(Xmms.CollectionType.REFERENCE);
			coll.attribute_set("reference", coll_name);
			coll.attribute_set("namespace", coll_ns);

			/* TODO: Check if store is empty to get rid of assert */
			if (get_dest_row_at_pos(x, y, out path, out align)) {
				int pos = path.get_indices()[0];

				if (align == Gtk.TreeViewDropPosition.AFTER ||
				    align ==  Gtk.TreeViewDropPosition.INTO_OR_AFTER) {
					pos++;
				}
				c.xmms.playlist_insert_collection(_playlist, pos, coll, _sort);
			} else {
				c.xmms.playlist_add_collection(_playlist, coll, _sort);
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
		private void on_playlist_position(Client c, string playlist, int pos) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter;

			/* Remove the old position indicator */
			if (_position.valid()) {
				model.get_iter(out iter, _position.get_path());
				store.set(iter, PlaylistColumn.PositionIndicator, 0);
			}

			/* Playlist is probably empty */
			if (pos < 0)
				return;

			/* Add the new position indicator */
			if (store.iter_nth_child (out iter, null, (int) pos)) {
				Gtk.TreePath path;
				uint mid;

				/* Notify the Client of the current medialib id */
				model.get(iter, PlaylistColumn.ID, out mid);
				c.set_playlist_id(mid);

				store.set(
					iter,
					PlaylistColumn.PositionIndicator,
					Gtk.STOCK_GO_FORWARD
				);

				path = model.get_path(iter);

				_position = new Gtk.TreeRowReference(model, path);

				if (!_have_scrolled) {
					scroll_to_cell(path, null, true, (float) 0.25, (float) 0);
					_have_scrolled = true;
				}
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
			_have_scrolled = false;

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
				_("<b>%s</b> - <small>%d:%02d</small>\n" +
				"<small>by</small> %s <small>from</small> %s"),
				title, dur_min, dur_sec, artist, album
			);

			foreach (weak Gtk.TreeRowReference row in lst) {
				weak Gtk.TreePath path;
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
