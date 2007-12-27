/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;
using Gtk;

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

			store.set_data("collections_parent", store.get_path(ref iter));

			store.insert_with_values(
				ref iter, null, pos++,
				CollColumn.Type, CollectionType.Invalid,
				CollColumn.Icon, null,
				CollColumn.Name, "<b>Playlists</b>",
				-1
			);

			store.set_data("playlists_parent", store.get_path(ref iter));

			return store;
		}
	}
}
