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

		private const string[]? _sort_order = {
			"artist", "album", "tracknr"
		};

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
			c.medialib_entry_changed += (client, res) => {
				on_media_info(res);
			};

			button_press_event += on_button_press_event;
			row_activated += on_row_activated;
		}

		public void query_collection(Xmms.Collection coll) {
			Client c = Client.instance();

			c.xmms.coll_query_ids(coll, _sort_order, 0, 0).notifier_set(
				on_coll_query_ids
			);
		}

		public void playlist_replace_with_filter_results() {
			Client c = Client.instance();
			Gtk.TreeIter iter;
			uint id;

			if (!model.iter_children(out iter, null)) {
				return;
			}

			c.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);

			do {
				model.get(iter, FilterColumn.ID, out id);
				c.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
			} while (model.iter_next(ref iter));
		}

		public void playlist_add_filter_results() {
			Client c = Client.instance();
			Gtk.TreeIter iter;
			uint id;

			if (!model.iter_children(out iter, null)) {
				return;
			}

			do {
				model.get(iter, FilterColumn.ID, out id);
				c.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
			} while (model.iter_next(ref iter));
		}

		[InstanceLast]
		private void on_coll_query_ids(Xmms.Result #res) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Client c = Client.instance();
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

			foreach (uint mid in pos_map.get_keys()) {
				c.xmms.medialib_get_info(mid).notifier_set(on_media_info);
			}
		}

		private void on_media_info(Xmms.Result #res) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			weak string artist, album, title;
			weak Gtk.TreeRowReference row;
			weak Gtk.TreePath path;
			Gtk.TreeIter iter;
			int mid, pos, id;
			string info;


			res.get_dict_entry_int("id", out mid);

			row = (Gtk.TreeRowReference) pos_map.lookup(mid.to_pointer());
			if (row == null || !row.valid()) {
				return;
			}

			if (!res.get_dict_entry_string("artist", out artist)) {
				artist = _("Unknown");
			}
			if (!res.get_dict_entry_string("album", out album)) {
				album = _("Unknown");
			}
			if (!res.get_dict_entry_string("title", out title)) {
				title = _("Unknown");
			}

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
				null, null, null, event_button.button,
				Gtk.get_current_event_time()
			);

			return true;
		}

		private void on_row_activated(Gtk.TreeView tree, Gtk.TreePath path, Gtk.TreeViewColumn column) {
			Client c = Client.instance();
			Gtk.TreeIter iter;
			uint id;

			model.get_iter(out iter, path);
			model.get(iter, FilterColumn.ID, out id);
			c.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
		}

		private void on_menu_add(Gtk.MenuItem item) {
			Client c = Client.instance();
			GLib.List<Gtk.TreePath> list;
			weak Gtk.TreeModel mod;
			Gtk.TreeIter iter;
			uint id;

			list = get_selection().get_selected_rows(out mod);
			foreach (weak Gtk.TreePath path in list) {
				model.get_iter(out iter, path);
				model.get(iter, FilterColumn.ID, out id);

				c.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
			}
		}

		private void on_menu_replace(Gtk.MenuItem item) {
			Client c = Client.instance();
			GLib.List<Gtk.TreePath> list;
			weak Gtk.TreeModel mod;
			Gtk.TreeIter iter;
			uint id;

			c.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);

			list = get_selection().get_selected_rows(out mod);
			foreach (weak Gtk.TreePath path in list) {
				model.get_iter(out iter, path);
				model.get(iter, FilterColumn.ID, out id);

				c.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
			}

		}

		private void create_columns() {
			Gtk.TreeViewColumn column;
			Gtk.CellRendererText cell;

			cell = new Gtk.CellRendererText();
			cell.ellipsize = Pango.EllipsizeMode.END;

			column = new Gtk.TreeViewColumn.with_attributes(
				_("Artist"), cell, "text", FilterColumn.Artist, null
			);
			column.resizable = true;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			column.min_width = 120;
			insert_column(column, -1);

			column = new Gtk.TreeViewColumn.with_attributes(
				_("Title"), cell, "text", FilterColumn.Title, null
			);
			column.resizable = true;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			column.min_width = 150;
			insert_column(column, -1);

			column = new Gtk.TreeViewColumn.with_attributes(
				_("Album"), cell, "text", FilterColumn.Album, null
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
			Gtk.MenuItem item;
			Gtk.ImageMenuItem img_item;

			filter_menu = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ADD, null);
			item.activate += on_menu_add;
			filter_menu.append(item);

			item = new Gtk.MenuItem.with_mnemonic(_("_Replace"));
			item.activate += on_menu_replace;
			filter_menu.append(item);

			filter_menu.show_all();
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
			GLib.List<Gtk.TreePath> lst = sel.get_selected_rows(null);
			GLib.List<uint> mid_list = new GLib.List<uint>();

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

			/* This should be removed as #515408 gets fixed. */
			weak uchar[] data = (uchar[]) mid_array;
			data.length = (int)(mid_array.length * sizeof(uint));

			selection_data.set(
				Gdk.Atom.intern(_target_entries[0].target, true),
				8, data
			);

			return true;
		}
	}
}
