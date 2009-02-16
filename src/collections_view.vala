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

	public class CollectionsView : Gtk.TreeView {

		/** drag-n-drop targets */
		private const Gtk.TargetEntry[] _target_entries = {
			//DragDropTarget.TrackId,
			{"application/x-xmmsclient-track-id", 0, DragDropTargetType.MID},
			//DragDropTarget.Collection
			{"application/x-xmmsclient-collection", 0, DragDropTargetType.COLL}
		};

		/** drag-n-drop sources */
		private const Gtk.TargetEntry[] _source_entries = {
			//DragDropTarget.Collection
			{"application/x-xmmsclient-collection", 0, DragDropTargetType.COLL}
		};

		/** context menu */
		private Gtk.Menu _collection_menu;

		/* sensitivity conditions of _collection_menu-items */
		private GLib.List<Gtk.MenuItem>
			_collection_menu_item_when_coll_selected = null;
		private GLib.List<Gtk.MenuItem>
			_collection_menu_item_when_ns_selected = null;

		/** to keep track of our last drop target */
		private Gtk.TreePath _drop_path = null;

		construct {
			Client c = Client.instance();
			Gdk.Pixbuf coll, pls;

			search_column = 0;
			enable_search = true;
			headers_visible = false;
			fixed_height_mode = true;

			create_columns (out coll, out pls);

			CollectionsModel store = new CollectionsModel(coll, pls);
			store.collection_loaded += (type) => {
				expand_all();
			};
			model = store;

			row_activated += on_row_activated;

			enable_model_drag_dest(_target_entries,
			                       Gdk.DragAction.COPY);

			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         _source_entries,
			                         Gdk.DragAction.MOVE);

			create_context_menu();
			get_selection().changed += on_selection_changed_update_menu;
			on_selection_changed_update_menu(get_selection());

			drag_leave += on_drag_leave;
			drag_motion += on_drag_motion;
			drag_data_get += on_drag_data_get;
			drag_data_received += on_drag_data_received;

			key_press_event += on_key_press_event;
			button_press_event += on_button_press_event;
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

			foreach (weak Gtk.MenuItem i
			         in _collection_menu_item_when_coll_selected) {
				i.sensitive = (n == 2);
			}

			foreach (weak Gtk.MenuItem i
			         in _collection_menu_item_when_ns_selected) {
				i.sensitive = (n == 1);
			}
		}


		private void on_drag_data_get (CollectionsView w, Gdk.DragContext ctx,
		                               Gtk.SelectionData selection_data,
		                               uint info, uint time)
		{
			weak Gtk.TreeSelection sel = get_selection();
			GLib.List<Gtk.TreePath> lst = sel.get_selected_rows(null);
			Gtk.TreeIter iter;
			string name;
			int type;

			model.get_iter(out iter, lst.data);

			model.get(
				iter,
				CollectionsModel.Column.Name, out name,
				CollectionsModel.Column.Type, out type
			);

			if (type == CollectionsModel.CollectionType.Playlist) {
				name = Xmms.COLLECTION_NS_PLAYLISTS + "/" + name;
			} else {
				name = Xmms.COLLECTION_NS_COLLECTIONS + "/" + name;
			}

			/* This should be removed as #515408 gets fixed. */
			weak uchar[] data = (uchar[]) name;
			data.length = (int) name.len() * 8;

			selection_data.set(
				Gdk.Atom.intern(_target_entries[1].target, true),
				8, data
			);
		}


		private bool on_button_press_event (CollectionsView w, Gdk.EventButton button)
		{
			Gtk.TreePath path;
			int x, y;

			/* we're only interested in the 3rd mouse button */
			if (button.button != 3) {
				return false;
			}

			_collection_menu.popup(
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


		private bool on_key_press_event (CollectionsView w, Gdk.EventKey e)
		{
			switch (e.keyval) {
				case Gdk.Keysym.F2:
					selected_collection_rename();
					return true;
				case Gdk.Keysym.Delete:
					selected_collection_delete();
					return true;
			}

			return false;
		}


		/**
		 * Handle user input rename of collections.
		 */
		private void on_cell_edited (CollCellRenderer renderer,
		                             string path, string new_text)
		{
			Client c = Client.instance();
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

			c.xmms.coll_rename(name, new_text, ns);
		}



		/**
		 * When dragging something over the collection tree widget, show a
		 * temporary new playlist, and update the drop paths.
		 */
		private bool on_drag_motion (CollectionsView w, Gdk.DragContext ctx,
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
		private void on_drag_leave (CollectionsView widget,
		                            Gdk.DragContext ctx,
		                            uint time)
		{
			CollectionsModel store = (CollectionsModel) model;
			Gtk.TreeViewDropPosition pos;

			/* save to handle */
			get_drag_dest_row(out _drop_path, out pos);

			if (store.has_temporary_playlist) {
				store.remove_temporary_playlist();
			}
		}


		/**
		 * 
		 */
		private void on_drag_data_received (CollectionsView w,
		                                    Gdk.DragContext ctx,
		                                    int x_pos, int y_pos,
		                                    Gtk.SelectionData data,
		                                    uint info, uint time)
		{
			CollectionsModel store = (CollectionsModel) model;

			if (_drop_path != null) {
				CollectionsModel.CollectionType type;
				string name = "Unknown";
				Gtk.TreeIter iter;

				store.get_iter(out iter, _drop_path);

				if (!store.get_iter(out iter, _drop_path)) {
					name = store.realize_temporary_playlist();
				} else {
					type = CollectionsModel.CollectionType.Playlist;
					if (store.path_is_child_of_type(_drop_path, type)) {
						store.get(iter, CollectionsModel.Column.Name, out name);
					}
				}

				playlist_insert_drop_data(info, name, data);

				_drop_path = null;
			}

			if (store.has_temporary_playlist) {
				store.remove_temporary_playlist();
			}

			Gtk.drag_finish(ctx, true, false, time);
		}


		private void playlist_insert_drop_data (uint info, string name,
		                                        Gtk.SelectionData sel)
		{
			Client c = Client.instance();

			if (info == (uint) DragDropTargetType.MID) {
				/* This should be removed as #515408 gets fixed. */
				weak uint[] ids = (uint[]) sel.data;
				ids.length = (int)(sel.length / sizeof(uint));

				for(int i = ids.length -1; i >= 0; i--) {
					c.xmms.playlist_add_id(name, ids[i]);
				}
			} else if (info == (uint) DragDropTargetType.COLL) {
				string[] collection_data;
				string coll_ns, coll_name;
				Xmms.Collection coll;

				collection_data = ((string) sel.data).split("/");
				coll_ns = collection_data[0];
				coll_name = collection_data[1];

				coll = new Xmms.Collection(Xmms.CollectionType.REFERENCE);
				coll.attribute_set("reference", coll_name);
				coll.attribute_set("namespace", coll_ns);

				c.xmms.playlist_add_collection(name, coll, null);
			}
		}



		private void on_row_activated (CollectionsView tree,
		                               Gtk.TreePath path,
		                               Gtk.TreeViewColumn column)
		{
			CollectionsModel store = (CollectionsModel) model;
			CollectionsModel.CollectionType type;
			Gtk.TreeIter iter;
			string name;

			Client c = Client.instance();

			store.get_iter(out iter, path);
			store.get(iter, CollectionsModel.Column.Name, out name);

			type = CollectionsModel.CollectionType.Collection;
			if (store.path_is_child_of_type(path, type)) {
				c.xmms.coll_get(name, "Collections").notifier_set(
					on_coll_get
				);
				if (Client.collection_needs_quoting(name)) {
					Abraca.instance().main_window.main_hpaned.
					right_hpaned.filter_entry_set_text("in:\"" + name + "\"");
				} else {
					Abraca.instance().main_window.main_hpaned.
						right_hpaned.filter_entry_set_text("in:" + name);
				}
			} else {
				c.xmms.playlist_load(name);
			}
		}



		private void on_menu_collection_get(Gtk.ImageMenuItem item) {
			weak Gtk.TreeSelection selection;
			Gtk.TreeIter iter;

			selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				CollectionsModel store = (CollectionsModel) model;
				Gtk.TreePath path = store.get_path(iter);

				if (path.get_depth() == 2) {
					CollectionsModel.CollectionType type;
					Client c = Client.instance();
					weak string ns;
					string name;

					store.get(iter, CollectionsModel.Column.Name, out name);

					type = CollectionsModel.CollectionType.Collection;
					if (store.path_is_child_of_type(path, type)) {
						ns = Xmms.COLLECTION_NS_COLLECTIONS;
					} else {
						ns = Xmms.COLLECTION_NS_PLAYLISTS;
					}

					/* TODO: Pass to the top class of filtertree */
					c.xmms.coll_get(name, ns).notifier_set(on_coll_get);

					if (Client.collection_needs_quoting(name)) {
						Abraca.instance().main_window.main_hpaned.
							right_hpaned.filter_entry_set_text(
								"in:\"" + ns + "/" + name + "\""
							);
					} else {
						Abraca.instance().main_window.main_hpaned.
							right_hpaned.filter_entry_set_text(
								"in:" + ns + "/" + name
							);
					}
				}
			}
		}


		private void selected_collection_rename ()
		{
			weak Gtk.TreeSelection selection;
			Gtk.TreeIter iter;

			selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				Gtk.TreePath path = model.get_path(iter);

				if (path.get_depth() == 2) {
					weak GLib.List<Gtk.CellRenderer> renderers;
					Gtk.CellRendererText renderer;
					weak GLib.List<Gtk.TreeViewColumn> cols;
					Gtk.TreeViewColumn col;

					cols = get_columns();
					col = cols.data;

					renderers = col.get_cell_renderers();
					renderer = (Gtk.CellRendererText) renderers.data;

					renderer.editable = true;
					set_cursor_on_cell(path, col, renderer, true);
					renderer.editable = false;
				}
			}
		}


		private void selected_collection_delete ()
		{
			weak Gtk.TreeSelection selection;
			Gtk.TreeIter iter;

			selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				CollectionsModel store = (CollectionsModel) model;
				Gtk.TreePath path = store.get_path(iter);

				if (path.get_depth() == 2) {
					CollectionsModel.CollectionType type;
					Client c = Client.instance();
					weak string ns = Xmms.COLLECTION_NS_PLAYLISTS;
					string name;

					store.get(iter, CollectionsModel.Column.Name, out name);

					type = CollectionsModel.CollectionType.Collection;
					if (store.path_is_child_of_type(path, type)) {
						ns = Xmms.COLLECTION_NS_COLLECTIONS;
					}

					c.xmms.coll_remove(name, ns);
				}
			}
		}


		private bool on_coll_get (Xmms.Value val)
		{
			Xmms.Collection coll;

			if (val.get_coll(out coll)) {
				Abraca.instance().main_window.main_hpaned.
					right_hpaned.filter_tree.query_collection(coll);
			}

			return true;
		}


		/**
		 * Create the treeview columns.
		 */
		private void create_columns (out Gdk.Pixbuf coll_pbuf,
		                             out Gdk.Pixbuf pls_pbuf)
		{
			Gtk.TreeViewColumn column;
			CollCellRenderer renderer;

			/* Load the playlist icon */
			try {
				pls_pbuf = new Gdk.Pixbuf.from_inline (
					-1, Resources.abraca_playlist_22, false
				);
			} catch (GLib.Error e) {
				GLib.stderr.printf("ERROR: %s\n", e.message);
			}

			/* ..and the collection icon */
			try {
				coll_pbuf = new Gdk.Pixbuf.from_inline (
					-1, Resources.abraca_collection_22, false
				);
			} catch (GLib.Error e) {
				GLib.stderr.printf("ERROR: %s\n", e.message);
			}

			renderer = new CollCellRenderer();
			renderer.height = pls_pbuf.height;
			renderer.edited += on_cell_edited;

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
			Gtk.ImageMenuItem item;

			_collection_menu = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.with_mnemonic(_("_Show"));
			item.image = new Gtk.Image.from_stock(
				Gtk.STOCK_FIND, Gtk.IconSize.MENU
			);
			item.activate += on_menu_collection_get;
			_collection_menu_item_when_coll_selected.prepend(item);
			_collection_menu.append(item);

			item = new Gtk.ImageMenuItem.with_mnemonic(_("_Rename"));
			item.image = new Gtk.Image.from_stock(
				Gtk.STOCK_EDIT, Gtk.IconSize.MENU
			);
			item.activate += (menu) => {
				selected_collection_rename();
			};
			_collection_menu_item_when_coll_selected.prepend(item);
			_collection_menu.append(item);

			item = new Gtk.ImageMenuItem.with_mnemonic(_("Delete"));
			item.image = new Gtk.Image.from_stock(
				Gtk.STOCK_DELETE, Gtk.IconSize.MENU
			);
			item.activate += (menu) => {
				selected_collection_delete();
			};
			_collection_menu_item_when_coll_selected.prepend(item);
			_collection_menu.append(item);

			_collection_menu.show_all();
		}
	}
}
