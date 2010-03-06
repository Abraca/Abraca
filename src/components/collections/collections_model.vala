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
	public class CollectionsModel : Gtk.TreeStore, Gtk.TreeModel {
		public enum CollectionType {
			Invalid = 0,
			Collection,
			Playlist
		}

		public enum Column {
			Type = 0,
			Icon,
			Style,
			Weight,
			Name,
			Total
		}

		private Gtk.TreeIter _temporary_playlist_iter;

		/* TODO: Is this required? */
		public bool has_temporary_playlist {
			get; private set; default = false;
		}

		private Gtk.TreeIter _playlist_iter;
		private Gtk.TreeIter _collection_iter;

		public Gdk.Pixbuf playlist_pixbuf { get; construct set; }
		public Gdk.Pixbuf collection_pixbuf { get; construct set; }

		/* Emited after 1..* collections has been added. */
		public signal void collection_loaded (CollectionType type);

		public CollectionsModel (Gdk.Pixbuf coll, Gdk.Pixbuf pls)
		{
			Object(playlist_pixbuf: coll, collection_pixbuf: pls);
		}

		construct {
			Client c = Client.instance();

			set_column_types(new GLib.Type[5] {
				typeof(int),
				typeof(Gdk.Pixbuf),
				typeof(int),
				typeof(int),
				typeof(string)
			});

			append(out _collection_iter, null);
			set(_collection_iter,
				Column.Type, CollectionType.Invalid,
				Column.Icon, null,
				Column.Style, Pango.Style.NORMAL,
				Column.Weight, Pango.Weight.BOLD,
				Column.Name, _("Collections")
			);

			append(out _playlist_iter, null);
			set(_playlist_iter,
				Column.Type, CollectionType.Invalid,
				Column.Icon, null,
				Column.Style, Pango.Style.NORMAL,
				Column.Weight, Pango.Weight.BOLD,
				Column.Name, _("Playlists")
			);

			c.playlist_loaded.connect(on_playlist_loaded);
			c.collection_add.connect(on_collection_add);
			c.collection_rename.connect(on_collection_rename);
			c.collection_remove.connect(on_collection_remove);
			c.connected.connect(query_collections);
		}


		/**
		 * Check wether a path is of, or is descendant of some type.
		 */
		public bool path_is_type (Gtk.TreePath path, CollectionType t)
		{
			Gtk.TreeIter iter;
			Gtk.TreePath cmp;

			if (t == CollectionType.Collection) {
				iter = _collection_iter;
			} else {
				iter = _playlist_iter;
			}

			cmp = get_path(iter);

			return path.compare(cmp) == 0 || path.is_descendant(cmp);
		}


		/**
		 * Check wether a path is a descendant of some type.
		 */
		public bool path_is_child_of_type (Gtk.TreePath path, CollectionType t)
		{
			Gtk.TreeIter iter;
			Gtk.TreePath cmp;

			if (t == CollectionType.Collection) {
				iter = _collection_iter;
			} else {
				iter = _playlist_iter;
			}

			cmp = get_path(iter);

			return path.is_descendant(cmp);
		}


		/**
		 * Add a new temporary playlist to the model.
		 * This is used when dropping media to a new playlist.
		 */
		public void append_temporary_playlist ()
		{
			append(out _temporary_playlist_iter, _playlist_iter);

			set(_temporary_playlist_iter,
				Column.Type, CollectionType.Playlist,
				Column.Icon, playlist_pixbuf,
				Column.Name, get_new_playlist_name()
			);

			has_temporary_playlist = true;
		}


		/**
		 * Remove the current temporary playlist from the model.
		 */
		public void remove_temporary_playlist ()
		{
			remove(_temporary_playlist_iter);
			has_temporary_playlist = false;
		}


		/**
		 * Transform the current temporary playlist to a real
		 * playlist and return its name.
		 */
		public string realize_temporary_playlist ()
		{
			Client c = Client.instance();
			string name = get_new_playlist_name();

			c.xmms.playlist_create(name);

			has_temporary_playlist = false;

			return name;
		}


		/**
		 * Generate a new unique playlist name by suffixing "New Playlist"
		 * with an integer.
		 */
		private string get_new_playlist_name ()
		{
			Gtk.TreeIter iter;
			int current, highest = -1;

			iter_children(out iter, _playlist_iter);
			do {
				string[] parts;
				string name;

				get(iter, Column.Name, out name);

				if (name == null) {
					continue;
				}

				parts = name.split("-", 2);
				if (parts[0] == _("New Playlist")) {
					if (parts[1] != null) {
						current = parts[1].to_int();
					} else {
						current = 0;
					}

					if (current > highest) {
						highest = current;
					}
				}
			} while (iter_next(ref iter));

			if (!has_temporary_playlist) {
				highest++;
			}

			if (highest > 0) {
				return _("New Playlist") + highest.to_string("-%i");
			} else {
				return _("New Playlist");
			}
		}


		private void query_collections (Client c)
		{
			c.xmms.coll_list(Xmms.COLLECTION_NS_COLLECTIONS).notifier_set(r => {
				on_list_collections(r, CollectionType.Collection);
				return true;
			});

			c.xmms.coll_list(Xmms.COLLECTION_NS_PLAYLISTS).notifier_set(r => {
				on_list_collections(r, CollectionType.Playlist);
				return true;
			});
		}


		/**
		 * Perform a full list of Collections starting from a clean tree.
		 */
		private bool on_list_collections (Xmms.Value val, CollectionType type)
		{
			Gtk.TreeIter child, parent;
			unowned Gdk.Pixbuf pixbuf;

			if (type == CollectionType.Collection) {
				parent = _collection_iter;
				pixbuf = collection_pixbuf;
			} else {
				parent = _playlist_iter;
				pixbuf = playlist_pixbuf;
			}

			while (iter_children(out child, parent)) {
				remove(child);
			}

			int pos = iter_n_children(parent);

			unowned Xmms.ListIter list_iter;
			val.get_list_iter(out list_iter);

			for (list_iter.first(); list_iter.valid(); list_iter.next()) {
				Pango.Weight weight = Pango.Weight.NORMAL;
				Pango.Style style = Pango.Style.NORMAL;
				unowned Xmms.Value entry;
				Gtk.TreeIter iter;
				string? name = null;

				if (!(list_iter.entry(out entry) && entry.get_string (out name)))
					continue;

				// Ignore hidden collections
				if (name[0] == '_')
					continue;

				if (type == CollectionType.Playlist) {
					Client c = Client.instance();
					if (name == c.current_playlist) {
						style = Pango.Style.ITALIC;
						weight = Pango.Weight.BOLD;
					}
				}

				insert_with_values(
					out iter, parent, pos++,
					CollectionsModel.Column.Type, type,
					CollectionsModel.Column.Icon, pixbuf,
					CollectionsModel.Column.Style, style,
					CollectionsModel.Column.Weight, weight,
					CollectionsModel.Column.Name, name
				);
			}

			collection_loaded(type);

			return true;
		}


		/**
		 * When a playlist is loaded, mark it as bold, and other as normal.
		 */
		private void on_playlist_loaded (Client c, string name)
		{
			Gtk.TreeIter iter;

			if (iter_children(out iter, _playlist_iter)) {
				do {
					string current;
					int style;

					get(iter, Column.Name, out current,
					    Column.Style, out style);

					if (style != Pango.Style.NORMAL) {
						set(iter,
							Column.Style, Pango.Style.NORMAL,
						    Column.Weight, Pango.Weight.NORMAL
						);
					}

					if (current == name) {
						set(iter,
							Column.Style, Pango.Style.ITALIC,
						    Column.Weight, Pango.Weight.BOLD
						);
					}
				} while (iter_next(ref iter));
			}
		}


		/**
		 * Manage Collection creations.
		 */
		private void on_collection_add (Client c, string name, string ns)
		{
			Gtk.TreeIter iter, parent;
			unowned Gdk.Pixbuf pixbuf;
			CollectionType type;

			if (name[0] == '_') {
				return;
			}

			if (ns == Xmms.COLLECTION_NS_PLAYLISTS) {
				parent = _playlist_iter;
				type = CollectionType.Playlist;
				pixbuf = playlist_pixbuf;
			} else {
				parent = _collection_iter;
				type = CollectionType.Collection;
				pixbuf = collection_pixbuf;
			}

			append(out iter, parent);

			set(iter,
				Column.Type, type,
				Column.Icon, pixbuf,
				Column.Name, name
			);

			collection_loaded(type);
		}


		/**
		 * Manage Collection renames.
		 */
		private void on_collection_rename (Client c, string name,
		                                   string newname, string ns)
		{
			Gtk.TreeIter iter, parent;

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

			iter_children(out iter, parent);
			do {
				string current;

				get(iter, Column.Name, out current);
				if (name == current) {
					set(iter, Column.Name, newname);
					break;
				}
			} while (iter_next(ref iter));
		}


		/**
		 * Manage removal of collections.
		 */
		private void on_collection_remove (Client c, string name, string ns)
		{
			Gtk.TreeIter iter, parent;

			if (ns == Xmms.COLLECTION_NS_PLAYLISTS) {
				parent = _playlist_iter;
			} else {
				parent = _collection_iter;
			}

			iter_children(out iter, parent);
			do {
				string current;

				get(iter, Column.Name, out current);
				if (name == current) {
					remove(iter);
					break;
				}
			} while (iter_next(ref iter));
		}
	}
}

