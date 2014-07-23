/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2014 Abraca Team
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
	public class PlaylistView : Abraca.TreeView {
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
		private Gtk.TargetEntry[] _target_entries = {
			Abraca.TargetEntry.PlaylistEntries,
			Abraca.TargetEntry.Collection,
			Abraca.TargetEntry.UriList,
			Abraca.TargetEntry.Internet
		};

		/** drag-n-drop sources */
		private Gtk.TargetEntry[] _source_entries = {
			Abraca.TargetEntry.PlaylistEntries,
			Abraca.TargetEntry.Collection,
		};

		/** current playlist sort order */
		private Xmms.Value _sort;

		private Client client;
		private Config config;
		private Medialib medialib;
		private Searchable search;

		public PlaylistView (PlaylistModel _model, Client _client,
		                     Medialib m, Config _config, Searchable _search)
		{
			model = _model;
			client = _client;
			config = _config;
			medialib = m;
			search = _search;

			enable_search = false;
			search_column = 1;
			headers_visible = false;
			rules_hint = true;
			tooltip_column = PlaylistModel.Column.INFO;
			fixed_height_mode = true;

			create_columns ();
			create_context_menu(config);
			create_dragndrop();

			row_activated.connect(on_row_activated);
			key_press_event.connect(on_key_press_event);
			button_press_event.connect(on_button_press_event);

			var selection = get_selection();
			selection.set_mode(Gtk.SelectionMode.MULTIPLE);
			selection.changed.connect(on_selection_changed_update_menu);

			on_selection_changed_update_menu(selection);

			_sort = new Xmms.Value.from_list();
			_sort.list_append (new Xmms.Value.from_string("album"));
			_sort.list_append (new Xmms.Value.from_string("tracknr"));

			show_all();
		}


		private void on_selection_changed_update_menu(Gtk.TreeSelection s)
		{
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


		private bool on_button_press_event(Gtk.Widget w, Gdk.EventButton button)
		{
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


		private void delete_selected()
		{
			var entries = new Gee.LinkedList<uint>();

			foreach_selected_row<uint> (PlaylistModel.Column.ID, (idx, mid) => {
				entries.insert (0, idx);
			});

			foreach (var idx in entries) {
				client.xmms.playlist_remove_entry(Xmms.ACTIVE_PLAYLIST, idx);
			}
		}


		private bool on_key_press_event(Gtk.Widget w, Gdk.EventKey e)
		{
			if (e.keyval != Gdk.keyval_from_name("Delete") && e.keyval != Gdk.keyval_from_name("BackSpace"))
				return false;
			delete_selected();
			return true;
		}


		/**
		 * Create metadata and coverart columns.
		 */
		private void create_columns()
		{
			Gtk.CellRendererText text_renderer;
			Gtk.CellRendererPixbuf pbuf_renderer;
			Gtk.TreeViewColumn column;
			Gdk.Pixbuf pbuf;

			pbuf_renderer = new Gtk.CellRendererPixbuf();

			column = new Gtk.TreeViewColumn.with_attributes (
				null, pbuf_renderer,
				"icon-name", PlaylistModel.Column.POSITION_INDICATOR,
				"sensitive", PlaylistModel.Column.AVAILABLE,
				null
			);

			/* Find out the width of the position idicator icon */
			pbuf = Abraca.Icons.by_name("go-next", Gtk.IconSize.MENU);

			/* Add some extra width otherwise it will not fit into the column */
			column.set_min_width((pbuf.width + 3) * 2);
			column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);

			append_column (column);

			text_renderer = new Gtk.CellRendererText();

			text_renderer.set_fixed_height_from_font(2);

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


		private void create_context_menu (Config config)
		{
			Gtk.MenuItem item;
			Gtk.Menu submenu;

			_playlist_menu = new Gtk.Menu();

			/* Jump */
			item = new Gtk.MenuItem.with_label(_("Jump"));
			item.activate.connect(jump_to_selected);
			_playlist_menu_item_when_one_selected.prepend(item);
			_playlist_menu.append(item);

			/* Separator */
			item = new Gtk.SeparatorMenuItem();
			_playlist_menu.append(item);

			/* Information */
			item = new Gtk.MenuItem.with_label(_("Info"));
			item.activate.connect(on_menu_playlist_info);
			_playlist_menu_item_when_some_selected.prepend(item);
			_playlist_menu.append(item);

			/* Filter submenu */
			submenu = new Gtk.Menu();

			item = new Gtk.MenuItem.with_label(_("By Artist"));
			item.activate.connect(i => {
				on_menu_playlist_filter("artist");
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("By Album"));
			item.activate.connect(i => {
				on_menu_playlist_filter("album");
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("By Genre"));
			item.activate.connect(i => {
				on_menu_playlist_filter("genre");
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Find"));
			item.set_submenu(submenu);
			_playlist_menu_item_when_some_selected.prepend(item);
			_playlist_menu.append(item);

			/* Delete */
			item = new Gtk.MenuItem.with_label(_("Delete"));
			item.activate.connect(delete_selected);
			_playlist_menu_item_when_some_selected.prepend(item);
			_playlist_menu.append(item);

			/* Separator */
			item = new Gtk.SeparatorMenuItem();
			_playlist_menu.append(item);

			/* Sorting submenu */
			submenu = new Gtk.Menu();
			item = new Gtk.MenuItem.with_label(_("Artist"));
			item.activate.connect(i => {
				on_menu_playlist_sort(config.sorting_artist);
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Album"));
			item.activate.connect(i => {
				this.on_menu_playlist_sort(config.sorting_album);
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Title"));
			item.activate.connect(i => {
				on_menu_playlist_sort(config.sorting_title);
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Year"));
			item.activate.connect(i => {
				on_menu_playlist_sort(config.sorting_year);
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Path"));
			item.activate.connect(i => {
				on_menu_playlist_sort(config.sorting_path);
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Custom"));
			item.activate.connect(i => {
				on_menu_playlist_sort(config.sorting_custom);
			});
			submenu.append(item);

			item = new Gtk.MenuItem.with_label(_("Sort"));
			item.set_submenu(submenu);
			_playlist_menu.append(item);

			/* Shuffle */
			item = new Gtk.MenuItem.with_label(_("Shuffle"));
			item.activate.connect(i => {
				client.xmms.playlist_shuffle(Xmms.ACTIVE_PLAYLIST);
			});
			_playlist_menu.append(item);

			/* Clear */
			item = new Gtk.MenuItem.with_label(_("Clear"));
			item.activate.connect(i => {
				client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
			});
			_playlist_menu.append(item);

			_playlist_menu.show_all();
		}


		private void on_menu_playlist_sort(string type)
		{
			_sort = new Xmms.Value.from_list();

			foreach (string s in type.split(",")) {
				_sort.list_append(new Xmms.Value.from_string(s));
			}

			client.xmms.playlist_sort(Xmms.ACTIVE_PLAYLIST, _sort);
		}


		private void on_menu_playlist_filter(string key)
		{
			int column;

			if (key == "artist") {
				column = PlaylistModel.Column.ARTIST;
			} else if (key == "album") {
				column = PlaylistModel.Column.ALBUM;
			} else if (key == "genre") {
				column = PlaylistModel.Column.GENRE;
			} else {
				GLib.return_if_reached();
			}

			var values = new Gee.HashSet<string>();

			foreach_selected_row<string>(column, (pos, text) => {
				if (text != "Unknown")
					values.add(text.casefold());
			});

			var query = new GLib.StringBuilder();

			foreach (var val in values) {
				if (query.len > 0) {
					query.append(" OR ");
				}
				query.append(key);
				query.append(":\"");
				query.append(val);
				query.append("\"");
			}

			if (query.len > 0) {
				search.search(query.str);
			}
		}


		private void on_menu_playlist_info(Gtk.MenuItem item)
		{
			foreach_selected_row<uint>(PlaylistModel.Column.ID, (pos, mid) => {
				medialib.info_dialog_add_id(mid);
			});
		}


		/**
		 * Setup dragndrop for the playlist.
		 */
		private void create_dragndrop()
		{
			enable_model_drag_dest(_target_entries,
			                       Gdk.DragAction.MOVE);

			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         _source_entries,
			                         Gdk.DragAction.MOVE);

			drag_data_received.connect(on_drag_data_receive);
			drag_data_get.connect(on_drag_data_get);
		}


		private void on_drag_data_get(Gtk.Widget w, Gdk.DragContext ctx,
		                              Gtk.SelectionData selection_data,
		                              uint info, uint time)
		{
			if (info == Abraca.TargetInfo.PLAYLIST_ENTRIES) {
				var value = new Xmms.Value.from_list();
				foreach_selected_row<int>(PlaylistModel.Column.ID, (pos, mid) => {
					value.list_insert_int(0, pos);
				});
				DragDropUtil.send_playlist_entries(selection_data, value);
			} else {
				var list = new Xmms.Collection(Xmms.CollectionType.IDLIST);
				foreach_selected_row<int>(PlaylistModel.Column.ID, (pos, mid) => {
					list.idlist_append(mid);
				});
				DragDropUtil.send_collection(selection_data, list);
			}
		}


		/**
		 * Take care of the various types of drops.
		 */
		private void on_drag_data_receive(Gtk.Widget w, Gdk.DragContext ctx, int x, int y,
		                                  Gtk.SelectionData sel, uint info, uint time)
		{
			bool success = false;

			if (info == Abraca.TargetInfo.PLAYLIST_ENTRIES) {
				success = on_drop_playlist_entries(sel, x, y);
			} else if (info == Abraca.TargetInfo.COLLECTION) {
				success = on_drop_collection(sel, x, y);
			} else if (info == Abraca.TargetInfo.URI) {
				success = on_drop_files(sel, x, y);
			} else if (info == Abraca.TargetInfo.INTERNET) {
				success = on_drop_files(sel, x, y, true);
			}

			/* success, but do not remove from source */
			Gtk.drag_finish(ctx, success, false, time);
		}

		private bool get_drop_destination(int x, int y, out int dest)
		{
			int dst;
			Gtk.TreeViewDropPosition align;
			Gtk.TreePath path;

			if (get_dest_row_at_pos(x, y, out path, out align)) {
				dst = path.get_indices()[0];

				if (align == Gtk.TreeViewDropPosition.AFTER
				    || align == Gtk.TreeViewDropPosition.INTO_OR_AFTER) {
					dst++;
				}

				dest = dst;
			} else {
				dest = model.iter_n_children (null);
			}
			return true;
		}

		/**
		 * Handle dropping of playlist entries.
		 */
		private bool on_drop_playlist_entries(Gtk.SelectionData sel, int x, int y)
		{
			int dest;

			var value = DragDropUtil.receive_playlist_entries(sel);

			if (get_drop_destination(x, y, out dest)) {
				int downward = 0;
				int upward = 0;

				for (int i = value.list_get_size() - 1; i >= 0; i--) {
					int position;
					value.list_get_int(i, out position);
					if (position < dest) {
						client.xmms.playlist_move_entry(Xmms.ACTIVE_PLAYLIST, position-downward, (uint) dest-1);
						downward++;
					} else {
						client.xmms.playlist_move_entry(Xmms.ACTIVE_PLAYLIST, position, (uint) dest+upward);
						upward++;
					}
				}
			}

			return false;
		}


		/**
		 * Handle dropping of medialib ids.
		 */
		private bool on_drop_collection(Gtk.SelectionData sel, int x, int y)
		{
			int pos;

			var coll = DragDropUtil.receive_collection(sel);

			if (get_drop_destination(x, y, out pos)) {
				client.xmms.playlist_insert_collection(Xmms.ACTIVE_PLAYLIST, pos, coll, _sort);
			} else {
				client.xmms.playlist_add_collection(Xmms.ACTIVE_PLAYLIST, coll, _sort);
			}

			return true;
		}


		/**
		 * Handle dropping of urls.
		 * TODO: Handle coding of urls from nautilus.
		 * TODO: Handle inserting of directories.
		 */
		private bool on_drop_files(Gtk.SelectionData sel, int x, int y,
		                           bool internet = false)
		{
			string[] uri_list;
			int pos;

			uri_list = ((string) sel.get_data()).split("\r\n");

			for (int i = 0; uri_list != null && uri_list[i] != null; i++) {
				if (internet && (i % 2 != 0)) {
					continue;
				}

				if (((string) uri_list[i]).length > 0) {
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
					} else if (get_drop_destination (x, y, out pos)) {
						client.xmms.playlist_insert_url(Xmms.ACTIVE_PLAYLIST, pos, uri);
					} else {
						client.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, uri);
					}
				}
			}

			return true;
		}


		/**
		 * Perform a jump to that song and start playback if not already
		 * playing.
		 */
		private void jump_to_pos(int pos)
		{
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


		private void jump_to_selected(Gtk.MenuItem tree)
		{
			jump_to_pos(get_selection().get_selected_rows(null).first().data
			            .get_indices()[0]);
		}


		/**
		 * When clicking a row, perform a jump to that song and start
		 * playback if not already playing.
		 */
		private void on_row_activated(Gtk.TreeView tree, Gtk.TreePath path,
		                              Gtk.TreeViewColumn column)
		{
			jump_to_pos(path.get_indices()[0]);
		}
	}
}
