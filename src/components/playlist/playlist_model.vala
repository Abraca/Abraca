/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2010  Abraca Team
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
	public class PlaylistModel : Gtk.ListStore, Gtk.TreeModel {
		/* Metadata resolve status */
		private enum Status {
			UNRESOLVED,
			RESOLVING,
			RESOLVED
		}

		public enum Column {
			STATUS,
			ID,
			POSITION_INDICATOR,
			AVAILABLE,
			ARTIST,
			ALBUM,
			GENRE,
			INFO
		}

		/** keep track of current playlist position */
		private Gtk.TreeRowReference _position = null;

		/** keep track of playlist position <-> medialib id */
		private TreeRowMap playlist_map;

		private Client client;

		private GLib.Type[] _types = new GLib.Type[] {
			typeof(int),
			typeof(uint),
			typeof(string),
			typeof(bool),
			typeof(string),
			typeof(string),
			typeof(string),
			typeof(string),
			typeof(string)
		};

		public PlaylistModel (Client _client) {
			set_column_types(_types);

			playlist_map = new TreeRowMap(this);

			client = _client;

			client.playlist_loaded.connect(on_playlist_loaded);

			client.playlist_add.connect(on_playlist_add);
			client.playlist_move.connect(on_playlist_move);
			client.playlist_insert.connect(on_playlist_insert);
			client.playlist_remove.connect(on_playlist_remove);
			client.playlist_position.connect(on_playlist_position);

			client.playback_status.connect(on_playback_status);

			client.medialib_entry_changed.connect((c, res) => {
				on_medialib_info(res);
			});
		}

		/**
		 * When GTK asks for the value of a column, check if the row
		 * has been resolved or not, otherwise resolve it.
		 */
		public void get_value(Gtk.TreeIter iter, int column, ref GLib.Value val) {
			GLib.Value status;

			base.get_value(iter, Column.STATUS, out status);
			if (status.get_int() == Status.UNRESOLVED) {
				GLib.Value mid;

				base.get_value(iter, Column.ID, out mid);

				set(iter, Column.STATUS, Status.RESOLVING);

				client.xmms.medialib_get_info(mid.get_uint()).notifier_set(
					on_medialib_info
				);
			}

			base.get_value(iter, column, out val);
		}


		/**
		 * Removes the row when an entry has been removed from the playlist.
		 */
		private void on_playlist_remove(Client c, string playlist, int pos) {
			Gtk.TreePath path;
			Gtk.TreeIter iter;

			if (playlist != client.current_playlist) {
				return;
			}

			path = new Gtk.TreePath.from_indices(pos, -1);
			if (get_iter(out iter, path)) {
				uint mid;

				get(iter, Column.ID, out mid);

				playlist_map.remove_path((int) mid, path);
				remove(iter);
			}
		}


		/**
		 * TODO: Move row x to pos y.
		 */
		private void on_playlist_move(Client c, string playlist, int pos, int npos) {
			Gtk.TreeIter? niter = null;
			Gtk.TreeIter iter;

			if (playlist != client.current_playlist) {
				return;
			}

			if (!iter_nth_child (out iter, null, pos))
				return;

			if (!iter_nth_child (out niter, null, npos))
				return;

			if (pos < npos)
				move_after (ref iter, niter);
			else
				move_before (ref iter, niter);
		}


		/**
		 * Update the position indicator to point at the
		 * current playing entry.
		 */
		private void on_playlist_position(Client c, string playlist, uint pos) {
			Gtk.TreeIter iter;

			if (playlist != client.current_playlist) {
				return;
			}

			/* Remove the old position indicator */
			if (_position.valid()) {
				get_iter(out iter, _position.get_path());
				set(iter, Column.POSITION_INDICATOR, 0);
			}

			/* Playlist is probably empty */
			if (pos < 0)
				return;

			/* Add the new position indicator */
			if (iter_nth_child (out iter, null, (int) pos)) {
				Gtk.TreePath path;
				int mid;

				/* Notify the Client of the current medialib id */
				get(iter, Column.ID, out mid);
				client.set_playlist_id(mid);

				set(
					iter,
					Column.POSITION_INDICATOR,
					Gtk.Stock.GO_FORWARD
				);

				path = get_path(iter);

				_position = new Gtk.TreeRowReference(this, path);
			}
		}


		/**
		 * Insert a row when a new entry has been inserted in the playlist.
		 */
		private void on_playlist_insert(Client c, string playlist, uint mid, int pos) {
			Gtk.TreeIter iter, sibling;

			if (playlist != client.current_playlist) {
				return;
			}

			var path = new Gtk.TreePath.from_indices(pos, -1);
			if (get_iter(out sibling, path)) {
				insert_before (out iter, sibling);
			} else {
				// Insert occurred after the last entry, lets append.
				append(out iter);
			}

			set(iter, Column.STATUS, Status.UNRESOLVED, Column.ID, mid);

			playlist_map.add_iter((int) mid, iter);
		}


		/**
		 * Keep track of status so we know what to do when an item has been clicked.
		 */
		private void on_playback_status(Client c, int status) {
			/* Notify the Client of the current medialib id */
			if (_position.valid()) {
				Gtk.TreeIter iter;
				int mid;

				get_iter(out iter, _position.get_path());
				get(iter, Column.ID, out mid);

				client.set_playlist_id(mid);
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
			Gtk.TreeIter iter;

			if (playlist != client.current_playlist) {
				return;
			}

			append(out iter);
			set(iter, Column.STATUS, Status.UNRESOLVED, Column.ID, mid);

			playlist_map.add_iter((int) mid, iter);
		}


		/**
		 * Refresh the whole playlist.
		 */
		private bool on_playlist_list_entries(Xmms.Value val) {
			Gtk.TreeIter? iter, sibling = null;
			bool first = true;

			playlist_map.clear();
			clear();

			/* disconnect our model while the shit hits the fan */
			/*
			set_model(null);
			*/

			unowned Xmms.ListIter list_iter;
			val.get_list_iter(out list_iter);

			for (list_iter.first(); list_iter.valid(); list_iter.next()) {
				Xmms.Value entry;
				int mid = 0;

				if (!(list_iter.entry(out entry) && entry.get_int(out mid)))
					continue;

				if (first) {
					insert_after(out iter, null);
					first = !first;
				} else {
					insert_after(out iter, sibling);
				}

				set(iter, Column.STATUS, Status.UNRESOLVED, Column.ID, mid);

				sibling = iter;

				playlist_map.add_iter(mid, iter);
			}

			/* reconnect the model again */
			/*
			set_model(ore);
			*/

			return true;
		}


		private bool on_medialib_info(Xmms.Value propdict) {
			string album, title, genre, artist = null;
			string info;
			int status, mid;

			Xmms.Value val = propdict.propdict_to_dict();

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
						"<b>%s</b> - <small>%s</small>\n" + _("<small>by</small> %s <small>from</small> %s"),
						title, duration, artist, album
					);
				} else {
					info = GLib.Markup.printf_escaped(
						"<b>%s</b>\n" + _("<small>by</small> %s <small>from</small> %s"),
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

			foreach (var row in playlist_map.get_paths(mid)) {
				Gtk.TreePath path;
				Gtk.TreeIter? iter = null;

				path = row.get_path();

				if (!row.valid() || !get_iter(out iter, path)) {
					continue;
				}

				set(iter,
					Column.AVAILABLE, (bool)(status != 3),
					Column.INFO, info,
					Column.ARTIST, artist,
					Column.ALBUM, album,
					Column.GENRE, genre
				);
			}

			return false;
		}
	}
}
