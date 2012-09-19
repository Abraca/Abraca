/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2012 Abraca Team
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
using Gee;

namespace Abraca {
	public class Client : GLib.Object {
		private Xmms.Client _xmms = null;
		private void *_gmain = null;

		public enum ConnectionState
		{
			Disconnected,
			Connecting,
			Connected
		}


		public signal void connection_state_changed (ConnectionState state);

		public signal void playback_status(int status);
		public signal void playback_current_id(int mid);
		public signal void playback_playtime(int pos);
		public signal void playback_volume(Xmms.Value res);

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

		public signal void medialib_entry_changed(Xmms.Value res);

		public signal void configval_changed(string key, string val);

		private Gee.List<Xmms.Result> _recallable_references = new LinkedList<Xmms.Result>();

		/** current playback status */
		public int current_playback_status {
			get; set; default = Xmms.PlaybackStatus.STOP;
		}

		/** current playlist displayed */
		public string current_playlist {
			get; set; default = "";
		}

		public const string[] source_preferences = {
			"server",
			"client/*",
			"plugin/id3v2",
			"plugin/segment",
			"plugin/*",
			"*"
		};


		public Xmms.Client xmms {
			get {
				return _xmms;
			}
		}


		public void set_playlist_id (int mid) {
			if (current_playback_status == Xmms.PlaybackStatus.STOP) {
				playback_current_id(mid);
			}
		}


		public bool try_connect(string? path = null) {
			if (path == null) {
				path = GLib.Environment.get_variable("XMMS_PATH");
			}

			var next_client = new Xmms.Client("Abraca");

			connection_state_changed (ConnectionState.Connecting);

			if (next_client.connect(path)) {
				detach_callbacks();

				if (_gmain != null)
					Xmms.MainLoop.GMain.shutdown(_xmms, _gmain);

				_xmms = next_client;
				_gmain = Xmms.MainLoop.GMain.init(_xmms);

				_xmms.disconnect_callback_set(() => {
					connection_state_changed (ConnectionState.Disconnected);
				});

				attach_callbacks();

				connection_state_changed (ConnectionState.Connected);

				return true;
			}

			/* Connection failed, using the already established one */
			if (_xmms != null) {
				connection_state_changed (ConnectionState.Connected);
			}

			return false;
		}

		/**
		 * Try to connect to xmms2d.
		 * On failure xmms2d will be launched unless an explicit
		 * XMMS_PATH has been defined.
		 *
		 * @return true if a new reconnect should be attempted
		 */
		public bool reconnect() {
			var path = GLib.Environment.get_variable("XMMS_PATH");

			if (try_connect(path)) {
				return false;
			}

			if (path != null) {
				// Leaving early as XMMS_PATH was explicitly set
				return true;
			}

			string stdout, stderr;

			try {
				GLib.Process.spawn_command_line_sync("xmms2-launcher", out stdout, out stderr, null);
			} catch (SpawnError e) {
				GLib.warning("Unable to spawn 'xmms2-launcher' (%s)", e.message);
			}

			return true;
		}

		private void detach_callbacks() {
			while (!_recallable_references.is_empty) {
				var result = _recallable_references.remove_at(0);
				result.disconnect();
			}
		}

		private void attach_callbacks() {
			Xmms.Result recallable;

			_xmms.playback_status().notifier_set(
				on_playback_status
			);

			recallable = _xmms.broadcast_playback_status();
			recallable.notifier_set(
				on_playback_status
			);
			_recallable_references.add(recallable);

			_xmms.playback_current_id().notifier_set(
				on_playback_current_id
			);

			recallable = _xmms.broadcast_playback_current_id();
			recallable.notifier_set(
				on_playback_current_id
			);
			_recallable_references.add(recallable);


			_xmms.playback_playtime().notifier_set(
				on_playback_playtime
			);

			recallable = _xmms.signal_playback_playtime();
			recallable.notifier_set(
				on_playback_playtime
			);
			_recallable_references.add(recallable);

			_xmms.playback_volume_get().notifier_set(
				on_playback_volume
			);

			recallable = _xmms.broadcast_playback_volume_changed();
			recallable.notifier_set(
				on_playback_volume
			);
			_recallable_references.add(recallable);

			_xmms.playlist_current_active().notifier_set(
				on_playlist_loaded
			);

			recallable = _xmms.broadcast_playlist_loaded();
			recallable.notifier_set(
				on_playlist_loaded
			);
			_recallable_references.add(recallable);

			recallable = _xmms.broadcast_playlist_changed();
			recallable.notifier_set(
				on_playlist_changed
			);
			_recallable_references.add(recallable);

			recallable = _xmms.broadcast_collection_changed();
			recallable.notifier_set(
				on_collection_changed
			);
			_recallable_references.add(recallable);

			recallable = _xmms.broadcast_medialib_entry_changed();
			recallable.notifier_set(
				on_medialib_entry_changed
			);
			_recallable_references.add(recallable);

			recallable = _xmms.broadcast_playlist_current_pos();
			recallable.notifier_set(
				on_playlist_position
			);
			_recallable_references.add(recallable);

			_xmms.config_list_values().notifier_set(
				on_configval_changed
			);

			recallable = _xmms.broadcast_config_value_changed();
			recallable.notifier_set(
					on_configval_changed
			);
			_recallable_references.add(recallable);
		}

		private bool on_playback_status(Xmms.Value val) {
			int status;
			if (val.get_int(out status)) {
				playback_status(status);
				current_playback_status = status;
			}

			return true;
		}


		private bool on_playback_current_id(Xmms.Value val) {
			int mid;

			if (val.get_int(out mid)) {
				playback_current_id(mid);
			}

			return true;
		}


		/**
		 * Emit the current playback position in ms.
		 */
		private bool on_playback_playtime(Xmms.Value val) {
			int pos;

			if (val.get_int(out pos)) {
				playback_playtime(pos);
			}

			return true;
		}

		private bool on_playback_volume(Xmms.Value val) {
			playback_volume(val);

			return true;
		}

		private bool on_playlist_loaded(Xmms.Value val) {
			unowned string name;

			if (val.get_string(out name)) {
				current_playlist = name;

				playlist_loaded(name);

				_xmms.playlist_current_pos (name).notifier_set(
					on_playlist_position
				);
			}
			return true;
		}


		private bool on_playlist_position(Xmms.Value val) {
			int pos;

			if (val.is_type(Xmms.ValueType.DICT)) {
				string name;
				if (!val.dict_entry_get_int("position", out pos))
					return true;
				if (!val.dict_entry_get_string("name", out name))
					return true;
				playlist_position(name, pos);
			} else {
				if (!val.get_int(out pos))
					return true;
				playlist_position(current_playlist, pos);
			}

			return true;
		}


		private bool on_playlist_changed(Xmms.Value val) {
			string playlist;
			int mid, change, pos, npos;
			bool tmp;

			tmp = val.dict_entry_get_int("type", out change);
			tmp = val.dict_entry_get_int("position", out pos);
			tmp = val.dict_entry_get_int("newposition", out npos);
			tmp = val.dict_entry_get_int("id", out mid);
			tmp = val.dict_entry_get_string("name", out playlist);

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
					/* not really interesting */
					break;
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

			return true;
		}


		private bool on_collection_changed(Xmms.Value val) {
			string name, newname, ns;
			int change;
			bool tmp;

			tmp = val.dict_entry_get_string("name", out name);
			tmp = val.dict_entry_get_string("namespace", out ns);
			tmp = val.dict_entry_get_int("type", out change);

			switch (change) {
				case Xmms.CollectionChanged.ADD:
					collection_add(name, ns);
					break;
				case Xmms.CollectionChanged.UPDATE:
					collection_update(name, ns);
					break;
				case Xmms.CollectionChanged.RENAME:
					if (val.dict_entry_get_string("newname", out newname)) {
						if (name == current_playlist) {
							current_playlist = newname;
						}
						collection_rename(name, newname, ns);
					}
					break;
				case Xmms.CollectionChanged.REMOVE:
					collection_remove(name, ns);
					break;
				default:
					break;
			}

			return true;
		}


		public bool on_medialib_entry_changed(Xmms.Value val) {
			int mid;

			if (val.get_int(out mid)) {
				_xmms.medialib_get_info(mid).notifier_set(
					on_medialib_get_info
				);
			}
			return true;
		}


		private bool on_medialib_get_info(Xmms.Value val) {
			if (!val.is_error()) {
				medialib_entry_changed(val);
			}
			return true;
		}

		public static bool collection_needs_quoting (string str) {
			bool ret = false;
			bool numeric = true;

			for(int i = 0; i < str.length; i++) {
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

		private void on_configval_changed_foreach(string key, Xmms.Value val) {
			string cfg_value;
			if (val.get_string(out cfg_value)) {
				configval_changed(key, cfg_value);
			}
		}

		private bool on_configval_changed(Xmms.Value val) {
			val.dict_foreach(on_configval_changed_foreach);
			return true;
		}
	}
}
