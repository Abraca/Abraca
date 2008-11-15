
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

		/** have we scrolled to current position? */
		private bool _have_scrolled;

		/** keep track of current playlist position */
		private Gtk.TreeRowReference _position = null;

		/** keep track of playlist position <-> medialib id */
		private PlaylistMap playlist_map;


		construct {
			Client c = Client.instance();

			set_column_types(new GLib.Type[8] {
					typeof(int),
					typeof(uint),
					typeof(string),
					typeof(bool),
					typeof(string),
					typeof(string),
					typeof(string),
					typeof(string),
					typeof(string)
			});

			playlist_map = new PlaylistMap();

			c.playlist_loaded += on_playlist_loaded;

			c.playlist_add += on_playlist_add;
			c.playlist_move += on_playlist_move;
			c.playlist_insert += on_playlist_insert;
			c.playlist_remove += on_playlist_remove;
			c.playlist_position += on_playlist_position;

			c.playback_status += on_playback_status;

			c.medialib_entry_changed += (client,res) => {
				on_medialib_info(res);
			};
		}


		/**
		 * When GTK asks for the value of a column, check if the row
		 * has been resolved or not, otherwise resolve it.
		 */
		public void get_value(Gtk.TreeIter iter, int column, ref GLib.Value val) {
			GLib.Value tmp1;

			base.get_value(iter, Column.STATUS, ref tmp1);
			if (((Status)tmp1.get_int()) == Status.UNRESOLVED) {
				Client c = Client.instance();
				GLib.Value tmp2;

				base.get_value(iter, Column.ID, ref tmp2);

				set(iter, Column.STATUS, Status.RESOLVING);

				c.xmms.medialib_get_info(tmp2.get_uint()).notifier_set(
					on_medialib_info
				);
			}

			base.get_value(iter, column, ref val);
		}


		/**
		 * Removes the row when an entry has been removed from the playlist.
		 */
		private void on_playlist_remove(Client c, string playlist, int pos) {
			Gtk.TreePath path;
			Gtk.TreeIter iter;

			if (playlist != c.current_playlist) {
				return;
			}

			path = new Gtk.TreePath.from_indices(pos, -1);
			if (get_iter(out iter, path)) {
				uint mid;

				get(iter, Column.ID, out mid);

				playlist_map.remove(mid, path);
				remove(iter);
			}
		}


		/**
		 * TODO: Move row x to pos y.
		 */
		private void on_playlist_move(Client c, string playlist, int pos, int npos) {
			Gtk.TreeIter iter, niter;
			if (iter_nth_child (out iter, null, pos) &&
			    iter_nth_child(out niter, null, npos)) {
				if (pos < npos) {
					move_after (iter, niter);
				} else {
					move_before (iter, niter);
				}
			}
		}


		/**
		 * Update the position indicator to point at the
		 * current playing entry.
		 */
		private void on_playlist_position(Client c, string playlist, uint pos) {
			Gtk.TreeIter iter;

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
				uint mid;

				/* Notify the Client of the current medialib id */
				get(iter, Column.ID, out mid);
				c.set_playlist_id(mid);

				set(
					iter,
					Column.POSITION_INDICATOR,
					Gtk.STOCK_GO_FORWARD
				);

				path = get_path(iter);

				_position = new Gtk.TreeRowReference(this, path);

				/*
				if (!_have_scrolled) {
					scroll_to_cell(path, null, true, (float) 0.25, (float) 0);
					_have_scrolled = true;
				}
				*/
			}
		}


		/**
		 * Insert a row when a new entry has been inserted in the playlist.
		 */
		private void on_playlist_insert(Client c, string playlist, uint mid, int pos) {
			Gtk.TreePath path;
			Gtk.TreeIter iter;

			if (playlist != c.current_playlist) {
				return;
			}

			path = new Gtk.TreePath.from_indices(pos, -1);
			if (get_iter(out iter, path)) {
				Gtk.TreeIter added;

				insert_before (out added, iter);

				set(added, Column.STATUS, Status.UNRESOLVED, Column.ID, mid);

				Gtk.TreePath path = get_path(added);
				Gtk.TreeRowReference row = new Gtk.TreeRowReference(this, path);
				playlist_map.insert(mid, row);
			}
		}


		/**
		 * Keep track of status so we know what to do when an item has been clicked.
		 */
		private void on_playback_status(Client c, int status) {
			/* Notify the Client of the current medialib id */
			if (_position.valid()) {
				Gtk.TreeIter iter;
				uint mid;

				get_iter(out iter, _position.get_path());
				get(iter, Column.ID, out mid);

				c.set_playlist_id(mid);
			}
		}


		/**
		 * Called when xmms2 has loaded a new playlist, simply requests
		 * the mids of that playlist.
		 */
		private void on_playlist_loaded(Client c, string name) {
			_have_scrolled = false;

			c.xmms.playlist_list_entries(name).notifier_set(
				on_playlist_list_entries
			);
		}


		private void on_playlist_add(Client c, string playlist, uint mid) {
			Gtk.TreeRowReference row;
			Gtk.TreePath path;
			Gtk.TreeIter iter;

			if (playlist != c.current_playlist) {
				return;
			}

			append(out iter);
			set(iter, Column.STATUS, Status.UNRESOLVED, Column.ID, mid);

			path = get_path(iter);
			row = new Gtk.TreeRowReference(this, path);

			playlist_map.insert(mid, row);
		}


		/**
		 * Refresh the whole playlist.
		 */
		private void on_playlist_list_entries(Xmms.Result #res) {
			Client c = Client.instance();
			Gtk.TreeIter iter, sibling;
			bool first = true;

			playlist_map.clear();
			clear();

			/* disconnect our model while the shit hits the fan */
			/*
			set_model(null);
			*/

			for (res.list_first(); res.list_valid(); res.list_next()) {
				Gtk.TreeRowReference row;
				Gtk.TreePath path;
				uint mid;
				int pos;

				if (!res.get_uint(out mid))
					continue;

				if (first) {
					insert_after(out iter, null);
					first = !first;
				} else {
					insert_after(out iter, sibling);
				}

				set(iter, Column.STATUS, Status.UNRESOLVED, Column.ID, mid);

				sibling = iter;

				path = get_path(iter);
				row = new Gtk.TreeRowReference(this, path);

				playlist_map.insert(mid, row);
			}

			/* reconnect the model again */
			/*
			set_model(ore);
			*/
		}


		private void on_medialib_info(Xmms.Result #res) {
			weak GLib.SList<Gtk.TreeRowReference> lst;
			weak string artist, album, title, genre;
			int pos, id, status;
			string info;
			int mid;

			res.get_dict_entry_int("id", out mid);

			lst = playlist_map.lookup(mid);
			if (lst == null) {
				// the given mid doesn't match any of our rows 
				return;
			}

			res.get_dict_entry_int("status", out status);

			if (!res.get_dict_entry_string("album", out album)) {
				album = _("Unknown");
			}
			if (!res.get_dict_entry_string("genre", out genre)) {
				genre = _("Unknown");
			}

			if (res.get_dict_entry_string("title", out title)) {
				string duration;

				if (!res.get_dict_entry_string("artist", out artist)) {
					artist = _("Unknown");
				}

				if (Client.transform_duration(res, out duration)) {
					info = GLib.Markup.printf_escaped(
						_("<b>%s</b> - <small>%s</small>\n" +
						"<small>by</small> %s <small>from</small> %s"),
						title, duration, artist, album
					);
				} else {
					info = GLib.Markup.printf_escaped(
						_("<b>%s</b>\n" +
						"<small>by</small> %s <small>from</small> %s"),
						title, artist, album
					);
				}
			} else {
				weak string url;
				string duration;

				res.get_dict_entry_string("url", out url);

				if (Client.transform_duration(res, out duration)) {
					info = GLib.Markup.printf_escaped(
						_("<b>%s</b> - <small>%s</small>"),
						url, duration
					);
				} else {
					info = GLib.Markup.printf_escaped(
						_("<b>%s</b>"),
						url
					);
				}
			}


			foreach (weak Gtk.TreeRowReference row in lst) {
				Gtk.TreePath path;
				Gtk.TreeIter iter;

				path = row.get_path();

				if (!row.valid() || !get_iter(out iter, path)) {
					GLib.stdout.printf("row not valid\n");
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
		}
	}
}
