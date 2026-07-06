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
	/** A single row in the playlist, exposed as bindable GObject properties. */
	public class PlaylistItem : GLib.Object {
		public enum Status {
			UNRESOLVED,
			RESOLVING,
			RESOLVED
		}

		public Status status { get; set; default = Status.UNRESOLVED; }
		public uint id { get; construct; }
		public string position_indicator { get; set; default = ""; }
		public bool available { get; set; default = true; }
		public string artist { get; set; default = ""; }
		public string album { get; set; default = ""; }
		public string genre { get; set; default = ""; }
		public string info { get; set; default = "\n"; }

		public PlaylistItem (uint id) {
			Object (id: id);
		}
	}

	public class PlaylistModel : GLib.Object {
		/** GtkColumnView-facing list model (GLib.ListStore is final, so we wrap it) */
		public GLib.ListStore store { get; private set; }

		/** current playing position, or -1 */
		private int position = -1;

		/** map medialib id -> rows carrying it (a mid may appear many times) */
		private Gee.MultiMap<uint,PlaylistItem> id_map =
			new Gee.HashMultiMap<uint,PlaylistItem>();

		private Client client;

		private MetadataRequestor requestor;

		public PlaylistModel (Client _client, MetadataResolver resolver) {
			store = new GLib.ListStore (typeof (PlaylistItem));

			string[] attributes = {
				"status",
				"album",
				"genre",
				"title",
				"artist",
				"duration",
				"url"
			};

			requestor = resolver.register(on_resolver_complete);
			requestor.set_attributes(attributes);

			client = _client;

			client.playlist_loaded.connect(on_playlist_loaded);

			client.playlist_add.connect(on_playlist_add);
			client.playlist_move.connect(on_playlist_move);
			client.playlist_insert.connect(on_playlist_insert);
			client.playlist_remove.connect(on_playlist_remove);
			client.playlist_position.connect(on_playlist_position);

			client.playback_status.connect(on_playback_status);

			client.medialib_entry_changed.connect((c, res) => {
				on_medialib_info(res.propdict_to_dict());
			});
		}

		private PlaylistItem? item_at (uint position) {
			return store.get_item(position) as PlaylistItem;
		}

		/**
		 * Lazily resolve a row's metadata the first time it becomes visible.
		 * Called by the view when it binds a row widget.
		 */
		public void ensure_resolved (PlaylistItem item) {
			if (item.status != PlaylistItem.Status.UNRESOLVED)
				return;
			item.status = PlaylistItem.Status.RESOLVING;
			requestor.resolve((int) item.id);
		}

		private PlaylistItem insert_item (int pos, uint mid) {
			var item = new PlaylistItem(mid);
			if (pos < 0 || pos >= store.get_n_items())
				store.append(item);
			else
				store.insert(pos, item);
			id_map.set(mid, item);
			return item;
		}

		/**
		 * Removes the row when an entry has been removed from the playlist.
		 */
		private void on_playlist_remove(Client c, string playlist, int pos) {
			if (playlist != client.current_playlist)
				return;

			var item = item_at(pos);
			if (item == null)
				return;

			id_map.remove(item.id, item);
			store.remove(pos);
		}


		/**
		 * Move row at pos to npos.
		 */
		private void on_playlist_move(Client c, string playlist, int pos, int npos) {
			if (playlist != client.current_playlist)
				return;

			var item = item_at(pos);
			if (item == null)
				return;

			/* GLib.ListStore has no move; remove and re-insert. */
			store.remove(pos);
			if (npos < 0 || npos >= store.get_n_items())
				store.append(item);
			else
				store.insert(npos, item);
		}


		/**
		 * Update the position indicator to point at the
		 * current playing entry.
		 */
		private void on_playlist_position(Client c, string playlist, uint pos) {
			if (playlist != client.current_playlist)
				return;

			/* Remove the old position indicator */
			if (position >= 0) {
				var old = item_at(position);
				if (old != null)
					old.position_indicator = "";
			}

			position = (int) pos;

			var item = item_at(pos);
			if (item != null) {
				/* Notify the Client of the current medialib id */
				client.current_id = (int) item.id;
				item.position_indicator = "go-next";
			}
		}


		/**
		 * Insert a row when a new entry has been inserted in the playlist.
		 */
		private void on_playlist_insert(Client c, string playlist, uint mid, int pos) {
			if (playlist != client.current_playlist)
				return;

			insert_item(pos, mid);
		}


		/**
		 * Keep track of status so we know what to do when an item has been clicked.
		 */
		private void on_playback_status(Client c, int status) {
			/* Notify the Client of the current medialib id */
			if (position >= 0) {
				var item = item_at(position);
				if (item != null)
					client.current_id = (int) item.id;
			}
		}


		/**
		 * Called when xmms2 has loaded a new playlist, simply requests
		 * the mids of that playlist.
		 */
		private void on_playlist_loaded(Client c, string name) {
			client.xmms.playlist_list_entries(name).notifier_set(
				on_playlist_list_entries
			);
		}


		private void on_playlist_add(Client c, string playlist, uint mid) {
			if (playlist != client.current_playlist)
				return;

			insert_item(-1, mid);
		}


		/**
		 * Refresh the whole playlist.
		 */
		private bool on_playlist_list_entries(Xmms.Value val) {
			id_map.clear();
			store.remove_all();
			position = -1;

			unowned Xmms.ListIter list_iter;
			val.get_list_iter(out list_iter);

			for (list_iter.first(); list_iter.valid(); list_iter.next()) {
				Xmms.Value entry;
				int mid = 0;

				if (!(list_iter.entry(out entry) && entry.get_int(out mid)))
					continue;

				insert_item(-1, mid);
			}

			return true;
		}


		private void on_resolver_complete(Xmms.Value value)
		{
			unowned Xmms.ListIter iter;
			Xmms.Value entry;

			value.get_list_iter(out iter);

			while (iter.entry(out entry)) {
				on_medialib_info(entry);
				iter.next();
			}
		}


		private bool on_medialib_info(Xmms.Value val) {
			string album, title, genre, artist = null;
			string info;
			int status, mid;

			val.dict_entry_get_int("id", out mid);
			val.dict_entry_get_int("status", out status);

			if (!val.dict_entry_get_string("album", out album)) {
				album = _("Unknown");
			}
			if (!val.dict_entry_get_string("genre", out genre)) {
				genre = _("Unknown");
			}

			if (val.dict_entry_get_string("title", out title)) {
				string duration;

				if (!val.dict_entry_get_string("artist", out artist)) {
					artist = _("Unknown");
				}

				if (Transform.normalize_dict(val, "duration", out duration)) {
					info = GLib.Markup.printf_escaped(
						"<b>%s</b> - <small>%s</small>\n" + _("<span size=\"small\" foreground=\"#666666\">by</span> %s <span size=\"small\" foreground=\"#666666\">on</span> %s"),
						title, duration, artist, album
					);
				} else {
					info = GLib.Markup.printf_escaped(
						"<b>%s</b>\n" + _("<span size=\"small\" foreground=\"#666666\">by</span> %s <span size=\"small\" foreground=\"#666666\">on</span> %s"),
						title, artist, album
					);
				}
			} else {
				string duration, url;

				if (!val.dict_entry_get_string("url", out url)) {
					url = _("Unknown");
				}

				if (Transform.duration(val, out duration)) {
					info = GLib.Markup.printf_escaped(
						"<b>%s</b> - <small>%s</small>", url, duration
					);
				} else {
					info = GLib.Markup.printf_escaped(
						"<b>%s</b>", url
					);
				}
			}

			foreach (var item in id_map.get((uint) mid)) {
				item.available = (status != 3);
				item.info = info;
				item.artist = artist;
				item.album = album;
				item.genre = genre;
				item.status = PlaylistItem.Status.RESOLVED;
			}

			return false;
		}
	}
}
