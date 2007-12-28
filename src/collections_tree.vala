/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public enum CollectionType {
		Invalid = 0,
		Collection,
		Playlist
	}

	enum CollColumn {
		Type = 0,
		Icon,
		Name,
		Total
	}

	public class CollectionsTree : Gtk.TreeView {
		construct {
			enable_search = true;
			search_column = 0;
			headers_visible = false;
			show_expanders = true;

			create_columns ();
			model = create_model();
		}

		public void query_collections() {
			Xmms.Client xmms = Abraca.instance().xmms;

			xmms.coll_list("Collections").notifier_set(
				on_coll_list_collections, this
			);

			xmms.coll_list("Playlists").notifier_set(
				on_coll_list_playlists, this
			);
		}

		[InstanceLast]
		private void on_coll_list_collections(Xmms.Result res) {
			on_coll_list(res, CollectionType.Collection);
		}

		[InstanceLast]
		private void on_coll_list_playlists(Xmms.Result res) {
			on_coll_list(res, CollectionType.Playlist);
		}

		private void on_coll_list(Xmms.Result res, CollectionType type) {
			Gtk.TreeIter parent;

			if (type == CollectionType.Collection)
				model.get_iter_first(out parent);
			else
				model.get_iter_from_string(out parent, "1");

			int pos = model.iter_n_children(out parent);

			Gtk.TreeStore store = (Gtk.TreeStore) model;

			for (res.list_first(); res.list_valid(); res.list_next()) {
				Gtk.TreeIter iter;
				weak string s;

				if (!res.get_string (out s))
					continue;

				/* ignore playlists that are for internal use only */
				if (type == CollectionType.Playlist && s[0] == '_')
					continue;

				store.insert_with_values(
					ref iter, ref parent, pos++,
					CollColumn.Type, type,
					CollColumn.Icon, null,
					CollColumn.Name, s,
					-1
				);
			}

			expand_all();
		}

		private void create_columns() {
 			insert_column_with_attributes(
				-1, null, new Gtk.CellRendererPixbuf(),
				"stock-id", CollColumn.Icon, null
			);

 			insert_column_with_attributes(
				-1, null, new Gtk.CellRendererText(),
				"markup", CollColumn.Name, null
			);
		}

		private Gtk.TreeModel create_model() {
			Gtk.TreeStore store = new Gtk.TreeStore(
				CollColumn.Total,
				typeof(int), typeof(string), typeof(string)
			);

			Gtk.TreeIter iter;
			int pos = 1;

			store.insert_with_values(
				ref iter, null, pos++,
				CollColumn.Type, CollectionType.Invalid,
				CollColumn.Icon, null,
				CollColumn.Name, "<b>Collections</b>",
				-1
			);

			store.insert_with_values(
				ref iter, null, pos++,
				CollColumn.Type, CollectionType.Invalid,
				CollColumn.Icon, null,
				CollColumn.Name, "<b>Playlists</b>",
				-1
			);

			return store;
		}
	}
}
