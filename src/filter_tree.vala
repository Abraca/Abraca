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
	/* TODO: Remove and introduce dynamic colums */
	enum FilterColumn {
		Status,
		ID,
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

		/* sensitivity conditions of filter_menu-items */
		private GLib.List<Gtk.MenuItem>
			filter_menu_item_when_one_selected = null;
		private GLib.List<Gtk.MenuItem>
			filter_menu_item_when_some_selected = null;
		private GLib.List<Gtk.MenuItem>
			filter_menu_item_when_none_selected = null;

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


		construct {
			fixed_height_mode = true;
			enable_search = false;

			create_columns ();

			get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);

			model = new FilterModel();

			create_context_menu();
			get_selection().changed += on_selection_changed_update_menu;
			on_selection_changed_update_menu(get_selection());

			create_drag_n_drop();

			button_press_event += on_button_press_event;
			row_activated += on_row_activated;
		}

		private void on_selection_changed_update_menu(Gtk.TreeSelection s) {
			int n = s.count_selected_rows();

			foreach (weak Gtk.MenuItem i
			         in filter_menu_item_when_none_selected) {
				i.sensitive = (n == 0);
			}

			foreach (weak Gtk.MenuItem i
			         in filter_menu_item_when_one_selected) {
				i.sensitive = (n == 1);
			}

			foreach (weak Gtk.MenuItem i
			         in filter_menu_item_when_some_selected) {
				i.sensitive = (n > 0);
			}
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
			FilterModel store = (FilterModel) model;

			/* disconnect our model while the shit hits the fan */
			set_model(null);

			store.replace_content (res);

			/* reconnect the model again */
			set_model(store);
		}

		[InstanceLast]
		private bool on_button_press_event(FilterTree w, Gdk.Event e) {
			Gtk.TreePath path;
			int x, y;

			/* we're only interested in the 3rd mouse button */
			if (e.button.button != 3)
				return false;

			filter_menu.popup(
				null, null, null, e.button.button,
				Gtk.get_current_event_time()
			);

			x = (int) e.button.x;
			y = (int) e.button.y;

			/* Prevent selection-handling when right-clicking on an already
			   selected entry */
			if (get_path_at_pos(x, y, out path, null, null, null)) {
				weak Gtk.TreeSelection sel = get_selection();
				if (sel.path_is_selected(path)) {
					return true;
				}
			}

			return false;
		}

		private void on_row_activated(FilterTree tree, Gtk.TreePath path, Gtk.TreeViewColumn column) {
			Client c = Client.instance();
			Gtk.TreeIter iter;
			uint id;

			model.get_iter(out iter, path);
			model.get(iter, FilterColumn.ID, out id);
			c.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
		}

		private void on_menu_info(Gtk.MenuItem item) {
			Client c = Client.instance();
			GLib.List<Gtk.TreePath> list;
			weak Gtk.TreeModel mod;
			Gtk.TreeIter iter;
			uint id;

			list = get_selection().get_selected_rows(out mod);
			foreach (weak Gtk.TreePath path in list) {
				model.get_iter(out iter, path);
				model.get(iter, FilterColumn.ID, out id);

				Abraca.instance().medialib.info_dialog_add_id(id);
			}
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

		/* TODO: Remove and introduce dynamic colums */
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

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_INFO, null);
			item.activate += on_menu_info;
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ADD, null);
			item.activate += on_menu_add;
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.MenuItem.with_mnemonic(_("_Replace"));
			item.activate += on_menu_replace;
			filter_menu_item_when_some_selected.prepend(item);
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
		private void on_drag_data_get(FilterTree w, Gdk.DragContext ctx,
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
				model.get(iter, FilterModel.Column.ID, out mid, -1);

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
		}
	}
}
