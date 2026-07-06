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
	/** A node in the collections tree: either a root header or a leaf entry. */
	public class CollectionNode : GLib.Object {
		public CollectionsModel.CollectionType node_type { get; set; }
		public string name { get; set; }
		public bool is_root { get; construct; }
		public bool is_current { get; set; default = false; }

		/** child store for roots; null for leaves (not expandable) */
		public GLib.ListStore? children { get; construct; }

		public CollectionNode (CollectionsModel.CollectionType type, string name,
		                       bool is_root, GLib.ListStore? children)
		{
			Object (is_root: is_root, children: children);
			this.node_type = type;
			this.name = name;
		}
	}

	public class CollectionsModel : GLib.Object {
		public enum CollectionType {
			Invalid = 0,
			Collection,
			Playlist
		}

		public Gtk.TreeListModel tree_model { get; construct; }

		private GLib.ListStore roots;
		private CollectionNode collection_root;
		private CollectionNode playlist_root;

		private CollectionNode? temporary_playlist = null;

		public bool has_temporary_playlist {
			get { return temporary_playlist != null; }
		}

		/* Emited after 1..* collections has been added. */
		public signal void collection_loaded (CollectionType type);

		private Client client;

		public CollectionsModel (Client c)
		{
			client = c;

			collection_root = new CollectionNode (CollectionType.Collection, _("Collections"),
			                                      true, new GLib.ListStore (typeof (CollectionNode)));
			playlist_root = new CollectionNode (CollectionType.Playlist, _("Playlists"),
			                                    true, new GLib.ListStore (typeof (CollectionNode)));

			roots = new GLib.ListStore (typeof (CollectionNode));
			roots.append (collection_root);
			roots.append (playlist_root);

			_tree_model = new Gtk.TreeListModel (roots, false, true, (item) => {
				return ((CollectionNode) item).children;
			});

			client.playlist_loaded.connect(on_playlist_loaded);
			client.collection_add.connect(on_collection_add);
			client.collection_rename.connect(on_collection_rename);
			client.collection_remove.connect(on_collection_remove);
			client.connection_state_changed.connect(query_collections);
		}

		private unowned GLib.ListStore store_for (CollectionType type)
		{
			return (type == CollectionType.Collection)
				? collection_root.children : playlist_root.children;
		}

		private CollectionNode? find_child (GLib.ListStore store, string name)
		{
			for (uint i = 0; i < store.get_n_items (); i++) {
				var node = (CollectionNode) store.get_item (i);
				if (node.name == name)
					return node;
			}
			return null;
		}


		/**
		 * Add a new temporary playlist to the model.
		 * This is used when dropping media to a new playlist.
		 */
		public void append_temporary_playlist ()
		{
			temporary_playlist = new CollectionNode (CollectionType.Playlist,
			                                         get_new_playlist_name (), false, null);
			playlist_root.children.append (temporary_playlist);
		}


		/**
		 * Remove the current temporary playlist from the model.
		 */
		public void remove_temporary_playlist ()
		{
			if (temporary_playlist == null)
				return;
			uint pos;
			if (playlist_root.children.find (temporary_playlist, out pos))
				playlist_root.children.remove (pos);
			temporary_playlist = null;
		}


		/**
		 * Transform the current temporary playlist to a real
		 * playlist and return its name.
		 */
		public string realize_temporary_playlist ()
		{
			string name = get_new_playlist_name ();
			client.xmms.playlist_create (name);
			temporary_playlist = null;
			return name;
		}


		/**
		 * Generate a new unique playlist name by suffixing "New Playlist"
		 * with an integer.
		 */
		private string get_new_playlist_name ()
		{
			int current, highest = -1;

			var store = playlist_root.children;
			for (uint i = 0; i < store.get_n_items (); i++) {
				var node = (CollectionNode) store.get_item (i);
				var parts = node.name.split ("-", 2);
				if (parts[0] == _("New Playlist")) {
					current = (parts[1] != null) ? int.parse (parts[1]) : 0;
					if (current > highest)
						highest = current;
				}
			}

			if (!has_temporary_playlist)
				highest++;

			if (highest > 0)
				return _("New Playlist") + highest.to_string ("-%i");
			else
				return _("New Playlist");
		}


		private void query_collections (Client c, Client.ConnectionState state)
		{
			if (state != Client.ConnectionState.Connected)
				return;

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
			var store = store_for (type);
			store.remove_all ();

			unowned Xmms.ListIter list_iter;
			val.get_list_iter(out list_iter);

			for (list_iter.first(); list_iter.valid(); list_iter.next()) {
				unowned Xmms.Value entry;
				string? name = null;

				if (!(list_iter.entry(out entry) && entry.get_string (out name)))
					continue;

				// Ignore hidden collections
				if (name[0] == '_')
					continue;

				var node = new CollectionNode (type, name, false, null);
				if (type == CollectionType.Playlist && name == client.current_playlist)
					node.is_current = true;

				store.append (node);
			}

			collection_loaded(type);

			return true;
		}


		/**
		 * When a playlist is loaded, mark it as current, and others as normal.
		 */
		private void on_playlist_loaded (Client c, string name)
		{
			var store = playlist_root.children;
			for (uint i = 0; i < store.get_n_items (); i++) {
				var node = (CollectionNode) store.get_item (i);
				node.is_current = (node.name == name);
			}
		}


		/**
		 * Manage Collection creations.
		 */
		private void on_collection_add (Client c, string name, string ns)
		{
			if (name[0] == '_')
				return;

			CollectionType type = (ns == Xmms.COLLECTION_NS_PLAYLISTS)
				? CollectionType.Playlist : CollectionType.Collection;

			store_for (type).append (new CollectionNode (type, name, false, null));

			collection_loaded(type);
		}


		/**
		 * Manage Collection renames.
		 */
		private void on_collection_rename (Client c, string name,
		                                   string newname, string ns)
		{
			/* check for any current or future invisible collections */
			if (name[0] == '_') {
				if (newname[0] != '_')
					on_collection_add(c, newname, ns);
				return;
			} else if (newname[0] == '_') {
				on_collection_remove(c, name, ns);
				return;
			}

			CollectionType type = (ns == Xmms.COLLECTION_NS_PLAYLISTS)
				? CollectionType.Playlist : CollectionType.Collection;

			var node = find_child (store_for (type), name);
			if (node != null)
				node.name = newname;
		}


		/**
		 * Manage removal of collections.
		 */
		private void on_collection_remove (Client c, string name, string ns)
		{
			CollectionType type = (ns == Xmms.COLLECTION_NS_PLAYLISTS)
				? CollectionType.Playlist : CollectionType.Collection;

			var store = store_for (type);
			var node = find_child (store, name);
			if (node != null) {
				uint pos;
				if (store.find (node, out pos))
					store.remove (pos);
			}
		}
	}
}
