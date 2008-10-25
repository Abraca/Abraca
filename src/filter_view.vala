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

	public class FilterView : Gtk.TreeView, IConfigurable {
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

		construct {
			fixed_height_mode = true;
			enable_search = false;
			headers_clickable = true;

			get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);


			create_context_menu();
			get_selection().changed += on_selection_changed_update_menu;
			on_selection_changed_update_menu(get_selection());

			create_drag_n_drop();

			button_press_event += on_button_press_event;
			row_activated += on_row_activated;

			Configurable.register(this);
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			string[] list;

			if (file.has_key("filter", "columns")) {
				list = file.get_string_list("filter", "columns");
			} else {
				list = new string[] {"artist", "title", "album"};
			}

			model = FilterModel.create(#list);

			create_columns ();
		}

		public void get_configuration(GLib.KeyFile file) {
			FilterModel store = (FilterModel) model;
			file.set_string_list("filter", "columns", store.dynamic_columns);
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


		private void on_coll_query_ids(Xmms.Result #res) {
			FilterModel store = (FilterModel) model;

			/* disconnect our model while the shit hits the fan */
			set_model(null);

			store.replace_content (res);

			/* reconnect the model again */
			set_model(store);
		}


		private bool on_button_press_event(FilterView w, Gdk.EventButton button) {
			Gtk.TreePath path;
			int x, y;

			/* we're only interested in the 3rd mouse button */
			if (button.button != 3)
				return false;

			filter_menu.popup(
				null, null, null, button.button,
				Gtk.get_current_event_time()
			);

			x = (int) button.x;
			y = (int) button.y;

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


		private void on_row_activated(FilterView tree, Gtk.TreePath path, Gtk.TreeViewColumn column) {
			Client c = Client.instance();
			Gtk.TreeIter iter;
			uint id;

			model.get_iter(out iter, path);
			model.get(iter, FilterColumn.ID, out id);
			c.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
		}

		private void on_menu_select_all(Gtk.MenuItem item) {
			get_selection().select_all();
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


		private void create_columns() {
			FilterModel store = (FilterModel) model;
			Gtk.TreeViewColumn column;
			Gtk.CellRendererText cell;

			cell = new Gtk.CellRendererText();
			cell.ellipsize = Pango.EllipsizeMode.END;

			int pos = 2;
			foreach (weak string key in store.dynamic_columns) {
				column = new Gtk.TreeViewColumn.with_attributes(
					key, cell, "text", pos++, null
				);
				column.resizable = true;
				column.reorderable = true;
				column.fixed_width = 120;
				column.sizing = Gtk.TreeViewColumnSizing.FIXED;
				column.clickable = true;
				column.widget = new Gtk.Label(key);
				column.widget.show();

				insert_column(column, -1);

				/* Travel up until we find a button.. */
				Gtk.Widget w = column.widget.parent;
				while (!(w == null || w is Gtk.Button)) {
					w = w.parent;
				}

				/* To be on the safe side... but should be the button. */
				if (w != null) {
					w.button_press_event += on_header_clicked;
				}
			}
		}


		private bool on_header_clicked (Gtk.Widget w, Gdk.EventButton e)
		{
			Gtk.MenuItem item;
			Gtk.Menu menu;

			if (e.button != 3) {
				return false;
			}

			menu = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ADD, null);
			item.activate += on_header_add;
			menu.append(item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_REMOVE, null);
			item.activate += on_header_remove;
			menu.append(item);

			menu.popup(null, null, null, e.button, Gtk.get_current_event_time());

			menu.show_all();

			return true;
		}

		private void on_header_add (Gtk.Widget w) {
			GLib.stdout.printf("on_header_add\n");
		}

		private void on_header_remove (Gtk.Widget w) {
			GLib.stdout.printf("on_header_remove\n");
		}

		private void create_context_menu() {
			Gtk.MenuItem item;
			Gtk.ImageMenuItem img_item;

			filter_menu = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_SELECT_ALL, null);
			item.activate += on_menu_select_all;
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.SeparatorMenuItem();
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_INFO, null);
			item.activate += on_menu_info;
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.SeparatorMenuItem();
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


		private void on_drag_data_get(FilterView w, Gdk.DragContext ctx,
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
