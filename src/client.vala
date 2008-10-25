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
	public class Client : GLib.Object {
		static Client _instance;
		private Xmms.Client _xmms;
		private void *_gmain;

		public signal void connected();
		public signal void disconnected();

		public signal void playback_status(int status);
		public signal void playback_current_id(uint mid);
		public signal void playback_playtime(uint pos);
		public signal void playback_volume(Xmms.Result res);

		public signal void playlist_loaded(string name);
		public signal void playlist_add(string playlist, uint mid);
		public signal void playlist_move(string playlist, int pos, int npos);
		public signal void playlist_insert(string playlist, uint mid, int pos);
		public signal void playlist_remove(string playlist, int pos);
		public signal void playlist_position(string playlist, uint pos);

		public signal void collection_add(string name, string ns);
		public signal void collection_update(string name, string ns);
		public signal void collection_rename(string name, string newname, string ns);
		public signal void collection_remove(string name, string ns);

		public signal void medialib_entry_changed(Xmms.Result res);

		public signal void configval_changed(string key, string val);

		private Xmms.Result _result_playback_status;
		private Xmms.Result _result_playback_current_id;
		private Xmms.Result _result_medialib_entry_changed;
		private Xmms.Result _result_playback_volume;
		private Xmms.Result _result_playlist_loaded;
		private Xmms.Result _result_playlist_changed;
		private Xmms.Result _result_playlist_position;

		private Xmms.Result _result_collection_changed;

		private Xmms.Result _result_configval_changed;

		/** current playback status */
		public int current_playback_status {
			get; set; default = Xmms.PlaybackStatus.STOP;
		}

		/** current playlist displayed */
		public string current_playlist {
			get; set; default = "";
		}


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
			_result_configval_changed = null;

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
			if (current_playback_status == Xmms.PlaybackStatus.STOP) {
				playback_current_id(mid);
			}
		}


		public bool try_connect(string? path = null) {
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


		public bool reconnect() {
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

			_xmms.playback_volume_get().notifier_set(
				on_playback_volume
			);
			_xmms.broadcast_playback_volume_changed().notifier_set(
				on_playback_volume
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

			_xmms.broadcast_configval_changed().notifier_set(
					on_configval_changed
			);
		}


		private void on_playback_status(Xmms.Result #res) {
			uint status;
			if (res.get_uint(out status)) {
				playback_status((int) status);
				current_playback_status = status;
			}

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				_result_playback_status = res;
				_result_playback_status.ref();
			}
		}


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
		private void on_playback_playtime(Xmms.Result #res) {
			uint pos;

			if (res.get_uint(out pos)) {
				playback_playtime(pos);
			}

			if (res.get_class() == Xmms.ResultClass.SIGNAL) {
				res.restart();
			}
		}

		private void on_playback_volume(Xmms.Result #res) {

			playback_volume(res);

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				_result_playback_volume = res;
				_result_playback_volume.ref();
			}
		}

		private void on_playlist_loaded(Xmms.Result #res) {
			weak string name;

			if (res.get_string(out name)) {
				current_playlist = name;

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


		private void on_playlist_position(Xmms.Result #res) {
			uint pos;

			if (res.get_type() == Xmms.ResultType.DICT) {
				weak string name;

				res.get_dict_entry_uint("position", out pos);
				res.get_dict_entry_string("name", out name);

				playlist_position(name, pos);
			} else {
				res.get_uint(out pos);

				playlist_position(current_playlist, pos);
			}

			if (res.get_class() != Xmms.ResultClass.DEFAULT) {
				_result_playlist_loaded = res;
				_result_playlist_loaded.ref();
			}
		}


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


		private void on_collection_changed(Xmms.Result #res) {
			weak string name, newname, ns;
			int change;

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
					if (name == current_playlist) {
						current_playlist = newname;
					}
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


		private void on_medialib_get_info(Xmms.Result #res) {
			if (!res.iserror()) {
				medialib_entry_changed(res);
			}
		}

		public static bool collection_needs_quoting (string str) {
			bool ret = false;
			bool numeric = true;

			for(int i = 0; i < str.len(); i++) {
				switch(str[i]) {
					case ' ':
					case '\\':
					case '\"':
					case '\'':
					case '(':
					case ')':
							ret = true;
							break;
					case '0':
					case '1':
					case '2':
					case '3':
					case '4':
					case '5':
					case '6':
					case '7':
					case '8':
					case '9':
							break;
					default:
							numeric = false;
							break;
				}
			}

			return ret || numeric;
		}

		private void on_configval_changed_dict_each(void *key, Xmms.ResultType type,
		                                            void *val) {
			configval_changed((string) key, (string) val);
		}

		private void on_configval_changed(Xmms.Result #res) {
			res.dict_foreach(on_configval_changed_dict_each);

			_result_configval_changed = res;
			_result_configval_changed.ref();
		}


		/** Here comes default Xmms.Result filters, need a good place to live... */
		public static bool transform_duration (Xmms.Result res, out string result)
		{
			int dur_sec, dur_min, duration;

			if (!res.get_dict_entry_int("duration", out duration)) {
				return false;
			}

			dur_min = duration / 60000;
			dur_sec = (duration % 60000) / 1000;

			result = "%d:%02d".printf(dur_min, dur_sec);

			return true;
		}

		public static bool transform_bitrate (Xmms.Result res, out string result)
		{
			int bitrate;

			if (!res.get_dict_entry_int("bitrate", out bitrate)) {
				return false;
			}

			result = "%.1f kbps".printf(bitrate / 1000.0 );

			return true;
		}

		public static bool transform_date (Xmms.Result res, string key, out string result)
		{
			GLib.TimeVal time;
			int unxtime;

			if (!res.get_dict_entry_int(key, out unxtime)) {
				return false;
			}

			time.tv_sec = unxtime;
			result = time.to_iso8601();

			return true;
		}

		public static bool transform_generic (Xmms.Result res, string key, out string repr)
		{
			switch (res.get_dict_entry_type(key)) {
				case Xmms.ResultType.INT32:
					int tmp;
					if (!res.get_dict_entry_int(key, out tmp)) {
						return false;
					}
					repr = "%d".printf(tmp);
					break;
				case Xmms.ResultType.UINT32:
					uint tmp;
					if (!res.get_dict_entry_uint(key, out tmp)) {
						return false;
					}
					repr = "%u".printf(tmp);
					break;
				case Xmms.ResultType.STRING:
					if (!res.get_dict_entry_string(key, out repr)) {
						return false;
					}
					repr = "%s".printf(repr);
					break;
				default:
					return false;
			}

			return true;
		}
	}
}
