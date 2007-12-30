/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	enum PlaylistColumn {
		ID = 0,
		CoverArt,
		Info,
		Total
	}

	public class PlaylistTree : Gtk.TreeView {
		construct {
			enable_search = true;
			search_column = 1;
			headers_visible = false;
			show_expanders = false;
			rules_hint = true;

			create_columns ();

			model = new Gtk.ListStore(
				PlaylistColumn.Total,
				typeof(uint), typeof(string), typeof(string)
			);
			show_all();
		}

		public void query_active_playlist() {
			Xmms.Client xmms = Abraca.instance().xmms;

			xmms.playlist_current_active().notifier_set(
				on_playlist_current_active, this
			);
		}

		[InstanceLast]
		private void on_playlist_current_active(Xmms.Result res) {
			Xmms.Client xmms = Abraca.instance().xmms;

			xmms.playlist_list_entries("_active").notifier_set(
				on_playlist_list_entries, this
			);
		}

		[InstanceLast]
		private void on_playlist_list_entries(Xmms.Result res) {
			Xmms.Client xmms = Abraca.instance().xmms;
			Gtk.ListStore store = (Gtk.ListStore) model;

			store.clear();

			for (res.list_first(); res.list_valid(); res.list_next()) {
				uint id;

				if (!res.get_uint(out id))
					continue;

				xmms.medialib_get_info(id).notifier_set(
					on_medialib_get_info, this
				);
			}
		}

		[InstanceLast]
		private void on_medialib_get_info(Xmms.Result res) {
			Gtk.ListStore store = (Gtk.ListStore) model;
			Gtk.TreeIter iter;
			weak string artist, title, album;
			string info;
			uint id;
			int duration, dur_min, dur_sec, pos;

			res.get_dict_entry_uint("id", out id);
			res.get_dict_entry_int("duration", out duration);

			if (!res.get_dict_entry_string("artist", out artist))
				artist = "Unknown";

			if (!res.get_dict_entry_string("title", out title))
				title = "Unknown";

			if (!res.get_dict_entry_string("album", out album))
				album = "Unknown";

			dur_min = duration / 60000;
			dur_sec = (duration % 60000) / 1000;

			info = Markup.printf_escaped(
				"<b>%s</b> - <small>%d:%02d</small>\n" +
				"<small>by</small> %s <small>from</small> %s",
				title, dur_min, dur_sec, artist, album
			);

			pos = store.iter_n_children(null);

			store.insert_with_values(
				ref iter, pos,
				PlaylistColumn.ID, id,
				PlaylistColumn.CoverArt, null,
				PlaylistColumn.Info, info
			);
		}


		private void create_columns() {
 			insert_column_with_attributes(
				-1, null, new Gtk.CellRendererPixbuf(),
				"stock-id", PlaylistColumn.CoverArt, null
			);

 			insert_column_with_attributes(
				-1, null, new Gtk.CellRendererText(),
				"markup", PlaylistColumn.Info, null
			);
		}
	}
}
