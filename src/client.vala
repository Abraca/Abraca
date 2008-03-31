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

namespace Abraca {
	public class Client : GLib.Object {
		static Client _instance;
		private Xmms.Client _xmms;
		private pointer _gmain;

		private uint _status;
		private string _playlist = null;

		public signal void connected();
		public signal void disconnected();

		public signal void playback_status(int status);
		public signal void playback_current_id(uint mid);
		public signal void playback_playtime(uint pos);
		public signal void playlist_loaded(string name);

		public signal void playlist_add(weak string playlist, uint mid);
		public signal void playlist_move(weak string playlist, int pos, int npos);
		public signal void playlist_insert(weak string playlist, uint mid, int pos);
		public signal void playlist_remove(weak string playlist, int pos);
		public signal void playlist_position(weak string playlist, uint pos);

		public signal void collection_add(weak string name, weak string ns);
		public signal void collection_update(weak string name, weak string ns);
		public signal void collection_rename(weak string name, weak string newname, weak string ns);
		public signal void collection_remove(weak string name, weak string ns);

		public signal void media_info(GLib.HashTable<string,pointer> hash);

		private Xmms.Result _result_playback_status;
		private Xmms.Result _result_playback_current_id;
		private Xmms.Result _result_medialib_entry_changed;
		private Xmms.Result _result_playlist_loaded;
		private Xmms.Result _result_playlist_changed;
		private Xmms.Result _result_playlist_position;

		private Xmms.Result _result_collection_changed;

		construct {
			_xmms = new Xmms.Client("Abraca");
		}

		private void on_disconnect() {
			disconnected();

			_result_playback_status = null;
			_result_playback_current_id = null;
			_result_medialib_entry_changed = null;
			_result_playlist_loaded = null;
			_result_playlist_changed = null;
			_result_playlist_position = null;
			_result_collection_changed = null;

			GLib.Timeout.add(500, reconnect);

			Xmms.MainLoop.GMain.shutdown(_xmms, _gmain);
		}

		public static Client instance() {
			if (_instance == null)
				_instance = new Client();

			return _instance;
		}

		public Xmms.Client xmms {
			get {
				return _xmms;
			}
		}

		public void set_playlist_id (uint mid) {
			if (_status == Xmms.PlaybackStatus.STOP) {
				playback_current_id(mid);
			}
		}

		public bool try_connect(string path = null) {
			if (path == null) {
				path = GLib.Environment.get_variable("XMMS_PATH");
			}

			if (_xmms.connect(path)) {
				_gmain = Xmms.MainLoop.GMain.init(_xmms);
				_xmms.disconnect_callback_set(on_disconnect);
				create_callbacks();

				connected();

				return true;
			}

			return false;
		}

		private bool reconnect() {
			return !try_connect();
		}

		private void create_callbacks() {
			_xmms.playback_status().notifier_set(
				on_playback_status
			);

			_xmms.broadcast_playback_status().notifier_set(
				on_playback_status
			);

			_xmms.playback_current_id().notifier_set(
				on_playback_current_id
			);

			_xmms.broadcast_playback_current_id().notifier_set(
				on_playback_current_id
			);

			_xmms.playback_playtime().notifier_set(
				on_playback_playtime
			);

			_xmms.signal_playback_playtime().notifier_set(
				on_playback_playtime
			);

			_xmms.playlist_current_active().notifier_set(
				on_playlist_loaded
			);

			_xmms.broadcast_playlist_loaded().notifier_set(
				on_playlist_loaded
			);

			_xmms.broadcast_playlist_changed().notifier_set(
				on_playlist_changed
			);

			_xmms.broadcast_collection_changed().notifier_set(
				on_collection_changed
			);

			_xmms.broadcast_medialib_entry_changed().notifier_set(
				on_medialib_entry_changed
			);

			_xmms.broadcast_playlist_current_pos().notifier_set(
				on_playlist_position
			);
		}

		[InstanceLast]
		private void on_playback_status(Xmms.Result #res) {
			if (res.get_uint(out _status)) {
				playback_status((int) _status);
			}

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				_result_playback_status = res;
				_result_playback_status.ref();
			}
		}

		[InstanceLast]
		private void on_playback_current_id(Xmms.Result #res) {
			uint mid;

			if (res.get_uint(out mid)) {
				playback_current_id(mid);
			}

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				_result_playback_current_id = res;
				_result_playback_current_id.ref();
			}
		}

		/**
		 * Emit the current playback position in ms.
		 */
		[InstanceLast]
		private void on_playback_playtime(Xmms.Result #res) {
			uint pos;

			if (res.get_uint(out pos)) {
				playback_playtime(pos);
			}

			if (res.get_class() == Xmms.ResultClass.SIGNAL) {
				res.restart();
			}
		}

		[InstanceLast]
		private void on_playlist_loaded(Xmms.Result #res) {
			weak string name;

			if (res.get_string(out name)) {
				_playlist = name;
				playlist_loaded(name);

				_xmms.playlist_current_pos (name).notifier_set(
					on_playlist_position
				);
			}

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				_result_playlist_loaded = res;
				_result_playlist_loaded.ref();
			}
		}

		[InstanceLast]
		private void on_playlist_position(Xmms.Result #res) {
			uint pos;

			if (res.get_uint(out pos)) {
				playlist_position(_playlist, pos);
			}

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				_result_playlist_loaded = res;
				_result_playlist_loaded.ref();
			}
		}

		[InstanceLast]
		private void on_playlist_changed(Xmms.Result #res) {
			weak string playlist;
			int change, pos, npos;
			uint mid;

			res.get_dict_entry_int("type", out change);
			res.get_dict_entry_int("position", out pos);
			res.get_dict_entry_int("newposition", out npos);
			res.get_dict_entry_uint("id", out mid);
			res.get_dict_entry_string("name", out playlist);

			switch (change) {
				case Xmms.PlaylistChange.ADD:
					playlist_add(playlist, mid);
					break;
				case Xmms.PlaylistChange.INSERT:
					playlist_insert(playlist, mid, pos);
					break;
				case Xmms.PlaylistChange.REMOVE:
					playlist_remove(playlist, pos);
					break;
				case Xmms.PlaylistChange.MOVE:
					playlist_move(playlist, pos, npos);
					break;
				case Xmms.PlaylistChange.UPDATE:
				case Xmms.PlaylistChange.CLEAR:
				case Xmms.PlaylistChange.SHUFFLE:
				case Xmms.PlaylistChange.SORT:
					xmms.playlist_current_active().notifier_set(
						on_playlist_loaded
					);
					break;
				default:
					break;
			}

			_result_playlist_changed = res;
			_result_playlist_changed.ref();
		}

		[InstanceLast]
		private void on_collection_changed(Xmms.Result #res) {
			int change;
			weak string name, newname, ns;

			res.get_dict_entry_string("name", out name);
			res.get_dict_entry_string("namespace", out ns);
			res.get_dict_entry_int("type", out change);

			switch (change) {
				case Xmms.CollectionChanged.ADD:
					collection_add(name, ns);
					break;
				case Xmms.CollectionChanged.UPDATE:
					collection_update(name, ns);
					break;
				case Xmms.CollectionChanged.RENAME:
					res.get_dict_entry_string("newname", out newname);
					collection_rename(name, newname, ns);
					break;
				case Xmms.CollectionChanged.REMOVE:
					collection_remove(name, ns);
					break;
				default:
					break;
			}

			_result_collection_changed = res;
			_result_collection_changed.ref();
		}
		/**
		 * TODO: Lookup in cache and return if found instead of requesting.
		 */
		public void get_media_info(uint mid, weak string[] keys) {
			xmms.medialib_get_info(mid).notifier_set(
				on_medialib_get_info
			);
		}

		[InstanceLast]
		public void on_medialib_entry_changed(Xmms.Result #res) {
			uint mid;

			if (res.get_uint(out mid)) {
				_xmms.medialib_get_info(mid).notifier_set(
					on_medialib_get_info
				);
			}

			_result_medialib_entry_changed = res;
			_result_medialib_entry_changed.ref();
		}

		/**
		 * TODO: Update cache here.
		 */
		[InstanceLast]
		private void on_medialib_get_info(Xmms.Result #res) {
			weak string tmp;
			int mid, duration;

			if (!res.get_dict_entry_int("id", out mid)) {
				return;
			}

			/* TODO: Dispatch as a hash so the delegate can handle
			 *       both stuff from here, and stuff from cache hits.
			 */
			GLib.HashTable<string,pointer> m =
				new GLib.HashTable<string,pointer>(GLib.str_hash, GLib.str_equal);

			m.insert("id", mid.to_pointer());

			if (!res.get_dict_entry_string("artist", out tmp)) {
				tmp = "Unknown";
			}
			m.insert("artist", (pointer) tmp);

			if (!res.get_dict_entry_string("album", out tmp)) {
				tmp = "Unknown";
			}
			m.insert("album", (pointer) tmp);

			if (!res.get_dict_entry_string("genre", out tmp)) {
				tmp = "Unknown";
			}
			m.insert("genre", (pointer) tmp);

			if (!res.get_dict_entry_string("title", out tmp)) {
				tmp = "Unknown";
			}
			m.insert("title", (pointer) tmp);

			if (!res.get_dict_entry_int("duration", out duration)) {
				duration = 0;
			}
			m.insert("duration", duration.to_pointer());

			media_info(m);

			/* destroy hashtable properly here */

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				/* does this ever happen? */
				GLib.stdout.printf("this probably never happens, to be removed?\n");
				res.ref();
			}
		}
	}
}
