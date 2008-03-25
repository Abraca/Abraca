/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */

namespace Abraca {
	public enum CollectionType {
		Invalid = 0,
		Collection,
		Playlist
	}

	enum CollColumn {
		Type = 0,
		Icon,
		Style,
		Weight,
		Name,
		Total
	}

	public class CollectionsTree : Gtk.TreeView {

		/** allowed drag-n-drop variants */
		private const Gtk.TargetEntry[] _target_entries = {
			DragDropTarget.TrackId,
			DragDropTarget.Collection
		};

		/** context menu */
		private Gtk.Menu _collection_menu;

		private string _playlist;
		private Gtk.TreeIter _playlist_iter;
		private Gtk.TreeIter _collection_iter;
		private Gtk.TreePath _drop_path = null;

		private Gtk.TreeIter _new_playlist_iter;
		private bool _new_playlist_visible = false;

		construct {
			Client c = Client.instance();

			enable_search = true;
			search_column = 0;
			headers_visible = false;
			show_expanders = true;
			fixed_height_mode = true;

			create_columns ();
			model = create_model();
			create_context_menu();

			enable_model_drag_dest(_target_entries,
			                       Gdk.DragAction.COPY);

			row_activated += on_row_activated;

			enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
			                         _target_entries,
			                         Gdk.DragAction.MOVE);

			drag_motion += on_drag_motion;
			drag_leave += on_drag_leave;
			drag_data_received += on_drag_data_received;
			drag_data_get += on_drag_data_get;
			button_press_event += on_button_press_event;

			c.playlist_loaded += on_playlist_loaded;
			c.collection_add += on_collection_add;
			c.collection_rename += on_collection_rename;
			c.collection_remove += on_collection_remove;
			c.connected += query_collections;
		}

		[InstanceLast]
		private bool on_drag_data_get(Gtk.Widget w, Gdk.DragContext ctx,
		                              Gtk.SelectionData selection_data,
		                              uint info, uint time) {
			weak Gtk.TreeSelection sel = get_selection();
			weak GLib.List<weak Gtk.TreePath> lst = sel.get_selected_rows(null);
			Gtk.TreeIter iter;
			string name;

			model.get_iter(out iter, lst.data);
			model.get(iter, CollColumn.Name, out name);

			/* This should be removed as #515408 gets fixed. */
			weak uchar[] data = (uchar[]) name;
			data.length = (int) name.len() * 8;

			selection_data.set(
					Gdk.Atom.intern(_target_entries[1].target, true),
					8, data
			);

			return true;
		}

		private bool on_button_press_event(Gtk.Widget w, Gdk.Event e) {
			weak Gdk.EventButton button_event = (Gdk.EventButton) e;

			/* we're only interested in the 3rd mouse button */
			if (button_event.button != 3) {
				return false;
			}

			_collection_menu.popup(
				null, null, null, button_event.button,
				Gtk.get_current_event_time()
			);

			return true;
		}

		/**
		 * send rename-command to server, when item in collection-list was changed
		 */
		private void on_collection_cell_renderer_edited (Gtk.CellRendererText renderer, string path, string new_text) {
			Gtk.TreeIter iter;
			int type;
			string name, ns;

			model.get_iter_from_string(out iter, path);

			model.get(iter, CollColumn.Name, out name, CollColumn.Type, out type);

			if (type == CollectionType.Playlist) {
				ns = Xmms.COLLECTION_NS_PLAYLISTS;
			}
			else {
				ns = Xmms.COLLECTION_NS_COLLECTIONS;
			}

			Client c = Client.instance();
			c.xmms.coll_rename(name, new_text, ns);

			return;
		}

		/**
		 * Add a temporary new playlist.
		 */
		private bool on_drag_motion (Gtk.Widget w, Gdk.DragContext ctx,
		                             int x, int y, uint time) {
			Gtk.TreeStore store = (Gtk.TreeStore) model;
			Gtk.TreeViewDropPosition pos;
			Gtk.TreePath path;

			bool update = false;

			Gdk.drag_status(ctx, Gdk.DragAction.COPY, time);
			set_drag_dest_row(null, Gtk.TreeViewDropPosition.INTO_OR_AFTER);

			if (get_dest_row_at_pos(x, y, out path, out pos)) {
				Gtk.TreePath tmp = store.get_path(_playlist_iter);
				if (path.compare(tmp) == 0 || path.is_descendant(tmp)) {
					update = !_new_playlist_visible;
					if (path.is_descendant(tmp)) {
						set_drag_dest_row(path, Gtk.TreeViewDropPosition.INTO_OR_AFTER);
					}
				} else if (_new_playlist_visible) {
					store.remove(_new_playlist_iter);
					_new_playlist_visible = false;
				}
			} else {
				update = !_new_playlist_visible;
			}

			if (update) {
				CollectionType type = CollectionType.Playlist;
				store.append(out _new_playlist_iter, _playlist_iter);

				store.set(_new_playlist_iter,
					CollColumn.Type, type,
					CollColumn.Icon, null,
					CollColumn.Name, "New Playlist"
				);

				_new_playlist_visible = true;
			}

			return true;
		}

		/**
		 * Remove the temporary playlist.
		 */
		private void on_drag_leave (Gtk.Widget w, Gdk.DragContext ctx, uint time_) {
			Gtk.TreeViewDropPosition pos;
			Gtk.TreeStore store;
			Gtk.TreePath tmp;

			store = (Gtk.TreeStore) model;

			/* save to handle */
			get_drag_dest_row(out _drop_path, out pos);

			tmp = store.get_path(_new_playlist_iter);
			if (_new_playlist_visible) {
				store.remove(_new_playlist_iter);
				_new_playlist_visible = false;
			}
		}

		private void on_drag_data_received (Gtk.Widget w, Gdk.DragContext ctx, int x, int y,
		                                    Gtk.SelectionData selection_data,
		                                    uint info, uint time) {
			Gtk.TreeStore store = (Gtk.TreeStore) model;
			Gtk.TreeViewDropPosition pos;
			Gtk.TreePath path;
			string name;

			if (_drop_path != null) {
				Gtk.TreePath tmp;

				tmp = store.get_path(_new_playlist_iter);
				if (_drop_path.compare(tmp) == 0) {
					Client c = Client.instance();

					c.xmms.playlist_create("New Playlist");

					playlist_insert_drop_data("New Playlist", selection_data);

					_new_playlist_visible = false;
				} else {
					tmp = store.get_path(_playlist_iter);
					if (_drop_path.is_descendant(tmp)) {
						Gtk.TreeIter iter;
						if (model.get_iter(out iter, _drop_path)) {
							model.get(iter, CollColumn.Name, out name);
							playlist_insert_drop_data(name, selection_data);
						}
					}
				}

				_drop_path = null;
			}

			if (_new_playlist_visible) {
				store.remove(_new_playlist_iter);
				_new_playlist_visible = false;
			}

			Gtk.drag_finish(ctx, true, false, time);
		}

		private void playlist_insert_drop_data(string name, Gtk.SelectionData sel) {
			Client c = Client.instance();

			/* This should be removed as #515408 gets fixed. */
			weak uint[] ids = (uint[]) sel.data;
			ids.length = (int)(sel.length / sizeof(uint));

			foreach (uint id in ids) {
				c.xmms.playlist_add_id(name, id);
			}
		}

		/**
		 * Called when xmms2 has loaded a new playlist, simply saves
		 * the name and updates the treeview
		 */
		private void on_playlist_loaded(Client c, string name) {
			_playlist = name;

			Gtk.TreeStore store = (Gtk.TreeStore) model;
			Gtk.TreeIter iter;
			string current;
			weak string attr;
			string text;
			int style;

			if (model.iter_children(out iter, _playlist_iter)) {
				do {
					store.get(iter, CollColumn.Name, out current, CollColumn.Style, out style);

					if (style != Pango.Style.NORMAL) {
						store.set(iter, CollColumn.Style, Pango.Style.NORMAL,
						                CollColumn.Weight, Pango.Weight.NORMAL);
					}
					if (current == name) {
						store.set(iter, CollColumn.Style, Pango.Style.ITALIC,
						                CollColumn.Weight, Pango.Weight.BOLD);
					}
				} while (model.iter_next(ref iter));
			}
		}

		private void on_collection_add (Client c, string name, string ns) {
			Gtk.TreeIter parent;
			Gtk.TreeIter iter;
			CollectionType type;

			if (name[0] == '_') {
				return;
			}

			if (ns == Xmms.COLLECTION_NS_PLAYLISTS) {
				parent = _playlist_iter;
				type = CollectionType.Playlist;
			} else {
				parent = _collection_iter;
				type = CollectionType.Collection;
			}

			Gtk.TreeStore store = (Gtk.TreeStore) model;

			store.append(out iter, parent);
			store.set(iter,
			          CollColumn.Type, type,
			          CollColumn.Icon, null,
			          CollColumn.Name, name);
		}

		private void on_collection_rename(Client c, string name, string newname, string ns) {
			Gtk.TreeIter parent;
			Gtk.TreeIter iter;
			string current;

			/* check for any current or future invisible collections */
			if (name[0] == '_') {
				if (newname[0] == '_') {
					return;
				} else {
					on_collection_add(c, newname, ns);
				}
				return;
			} else {
				if (newname[0] == '_') {
					on_collection_remove(c, name, ns);
					return;
				}
			}


			if (ns == Xmms.COLLECTION_NS_PLAYLISTS) {
				parent = _playlist_iter;
			} else {
				parent = _collection_iter;
			}

			Gtk.TreeStore store = (Gtk.TreeStore) model;

			store.iter_children(out iter, parent);
			do {
				store.get(iter, CollColumn.Name, out current);
				if (name == current) {
					store.set(iter, CollColumn.Name, newname);
					break;
				}
			} while (store.iter_next(ref iter));
		}

		private void on_collection_remove(Client c, string name, string ns) {
			Gtk.TreeIter parent;
			Gtk.TreeIter iter;
			string current;

			if (ns == Xmms.COLLECTION_NS_PLAYLISTS) {
				parent = _playlist_iter;
			} else {
				parent = _collection_iter;
			}

			Gtk.TreeStore store = (Gtk.TreeStore) model;

			store.iter_children(out iter, parent);
			do {
				store.get(iter, CollColumn.Name, out current);
				if (name == current) {
					store.remove(iter);
					break;
				}
			} while (store.iter_next(ref iter));
		}

		private void query_collections(Client c) {
			c.xmms.coll_list(Xmms.COLLECTION_NS_COLLECTIONS).notifier_set(
				on_coll_list_collections
			);

			c.xmms.coll_list(Xmms.COLLECTION_NS_PLAYLISTS).notifier_set(
				on_coll_list_playlists
			);
		}

		[InstanceLast]
		private void on_coll_list_collections(Xmms.Result #res) {
			on_coll_list(res, CollectionType.Collection);
		}

		[InstanceLast]
		private void on_coll_list_playlists(Xmms.Result #res) {
			on_coll_list(res, CollectionType.Playlist);
		}

		private void on_coll_list(Xmms.Result #res, CollectionType type) {
			Gtk.TreeIter parent;
			string name;

			if (type == CollectionType.Collection)
				parent = _collection_iter;
			else
				parent = _playlist_iter;

			int pos = model.iter_n_children(parent);

			Gtk.TreeStore store = (Gtk.TreeStore) model;

			for (res.list_first(); res.list_valid(); res.list_next()) {
				Gtk.TreeIter iter;
				weak string s;
				Pango.Style style;
				Pango.Weight weight;

				if (!res.get_string (out s))
					continue;

				/* ignore everything that is for internal use only */
				if (s[0] == '_')
					continue;

				if (type == CollectionType.Playlist && s == _playlist) {
					style = Pango.Style.ITALIC;
					weight = Pango.Weight.BOLD;
				} else {
					style = Pango.Style.NORMAL;
					weight = Pango.Weight.NORMAL;
				}

				store.insert_with_values(
					out iter, parent, pos++,
					CollColumn.Type, type,
					CollColumn.Icon, null,
					CollColumn.Style, style,
					CollColumn.Weight, weight,
					CollColumn.Name, s
				);
			}

			expand_all();
		}

		[InstanceLast]
		private void on_row_activated(
			Gtk.TreeView tree, Gtk.TreePath path,
			Gtk.TreeViewColumn column
		) {
			Gtk.TreeStore store = (Gtk.TreeStore) model;
			Gtk.TreeIter iter;
			Gtk.TreePath tmp;

			Client c = Client.instance();

			string name;

			store.get_iter(out iter, path);
			model.get(iter, CollColumn.Name, ref name);

			tmp = store.get_path(_collection_iter);
			if (path.is_descendant(tmp)) {
				c.xmms.coll_get(name, "Collections").notifier_set(
					on_coll_get
				);
			} else {
				c.xmms.playlist_load(name);
			}
		}

		private void on_menu_collection_rename(Gtk.MenuItem item) {
			Gtk.TreeIter iter;
			Gtk.TreePath path;
			Gtk.TreeViewColumn col;
			GLib.Object obj;
			weak GLib.List<Gtk.CellRenderer> renderers;
			weak GLib.List<Gtk.TreeViewColumn> cols;
			weak Gtk.TreeSelection selection;

			selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				path = model.get_path(iter);

				if (path.get_depth() == 2) {
					cols = get_columns();
					col = cols.data;

					renderers = col.get_cell_renderers();

					obj = renderers.data;
					obj.set("editable", true, null);

					set_cursor_on_cell(path, col, renderers.data, true);

					obj.set("editable", false, null);
				}
			}
		}

		private void on_menu_collection_delete(Gtk.MenuItem item) {
			weak Gtk.TreeSelection selection;
			Gtk.TreeIter iter;

			selection = get_selection();

			if (selection.get_selected(null, out iter)) {
				Gtk.TreePath path = model.get_path(iter);
				if (path.get_depth() == 2) {
					Client c = Client.instance();
					Gtk.TreePath tmp;
					weak string ns;
					string name;

					model.get(iter, CollColumn.Name, ref name);

					if (path.is_descendant(model.get_path(_playlist_iter))) {
						ns = Xmms.COLLECTION_NS_PLAYLISTS;
					}

					if (path.is_descendant(model.get_path(_collection_iter))) {
						ns = Xmms.COLLECTION_NS_COLLECTIONS;
					}

					c.xmms.coll_remove(name, ns);
				}
			}
		}

		[InstanceLast]
		private void on_coll_get(Xmms.Result #res) {
			Xmms.Collection coll;

			res.get_collection(out coll);

			Abraca.instance().main_window.main_hpaned.
				right_hpaned.filter_tree.query_collection(coll);
		}

		private void create_columns() {
			/* TODO: Fix icon
 			insert_column_with_attributes(
				-1, null, new Gtk.CellRendererPixbuf(),
				"stock-id", CollColumn.Icon, null
			);
			*/

			Gtk.CellRendererText renderer = new Gtk.CellRendererText();
			renderer.edited += on_collection_cell_renderer_edited;

 			insert_column_with_attributes(
				-1, null, renderer,
				"style", CollColumn.Style,
				"weight", CollColumn.Weight,
				"markup", CollColumn.Name, null
			);
		}

		private Gtk.TreeModel create_model() {
			Gtk.TreeStore store = new Gtk.TreeStore(
				CollColumn.Total,
				typeof(int), typeof(string), typeof(int), typeof(int), typeof(string)
			);

			int pos = 1;

			store.insert_with_values(
				out _collection_iter, null, pos++,
				CollColumn.Type, CollectionType.Invalid,
				CollColumn.Icon, null,
				CollColumn.Style, Pango.Style.NORMAL,
				CollColumn.Weight, Pango.Weight.BOLD,
				CollColumn.Name, "Collections",
				-1
			);

			store.insert_with_values(
				out _playlist_iter, null, pos++,
				CollColumn.Type, CollectionType.Invalid,
				CollColumn.Icon, null,
				CollColumn.Style, Pango.Style.NORMAL,
				CollColumn.Weight, Pango.Weight.BOLD,
				CollColumn.Name, "Playlists",
				-1
			);

			return store;
		}

		private void create_context_menu() {
			Gtk.ImageMenuItem item;

			_collection_menu = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.with_mnemonic("_Rename");
			item.image = new Gtk.Image.from_stock(
				Gtk.STOCK_EDIT, Gtk.IconSize.MENU
			);
			item.activate += on_menu_collection_rename;
			_collection_menu.append(item);

			item = new Gtk.ImageMenuItem.with_mnemonic("Delete");
			item.image = new Gtk.Image.from_stock(
				Gtk.STOCK_DELETE, Gtk.IconSize.MENU
			);
			item.activate += on_menu_collection_delete;
			_collection_menu.append(item);

			_collection_menu.show_all();
		}
	}
}
