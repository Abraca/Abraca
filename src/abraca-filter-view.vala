/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2013 Abraca Team
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
	public class FilterView : Abraca.TreeView, IConfigurable, SelectedRowsMixin {
		/* field and order used for sorting, see sorting property */
		public struct Sorting {
			public unowned string field;
			public Gtk.SortType order;
		}

		private Medialib medialib;
		private Client client;

		/** context menu */
		private Gtk.Menu filter_menu;
		private Gtk.Menu header_menu;

		/* sensitivity conditions of filter_menu-items */
		private GLib.List<Gtk.MenuItem>
			filter_menu_item_when_one_selected = null;
		private GLib.List<Gtk.MenuItem>
			filter_menu_item_when_some_selected = null;
		private GLib.List<Gtk.MenuItem>
			filter_menu_item_when_none_selected = null;

		/** allowed drag-n-drop variants */
		private Gtk.TargetEntry[] _target_entries = {
			Abraca.TargetEntry.Collection
		};

		/* properties */
		public Sorting sorting { get; set; }
		public Xmms.Collection collection { get; private set; }


		public FilterView (Client c, Medialib m)
		{
			medialib = m;
			client = c;

			//fixed_height_mode = true;
			enable_search = false;
			headers_clickable = true;

			get_selection().set_mode(Gtk.SelectionMode.MULTIPLE);

			create_header_menu();
			create_context_menu();
			get_selection().changed.connect(on_selection_changed_update_menu);
			on_selection_changed_update_menu(get_selection());

			create_drag_n_drop();

			button_press_event.connect(on_button_press_event);
			row_activated.connect(on_row_activated);
			key_press_event.connect(on_key_press_event);
			columns_changed.connect(on_columns_changed);

			notify["sorting"].connect(on_sorting_changed);

			Configurable.register(this);
		}


		public void get_configuration (GLib.KeyFile file)
		{
			FilterModel store = (FilterModel) model;
			file.set_string_list("filter", "columns", store.dynamic_columns);
		}


		public void set_configuration (GLib.KeyFile file)
			throws GLib.KeyFileError
		{
			string[] list;

			if (file.has_group("filter") && file.has_key("filter", "columns")) {
				list = file.get_string_list("filter", "columns");
			} else {
				list = new string[] {"artist", "title", "album"};
			}

			set_dynamic_columns(list);
		}


		private void on_sorting_changed (GLib.Object source, GLib.ParamSpec pspec)
		{
			if (collection != null) {
				query_collection(collection);
			} else {
				update_sort_indicators();
			}
		}


		private void on_selection_changed_update_menu (Gtk.TreeSelection s)
		{
			int n = s.count_selected_rows();

			foreach (var i in filter_menu_item_when_none_selected) {
				i.sensitive = (n == 0);
			}

			foreach (var i in filter_menu_item_when_one_selected) {
				i.sensitive = (n == 1);
			}

			foreach (var i in filter_menu_item_when_some_selected) {
				i.sensitive = (n > 0);
			}
		}


		public void query_collection (Xmms.Collection coll, Xmms.NotifierFunc? callback=null)
		{
			Xmms.Value order = new Xmms.Value.from_list();
			Xmms.Result res;

			if (sorting.field == null) {
				order.list_append(new Xmms.Value.from_string("artist"));
				order.list_append(new Xmms.Value.from_string("album"));
				order.list_append(new Xmms.Value.from_string("partofset"));
				order.list_append(new Xmms.Value.from_string("tracknr"));
			} else if (sorting.order == Gtk.SortType.ASCENDING) {
				order.list_append(new Xmms.Value.from_string("-" + sorting.field));
			} else {
				order.list_append(new Xmms.Value.from_string(sorting.field));
			}

			res = client.xmms.coll_query_ids(coll, order);
			res.notifier_set(on_coll_query_ids);
			if (callback != null) {
				res.notifier_set(callback);
			}

			collection = coll;
		}


		public void playlist_replace_with_filter_results ()
		{
			Gtk.TreeIter iter;
			uint id;

			if (!model.iter_children(out iter, null)) {
				return;
			}

			client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);

			do {
				model.get(iter, FilterModel.Column.ID, out id);
				client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
			} while (model.iter_next(ref iter));
		}


		public void playlist_add_filter_results ()
		{
			Gtk.TreeIter iter;
			uint id;

			if (!model.iter_children(out iter, null)) {
				return;
			}

			do {
				model.get(iter, FilterModel.Column.ID, out id);
				client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
			} while (model.iter_next(ref iter));
		}


		private bool on_coll_query_ids (Xmms.Value val)
		{
			FilterModel store = (FilterModel) model;

			/* disconnect our model while the shit hits the fan */
			set_model(null);

			store.replace_content (val);

			/* reconnect the model again */
			set_model(store);

			/* set the sort indicator for the sorted column */
			update_sort_indicators();

			return true;
		}


		private bool on_button_press_event (Gtk.Widget w, Gdk.EventButton button)
		{
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
				var sel = get_selection();
				if (sel.path_is_selected(path)) {
					return true;
				}
			}

			return false;
		}


		private bool on_key_press_event (Gdk.EventKey e)
		{
			if (e.keyval != Gdk.keyval_from_name("Return")) {
				return false;
			}

			if ((e.state & Gdk.ModifierType.CONTROL_MASK) > 0) {
				client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
			}

			foreach_selected_row<int>(FilterModel.Column.ID, (pos, mid) => {
				client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, mid);
			});

			return true;
		}


		private void on_columns_changed ()
		{
			if (model != null) {
				var columns = get_columns();
				var modified = new string[columns.length()];
				int i = 0;

				foreach (var column in columns) {
					modified[i++] = column.title;
				}

				set_dynamic_columns(modified);
			}
		}


		private void on_row_activated (Gtk.TreeView tree, Gtk.TreePath path,
		                               Gtk.TreeViewColumn column)
		{
			Gtk.TreeIter iter;
			uint id;

			model.get_iter(out iter, path);
			model.get(iter, FilterModel.Column.ID, out id);
			client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, id);
		}


		private void on_menu_select_all (Gtk.MenuItem item)
		{
			get_selection().select_all();
		}


		private void on_menu_info (Gtk.MenuItem item)
		{
			foreach_selected_row<uint>(FilterModel.Column.ID, (idx, mid) => {
				medialib.info_dialog_add_id(mid);
			});
		}


		private void on_menu_add (Gtk.MenuItem item)
		{
			foreach_selected_row<int>(FilterModel.Column.ID, (pos, mid) => {
				client.xmms.playlist_add_id (Xmms.ACTIVE_PLAYLIST, mid);
			});
		}


		private void on_menu_replace (Gtk.MenuItem item)
		{
			foreach_selected_row<int>(FilterModel.Column.ID, (pos, mid) => {
				client.xmms.playlist_add_id (Xmms.ACTIVE_PLAYLIST, mid);
			});
		}


		private void set_dynamic_columns (string[] props)
		{
			model = null;

			foreach (var column in get_columns()) {
				remove_column(column);
			}

			var cell = new Gtk.CellRendererText();
			cell.ellipsize = Pango.EllipsizeMode.END;

			int pos = 2;
			foreach (var key in props) {
				var column = new Gtk.TreeViewColumn.with_attributes(
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

				Gtk.Widget ancestor = column.widget.get_ancestor(typeof(Gtk.Button));

				GLib.assert(ancestor != null);

				ancestor.button_press_event.connect(on_header_clicked);
			}

			model = new FilterModel(client, props);

			if (collection != null) {
				query_collection(collection);
			} else {
				update_sort_indicators();
			}
		}


		private bool on_header_clicked (Gtk.Widget w, Gdk.EventButton e)
		{
			switch (e.button) {
				case 1:
					foreach (var column in get_columns()) {
						if (column.widget.get_ancestor(typeof(Gtk.Button)) == w) {
							Gtk.SortType order;
							if (sorting.field == column.title && sorting.order == Gtk.SortType.DESCENDING) {
								order = Gtk.SortType.ASCENDING;
							} else {
								order = Gtk.SortType.DESCENDING;
							}
							/* TODO: This temp variable is needed due to a bug in vala 0.11.5 */
							Sorting tmp = {column.title, order};
							sorting = tmp;
							break;
						}
					}
					return true;
				case 3:
					foreach (var column in get_columns()) {
						if (column.widget.get_ancestor(typeof(Gtk.Button)) == w) {
							header_menu.set_title(column.title);
							break;
						}
					}

					header_menu.popup(null, null, null, e.button, Gtk.get_current_event_time());
					header_menu.show_all();
					return true;
				default:
					return false;
			}
		}


		private void on_header_edit (Gtk.MenuItem item)
		{
			var store = (FilterModel) model;
			var edit = new FilterEditor();

			edit.transient_for = get_ancestor (typeof(Gtk.Window)) as Gtk.Window;

			edit.column_changed.connect((editor, prop, enabled) => {
				string[] modified;
				int i = 0;

				if (enabled) {
					modified = new string[store.dynamic_columns.length + 1];
				} else {
					modified = new string[store.dynamic_columns.length - 1];
				}

				foreach (unowned string s in store.dynamic_columns) {
					if (!enabled && s == prop) {
						continue;
					}
					modified[i++] = s;
				}

				if (enabled) {
					modified[i] = prop;
				}

				set_dynamic_columns(modified);
			});

			edit.set_active(store.dynamic_columns);
			edit.run();
		}


		private void on_header_remove (Gtk.MenuItem item)
		{
			var title = ((Gtk.Menu) item.parent).get_title();
			foreach (var column in get_columns()) {
				if (column.title == title) {
					remove_column(column);
					break;
				}
			}
		}


		private void on_header_reset_sorting (Gtk.MenuItem item)
		{
			sorting = Sorting();
		}

		private void create_header_menu ()
		{
			Gtk.MenuItem item;

			header_menu = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.EDIT, null);
			item.activate.connect(on_header_edit);
			header_menu.append(item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.REMOVE, null);
			item.activate.connect(on_header_remove);
			header_menu.append(item);

			header_menu.append(new Gtk.SeparatorMenuItem());

			item = new Gtk.MenuItem.with_label(_("Reset sorting"));
			item.activate.connect(on_header_reset_sorting);
			header_menu.append(item);
		}

		private void create_context_menu ()
		{
			Gtk.MenuItem item;

			filter_menu = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.SELECT_ALL, null);
			item.activate.connect(on_menu_select_all);
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.SeparatorMenuItem();
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.INFO, null);
			item.activate.connect(on_menu_info);
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.SeparatorMenuItem();
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.ADD, null);
			item.activate.connect(on_menu_add);
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			item = new Gtk.MenuItem.with_mnemonic(_("_Replace"));
			item.activate.connect(on_menu_replace);
			filter_menu_item_when_some_selected.prepend(item);
			filter_menu.append(item);

			filter_menu.show_all();
		}


		private void create_drag_n_drop ()
		{
			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         _target_entries,
			                         Gdk.DragAction.MOVE);

			drag_data_get.connect(on_drag_data_get);
		}


		private void update_sort_indicators ()
		{
			foreach (var column in get_columns()) {
				if (column.title == sorting.field) {
					column.sort_order = sorting.order;
					column.sort_indicator = true;
				} else {
					column.sort_indicator = false;
				}
			}
		}


		private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext ctx,
		                               Gtk.SelectionData selection_data,
		                               uint info, uint time)
		{
			var list = new Xmms.Collection(Xmms.CollectionType.IDLIST);
			foreach_selected_row<int>(FilterModel.Column.ID, (pos, mid) => {
				list.idlist_append(mid);
			});

			DragDropUtil.send_collection(selection_data, list);
		}
	}
}
