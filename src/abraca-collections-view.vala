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

	public class CollectionsView : Gtk.TreeView {

		/** drag-n-drop targets */
		private Gtk.TargetEntry[] target_entries = {
			Abraca.TargetEntry.Collection
		};

		/** drag-n-drop sources */
		private Gtk.TargetEntry[] source_entries = {
			Abraca.TargetEntry.Collection
		};

		/** context menu */
		private Gtk.Menu collection_menu;

		/* sensitivity conditions of collection_menu-items */
		private GLib.List<Gtk.MenuItem> collection_menu_item_when_coll_selected = null;
		private GLib.List<Gtk.MenuItem> collection_menu_item_when_ns_selected = null;

		/** to keep track of our last drop target */
		private Gtk.TreePath drop_path = null;

		private Client client;
		private Searchable search;

		public CollectionsView (Client c, Searchable s)
		{
			CollectionsModel store;

			client = c;
			search = s;

			search_column = 0;
			enable_search = true;
			headers_visible = false;
			fixed_height_mode = true;

			model = store = new CollectionsModel(Abraca.Icons.by_name("abraca-collection", Gtk.IconSize.LARGE_TOOLBAR),
			                                     Abraca.Icons.by_name("abraca-playlist", Gtk.IconSize.LARGE_TOOLBAR),
			                                     client);

			store.collection_loaded.connect((type) => {
				expand_all();
			});

			create_columns();

			row_activated.connect(on_row_activated);

			enable_model_drag_dest(target_entries, Gdk.DragAction.COPY);

			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         source_entries, Gdk.DragAction.MOVE);

			create_context_menu();
			get_selection().changed.connect(on_selection_changed_update_menu);
			on_selection_changed_update_menu(get_selection());

			drag_leave.connect(on_drag_leave);
			drag_motion.connect(on_drag_motion);
			drag_data_get.connect(on_drag_data_get);
			drag_data_received.connect(on_drag_data_received);

			key_press_event.connect(on_key_press_event);
			button_press_event.connect(on_button_press_event);
		}


		private void on_selection_changed_update_menu (Gtk.TreeSelection s)
		{
			int n;
			Gtk.TreeIter iter;

			if (!s.get_selected(null, out iter)) {
				n = 0;
			} else {
				n = model.get_path(iter).get_depth();
			}

			foreach (var i in collection_menu_item_when_coll_selected) {
				i.sensitive = (n == 2);
			}

			foreach (var i in collection_menu_item_when_ns_selected) {
				i.sensitive = (n == 1);
			}
		}


		private void on_drag_data_get (Gtk.Widget w, Gdk.DragContext ctx,
		                               Gtk.SelectionData selection_data,
		                               uint info, uint time)
		{
			unowned string coll_name, coll_ns;
			Gtk.TreeIter iter;
			int type;

			var sel = get_selection();
			var lst = sel.get_selected_rows(null);

			model.get_iter(out iter, lst.data);

			model.get(
				iter,
				CollectionsModel.Column.Name, out coll_name,
				CollectionsModel.Column.Type, out type
			);

			if (type == CollectionsModel.CollectionType.Playlist) {
				coll_ns = Xmms.COLLECTION_NS_PLAYLISTS;
			} else {
				coll_ns = Xmms.COLLECTION_NS_COLLECTIONS;
			}

			var reference = new Xmms.Collection(Xmms.CollectionType.REFERENCE);
			reference.attribute_set("reference", coll_name);
			reference.attribute_set("namespace", coll_ns);

			DragDropUtil.send_collection(selection_data, reference);
		}

		private bool on_button_press_event (Gtk.Widget w, Gdk.EventButton button)
		{
			Gtk.TreePath path;
			int x, y;

			/* we're only interested in the 3rd mouse button */
			if (button.button != 3) {
				return false;
			}

			collection_menu.popup(null, null, null, button.button, Gtk.get_current_event_time());

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


		private bool on_key_press_event (Gtk.Widget w, Gdk.EventKey e)
		{
			if (e.keyval == Gdk.keyval_from_name("F2")) {
				selected_collection_rename();
				return true;
			}

			if (e.keyval == Gdk.keyval_from_name("Delete")) {
				selected_collection_delete();
				return true;
			}

			return false;
		}


		/**
		 * Handle user input rename of collections.
		 */
		private void on_cell_edited (Gtk.CellRendererText renderer,
		                             string path, string new_text)
		{
			Gtk.TreeIter iter;
			int type;
			string name, ns;

			model.get_iter_from_string(out iter, path);

			model.get(
				iter,
				CollectionsModel.Column.Name, out name,
				CollectionsModel.Column.Type, out type
			);

			if (type == CollectionsModel.CollectionType.Playlist) {
				ns = Xmms.COLLECTION_NS_PLAYLISTS;
			} else {
				ns = Xmms.COLLECTION_NS_COLLECTIONS;
			}

			client.xmms.coll_rename(name, new_text, ns);
		}



		/**
		 * When dragging something over the collection tree widget, show a
		 * temporary new playlist, and update the drop paths.
		 */
		private bool on_drag_motion (Gtk.Widget w, Gdk.DragContext ctx,
		                             int x, int y, uint time)
		{
			CollectionsModel store = (CollectionsModel) model;
			Gtk.TreeViewDropPosition pos;
			Gtk.TreePath path;

			bool update = false;

			Gdk.drag_status(ctx, Gdk.DragAction.COPY, time);
			set_drag_dest_row(null, Gtk.TreeViewDropPosition.INTO_OR_AFTER);

			if (get_dest_row_at_pos(x, y, out path, out pos)) {
				CollectionsModel.CollectionType type =
					CollectionsModel.CollectionType.Playlist;

				if (store.path_is_type(path, type)) {
					update = !store.has_temporary_playlist;
					if (store.path_is_child_of_type(path, type)) {
						set_drag_dest_row(
							path, Gtk.TreeViewDropPosition.INTO_OR_AFTER
						);
					}
				} else if (store.has_temporary_playlist) {
					store.remove_temporary_playlist();
				}
			} else {
				/* TODO: This seems unsane? */
				update = !store.has_temporary_playlist;
			}

			if (update) {
				store.append_temporary_playlist();
			}

			return true;
		}


		/**
		 * Save the drop path and remove the temporary playlist if it wasn't
		 * the target of the drop operation.
		 */
		private void on_drag_leave (Gtk.Widget widget,
		                            Gdk.DragContext ctx,
		                            uint time)
		{
			CollectionsModel store = (CollectionsModel) model;
			Gtk.TreeViewDropPosition pos;

			/* save to handle */
			get_drag_dest_row(out drop_path, out pos);

			if (store.has_temporary_playlist) {
				store.remove_temporary_playlist();
			}
		}


		/**
		 *
		 */
		private void on_drag_data_received (Gtk.Widget w,
		                                    Gdk.DragContext ctx,
		                                    int x_pos, int y_pos,
		                                    Gtk.SelectionData data,
		                                    uint info, uint time)
		{
			CollectionsModel store = (CollectionsModel) model;

			if (drop_path != null) {
				CollectionsModel.CollectionType type;
				string name = "Unknown";
				Gtk.TreeIter iter;

				store.get_iter(out iter, drop_path);

				if (!store.get_iter(out iter, drop_path)) {
					name = store.realize_temporary_playlist();
				} else {
					type = CollectionsModel.CollectionType.Playlist;
					if (store.path_is_child_of_type(drop_path, type)) {
						store.get(iter, CollectionsModel.Column.Name, out name);
					}
				}

				playlist_insert_drop_data(info, name, data);

				drop_path = null;
			}

			if (store.has_temporary_playlist) {
				store.remove_temporary_playlist();
			}

			Gtk.drag_finish(ctx, true, false, time);
		}


		private void playlist_insert_drop_data (uint info, string name,
		                                        Gtk.SelectionData sel)
		{
			var coll = DragDropUtil.receive_collection(sel);

			var sort = new Xmms.Value.from_list();
			sort.list_append (new Xmms.Value.from_string("album"));
			sort.list_append (new Xmms.Value.from_string("tracknr"));

			client.xmms.playlist_add_collection(name, coll, sort);
		}


		private void on_row_activated (Gtk.TreeView tree,
		                               Gtk.TreePath path,
		                               Gtk.TreeViewColumn column)
		{
			CollectionsModel store = (CollectionsModel) model;
			CollectionsModel.CollectionType type;
			Gtk.TreeIter iter;
			string name;

			store.get_iter(out iter, path);
			store.get(iter, CollectionsModel.Column.Name, out name);

			type = CollectionsModel.CollectionType.Collection;
			if (store.path_is_child_of_type(path, type)) {
				if (Client.collection_needs_quoting(name))
					name = "\"" + name + "\"";
				search.search("in:" + name);
			} else {
				client.xmms.playlist_load(name);
			}
		}



		private void on_menu_collection_get(Gtk.MenuItem item) {
			Gtk.TreeIter iter;

			var selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				CollectionsModel store = (CollectionsModel) model;
				Gtk.TreePath path = store.get_path(iter);

				if (path.get_depth() == 2) {
					unowned string ns;
					string name;

					store.get(iter, CollectionsModel.Column.Name, out name);

					var type = CollectionsModel.CollectionType.Collection;
					if (store.path_is_child_of_type(path, type))
						ns = Xmms.COLLECTION_NS_COLLECTIONS;
					else
						ns = Xmms.COLLECTION_NS_PLAYLISTS;

					var full_name = ns + "/" + name;
					if (Client.collection_needs_quoting(full_name))
						full_name = "\"" + full_name + "\"";

					search.search ("in:" + full_name);
				}
			}
		}


		private void selected_collection_rename ()
		{
			Gtk.TreeIter iter;

			var selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				Gtk.TreePath path = model.get_path(iter);

				if (path.get_depth() == 2) {
					var cols = get_columns();
					var col = cols.data;

					var renderers = col.get_cells();
					var renderer = (Gtk.CellRendererText) renderers.data;

					renderer.editable = true;
					set_cursor_on_cell(path, col, renderer, true);
					renderer.editable = false;
				}
			}
		}


		private void selected_collection_delete ()
		{
			Gtk.TreeIter iter;

			var selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				CollectionsModel store = (CollectionsModel) model;
				Gtk.TreePath path = store.get_path(iter);

				if (path.get_depth() == 2) {
					CollectionsModel.CollectionType type;
					var ns = Xmms.COLLECTION_NS_PLAYLISTS;
					string name;

					store.get(iter, CollectionsModel.Column.Name, out name);

					type = CollectionsModel.CollectionType.Collection;
					if (store.path_is_child_of_type(path, type)) {
						ns = Xmms.COLLECTION_NS_COLLECTIONS;
					}

					client.xmms.coll_remove(name, ns);
				}
			}
		}


		/**
		 * Create the treeview columns.
		 */
		private void create_columns ()
		{
			Gtk.TreeViewColumn column;
			CellRendererCollection renderer;

			renderer = new CellRendererCollection();
			renderer.height = ((CollectionsModel) model).collection_pixbuf.height;
			renderer.edited.connect(on_cell_edited);

			column = new Gtk.TreeViewColumn.with_attributes (
				null, renderer,
				"pixbuf", CollectionsModel.Column.Icon,
				"style", CollectionsModel.Column.Style,
				"weight", CollectionsModel.Column.Weight,
				"text", CollectionsModel.Column.Name, null
			);
			column.set_sizing(Gtk.TreeViewColumnSizing.FIXED);

			append_column (column);
		}


		/**
		 * Create the context menu items.
		 */
		private void create_context_menu ()
		{
			Gtk.MenuItem item;

			collection_menu = new Gtk.Menu();

			item = new Gtk.MenuItem.with_mnemonic(_("_Show"));
			item.activate.connect(on_menu_collection_get);
			collection_menu_item_when_coll_selected.prepend(item);
			collection_menu.append(item);

			item = new Gtk.MenuItem.with_mnemonic(_("_Rename"));
			item.activate.connect((menu) => {
				selected_collection_rename();
			});
			collection_menu_item_when_coll_selected.prepend(item);
			collection_menu.append(item);

			item = new Gtk.MenuItem.with_mnemonic(_("Delete"));
			item.activate.connect((menu) => {
				selected_collection_delete();
			});
			collection_menu_item_when_coll_selected.prepend(item);
			collection_menu.append(item);

			collection_menu.show_all();
		}
	}
}
