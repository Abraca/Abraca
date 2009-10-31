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
	public class PlaylistView : Gtk.TreeView, SelectedRowsMixin {
		/** context menu */
		private Gtk.Menu _playlist_menu;

		/* sensitivity conditions of _playlist_menu-items */
		private GLib.List<Gtk.MenuItem>
			_playlist_menu_item_when_one_selected = null;
		private GLib.List<Gtk.MenuItem>
			_playlist_menu_item_when_some_selected = null;
		private GLib.List<Gtk.MenuItem>
			_playlist_menu_item_when_none_selected = null;

		/** drag-n-drop targets */
		private const Gtk.TargetEntry[] _target_entries = {
			//DragDropTarget.PlaylistRow,
			{"application/x-xmmsclient-playlist-row", 0, DragDropTargetType.ROW},
			//DragDropTarget.Collection,
			{"application/x-xmmsclient-collection", 0, DragDropTargetType.COLL},
			//DragDropTarget.TrackId,
 			{"application/x-xmmsclient-track-id", 0, DragDropTargetType.MID},
			//DragDropTarget.UriList,
			{"text/uri-list", 0, DragDropTargetType.URI},
			//DragDropTarget.Internet
			{"_NETSCAPE_URL", 0, DragDropTargetType.INTERNET}
		};

		/** drag-n-drop sources */
		private const Gtk.TargetEntry[] _source_entries = {
			//DragDropTarget.PlaylistRow,
			{"application/x-xmmsclient-playlist-row", 0, DragDropTargetType.ROW},
			//DragDropTarget.TrackId
 			{"application/x-xmmsclient-track-id", 0, DragDropTargetType.MID}
		};

		/** current playlist sort order */
		private Xmms.Value _sort;

		private Client client;
		private Config config;

		public PlaylistView (PlaylistModel _model, Client _client, Config _config) {
			model = _model;
			client = _client;

			enable_search = false;
			search_column = 1;
			headers_visible = false;
			rules_hint = true;
			fixed_height_mode = true;

			var sel = get_selection();
			sel.set_mode(Gtk.SelectionMode.MULTIPLE);

			create_columns ();

			row_activated += on_row_activated;
			key_press_event += on_key_press_event;
			button_press_event += on_button_press_event;

			create_context_menu(config);
			get_selection().changed += on_selection_changed_update_menu;
			on_selection_changed_update_menu(get_selection());

			create_dragndrop();

			show_all();
		}


		private void on_selection_changed_update_menu(Gtk.TreeSelection s) {
			int n = s.count_selected_rows();

			foreach (var i in _playlist_menu_item_when_none_selected) {
				i.sensitive = (n == 0);
			}

			foreach (var i in _playlist_menu_item_when_one_selected) {
				i.sensitive = (n == 1);
			}

			foreach (var i in _playlist_menu_item_when_some_selected) {
				i.sensitive = (n > 0);
			}
		}


		private bool on_button_press_event(PlaylistView w, Gdk.EventButton button) {
			Gtk.TreePath path;
			int x, y;

			/* we're only interested in the 3rd mouse button */
			if (button.button != 3) {
				return false;
			}

			_playlist_menu.popup(
				null, null, null, button.button,
				Gtk.get_current_event_time()
			);

			x = (int) button.x;
			y = (int) button.y;

			/* Prevent selection-handling when right-clicking on an already
			   selected entry */
			if (get_path_at_pos(x, y, out path, null, null, null)) {
				var sel = get_selection();
				if (sel.path_is_selected(path)) {
					return true;
				}
			}

			return false;
		}


		private void delete_selected() {
			var sel = get_selection();
			var paths = sel.get_selected_rows(null);
			var lst = new GLib.List<uint>();

			foreach (unowned Gtk.TreePath path in paths) {
				lst.prepend(path.get_indices()[0]);
			}

			foreach (uint id in lst) {
				client.xmms.playlist_remove_entry(Xmms.ACTIVE_PLAYLIST, id);
			}
		}


		private bool on_key_press_event(PlaylistView w, Gdk.EventKey e) {
			int KEY_DELETE = 65535;

			if (e.keyval == KEY_DELETE) {

				delete_selected();

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
			unowned Gtk.Settings settings;
			Pango.FontDescription desc;
			unowned Pango.Context ctx;
			Pango.Layout layout;
			Gdk.Pixbuf pbuf;
			int w, h;


			pbuf_renderer = new Gtk.CellRendererPixbuf();
			pbuf_renderer.stock_size = Gtk.IconSize.MENU;

			column = new Gtk.TreeViewColumn.with_attributes (
				null, pbuf_renderer,
				"stock-id", PlaylistModel.Column.POSITION_INDICATOR,
				"sensitive", PlaylistModel.Column.AVAILABLE,
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
			text_renderer.ellipsize = Pango.EllipsizeMode.END;
			text_renderer.ellipsize_set = true;

			column = new Gtk.TreeViewColumn.with_attributes (
				null, text_renderer,
				"markup", PlaylistModel.Column.INFO,
				"sensitive", PlaylistModel.Column.AVAILABLE,
				null
			);
			column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);

			append_column (column);
		}


		private void create_context_menu(Config config) {
			Gtk.ImageMenuItem img_item;
			Gtk.MenuItem item;
			Gtk.Menu submenu;
			Gtk.Image img;

			_playlist_menu = new Gtk.Menu();

			/* Jump */
			item = new Gtk.MenuItem.with_label(_("Jump"));
			item.activate += jump_to_selected;
			_playlist_menu_item_when_one_selected.prepend(item);
			_playlist_menu.append(item);

			/* Separator */
			item = new Gtk.SeparatorMenuItem();
			_playlist_menu.append(item);

			/* Information */
			item = new Gtk.ImageMenuItem.from_stock(
				Gtk.STOCK_INFO, null
			);
			item.activate += on_menu_playlist_info;
			_playlist_menu_item_when_some_selected.prepend(item);
			_playlist_menu.append(item);

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
			_playlist_menu_item_when_some_selected.prepend(img_item);
			_playlist_menu.append(img_item);

			/* Delete */
			item = new Gtk.ImageMenuItem.from_stock(
				Gtk.STOCK_DELETE, null
			);
			item.activate += delete_selected;
			_playlist_menu_item_when_some_selected.prepend(item);
			_playlist_menu.append(item);

			/* Separator */
			item = new Gtk.SeparatorMenuItem();
			_playlist_menu.append(item);

			/* Sorting submenu */
			submenu = new Gtk.Menu();
			item = new Gtk.MenuItem.with_label(_("Artist"));
			item.activate += i => {
				on_menu_playlist_sort(config.sorting_artist);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Album"));
			item.activate += i => {
				on_menu_playlist_sort(config.sorting_album);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Title"));
			item.activate += i => {
				on_menu_playlist_sort(config.sorting_title);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Year"));
			item.activate += i => {
				on_menu_playlist_sort(config.sorting_year);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Path"));
			item.activate += i => {
				on_menu_playlist_sort(config.sorting_path);
			};
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Custom"));
			item.activate += i => {
				on_menu_playlist_sort(config.sorting_custom);
			};
			submenu.append(item);

			img = new Gtk.Image.from_stock(
				Gtk.STOCK_SORT_ASCENDING, Gtk.IconSize.MENU
			);

			img_item = new Gtk.ImageMenuItem.with_label(_("Sort"));
			img_item.set_image(img);
			img_item.set_submenu(submenu);
			_playlist_menu.append(img_item);

			/* Shuffle */
			item = new Gtk.MenuItem.with_label(_("Shuffle"));
			item.activate += i => {
				client.xmms.playlist_shuffle(Xmms.ACTIVE_PLAYLIST);
			};
			_playlist_menu.append(item);

			/* Clear */
			img_item = new Gtk.ImageMenuItem.from_stock(
				Gtk.STOCK_CLEAR, null
			);
			img_item.activate += i => {
				client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
			};
			_playlist_menu.append(img_item);

			_playlist_menu.show_all();
		}


		private void on_menu_playlist_sort(string type) {
			_sort = new Xmms.Value.from_list();

			foreach (string s in type.split(",")) {
				_sort.list_append(new Xmms.Value.from_string(s));
			}

			client.xmms.playlist_sort(Xmms.ACTIVE_PLAYLIST, _sort);
		}


		private void on_menu_playlist_filter(string key) {
			bool empty = true;
			string query = "";
			int column;

			if (key == "artist") {
				column = PlaylistModel.Column.ARTIST;
			} else if (key == "album") {
				column = PlaylistModel.Column.ALBUM;
			} else if (key == "genre") {
				column = PlaylistModel.Column.GENRE;
			} else {
				return;
			}

			var list = get_selected_rows<string>(column);

			Xmms.Collection union = new Xmms.Collection(Xmms.CollectionType.UNION);
			Xmms.Collection universe = Xmms.Collection.universe();
			Xmms.Collection coll;

			foreach (var val in list) {
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

				if (query != "") {
					query += " OR ";
				}
				query += key + ":\"" + val + "\"";
			}

			if (!empty) {
				Abraca.instance().main_window.main_hpaned.
					right_hpaned.filter_entry_set_text(query);
				Abraca.instance().main_window.main_hpaned.
					right_hpaned.filter_tree.query_collection(union);
			}
		}


		private void on_menu_playlist_info(Gtk.MenuItem item) {
			var list = get_selected_rows<uint>(PlaylistModel.Column.ID);
			foreach (var mid in list) {
				Abraca.instance().medialib.info_dialog_add_id(mid);
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


		private void on_drag_data_get(PlaylistView w, Gdk.DragContext ctx,
		                              Gtk.SelectionData selection_data,
		                              uint info, uint time) {
			GLib.List<uint> pos_list = new GLib.List<uint>();
			Gdk.Atom dnd_atom;

			var sel = get_selection();
			var lst = sel.get_selected_rows(null);

			if (info == (uint) DragDropTargetType.ROW) {
				foreach (unowned Gtk.TreePath p in lst) {
					pos_list.prepend(p.get_indices()[0]);
				}
				dnd_atom = Gdk.Atom.intern(_source_entries[0].target, true);
			} else {
				Gtk.TreeIter iter;
				uint mid;
				foreach (unowned Gtk.TreePath p in lst) {
					model.get_iter(out iter, p);
					model.get(iter, PlaylistModel.Column.ID, out mid);
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
			unowned uchar[] data = (uchar[]) pos_array;
			data.length = (int)(pos_array.length * sizeof(uint));

			selection_data.set(dnd_atom, 8, data);
		}


		/**
		 * Take care of the various types of drops.
		 */
		private void on_drag_data_receive(PlaylistView w, Gdk.DragContext ctx, int x, int y,
										  Gtk.SelectionData sel, uint info, uint time) {
			bool success = false;

			if (info == (uint) DragDropTargetType.ROW) {
				success = on_drop_playlist_entries(sel, x, y);
			} else if (info == (uint) DragDropTargetType.MID) {
				success = on_drop_medialib_id(sel, x, y);
			} else if (info == (uint) DragDropTargetType.COLL) {
				success = on_drop_collection(sel, x, y);
			} else if (info == (uint) DragDropTargetType.URI) {
				success = on_drop_files(sel, x, y);
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

			/* TODO: Updated when #515408 vala bug has been fixed */
			unowned uint[] source = (uint[]) sel.data;
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
						client.xmms.playlist_move_entry(Xmms.ACTIVE_PLAYLIST, source[i]-downward, (uint) dest-1);
						downward++;
					} else {
						client.xmms.playlist_move_entry(Xmms.ACTIVE_PLAYLIST, source[i], (uint) dest+upward);
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

			/* TODO: Updated when #515408 vala bug has been fixed */
			unowned uint[] ids = (uint[]) sel.data;
			ids.length = (int)(sel.length / sizeof(uint));

			if (get_dest_row_at_pos(x, y, out path, out align)) {
				int pos = path.get_indices()[0];
				foreach (uint id in ids) {
					client.xmms.playlist_insert_id(Xmms.ACTIVE_PLAYLIST, pos, id);
				}
			} else {
				foreach (uint id in ids) {
					client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
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

			uri_list = ((string) sel.data).split("\r\n");

			for (int i = 0; uri_list != null && uri_list[i] != null; i++) {
				if (internet && (i % 2 != 0)) {
					continue;
				}

				if (((string) uri_list[i]).len() > 0) {
					Gtk.TreeViewDropPosition align;
					Gtk.TreePath path;
					bool is_dir = false;

					string uri = GLib.Uri.unescape_string(uri_list[i]);
					if (GLib.Uri.parse_scheme(uri) == "file") {
						string[] tmp = uri.split("file://", 2);
						if (tmp != null && tmp[1] != null) {
							GLib.FileTest pattern = GLib.FileTest.EXISTS | GLib.FileTest.IS_DIR;
							is_dir = GLib.FileUtils.test(tmp[1], pattern);
						}
					}

					if (is_dir) {
						client.xmms.playlist_radd (Xmms.ACTIVE_PLAYLIST, uri);
					} else if (get_dest_row_at_pos(x, y, out path, out align)) {
						int pos = path.get_indices()[0];
						client.xmms.playlist_insert_url(Xmms.ACTIVE_PLAYLIST, pos, uri);
					} else {
						client.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, uri);
					}
				}
			}

			return true;
		}


		private bool on_drop_collection(Gtk.SelectionData sel, int x, int y) {
			Xmms.Collection coll;
			Gtk.TreeViewDropPosition align;
			Gtk.TreePath path;

			GLib.stdout.printf("apan: %s\n", (string) sel.data);

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
				client.xmms.playlist_insert_collection(Xmms.ACTIVE_PLAYLIST, pos, coll, _sort);
			} else {
				client.xmms.playlist_add_collection(Xmms.ACTIVE_PLAYLIST, coll, _sort);
			}

			return true;
		}


		/**
		 * Perform a jump to that song and start playback if not already
		 * playing.
		 */
		private void jump_to_pos(int pos) {
			client.xmms.playlist_set_next(pos).notifier_set((res) => {
				client.xmms.playback_tickle().notifier_set((res) => {
					client.xmms.playback_status().notifier_set((res) => {
						int status;
						res.get_int(out status);
						if (status != Xmms.PlaybackStatus.PLAY) {
							client.xmms.playback_start();
						}
						return true;
					});
					return true;
				});
				return true;
			});
		}


		private void jump_to_selected(Gtk.MenuItem tree) {
			jump_to_pos(get_selection().get_selected_rows(null).first().data
			            .get_indices()[0]);
		}


		/**
		 * When clicking a row, perform a jump to that song and start
		 * playback if not already playing.
		 */
		private void on_row_activated(PlaylistView tree, Gtk.TreePath path,
		                              Gtk.TreeViewColumn column) {
			jump_to_pos(path.get_indices()[0]);
		}
	}
}
