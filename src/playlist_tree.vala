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
		private int _status;

		construct {
			Client c = Client.instance();

			enable_search = true;
			search_column = 1;
			headers_visible = false;
			show_expanders = false;
			rules_hint = true;

			create_columns ();

			model = new Gtk.ListStore(
				PlaylistColumn.Total,
				typeof(int), typeof(string), typeof(string)
			);
			row_activated += on_row_activated;

			c.playlist_loaded += on_playlist_loaded;
			c.playlist_add += on_playlist_add;
			c.playback_status += on_playback_status;

			show_all();

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


		[InstanceLast]
		private void on_row_activated(
			Gtk.TreeView tree, Gtk.TreePath path,
			Gtk.TreeViewColumn column
		) {
			Client c = Client.instance();
			int pos = path.to_string().to_int();

			c.xmms.playlist_set_next(pos);
			c.xmms.playback_tickle();

			if (_status != Xmms.PlaybackStatus.PLAY) {
				c.xmms.playback_start();
			}
		}

		private void on_playback_status(Client c, int status) {
			_status = status;
		}

		private void on_playlist_loaded(Client c, string name) {
			c.xmms.playlist_list_entries(name).notifier_set(
				on_playlist_list_entries, this
			);
		}

		private void on_playlist_add(Client c, uint mid) {
			c.xmms.medialib_get_info(mid).notifier_set(
				on_medialib_get_info, this
			);
		}

		[InstanceLast]
		private void on_playlist_list_entries(Xmms.Result res) {
			Client c = Client.instance();
			Gtk.ListStore store = (Gtk.ListStore) model;

			store.clear();

			for (res.list_first(); res.list_valid(); res.list_next()) {
				uint id;

				if (!res.get_uint(out id))
					continue;

				c.xmms.medialib_get_info(id).notifier_set(
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

			res.get_dict_entry_int("id", out id);
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
	}
}
