namespace Abraca {
	public class Client : GLib.Object {
		static Client _instance;
		private Xmms.Client _xmms;
		private pointer _gmain;

		public signal void connected();
		public signal void disconnected();

		public signal void playback_status(int status);
		public signal void playback_current_id(uint mid);
		public signal void playback_playtime(uint pos);
		public signal void playlist_loaded(string name);

		public signal void playlist_add(uint mid);
		public signal void playlist_insert(uint mid, int pos);
		public signal void playlist_remove(int pos);

		construct {
			_xmms = new Xmms.Client("Abraca");
		}

		private void on_disconnect() {
			disconnected();
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


		public bool try_connect() {
			string path;

			path = GLib.Environment.get_variable("XMMS_PATH");

			if (_xmms.connect(path)) {
				_gmain = Xmms.MainLoop.GMain.init(_xmms);
				_xmms.disconnect_callback_set(on_disconnect, this);
				create_callbacks();

				connected();

				return true;
			}

			return false;
		}

		private void create_callbacks() {
			_xmms.playback_status().notifier_set(
				on_playback_status, this
			);

			_xmms.broadcast_playback_status().notifier_set(
				on_playback_status, this
			);

			_xmms.playback_current_id().notifier_set(
				on_playback_current_id, this
			);

			_xmms.broadcast_playback_current_id().notifier_set(
				on_playback_current_id, this
			);

			_xmms.signal_playback_playtime().notifier_set(
				on_playback_playtime, this
			);

			_xmms.playlist_current_active().notifier_set(
				on_playlist_loaded, this
			);

			_xmms.broadcast_playlist_loaded().notifier_set(
				on_playlist_loaded, this
			);

			_xmms.broadcast_playlist_changed().notifier_set(
				on_playlist_changed, this
			);
		}

		[InstanceLast]
		private void on_playback_status(Xmms.Result res) {
			uint status;

			if (res.get_uint(out status)) {
				playback_status((int)status);
			}
		}

		[InstanceLast]
		private void on_playback_current_id(Xmms.Result res) {
			uint mid;

			if (res.get_uint(out mid)) {
				playback_current_id(mid);
			}
		}

		[InstanceLast]
		private void on_playback_playtime(Xmms.Result res) {
			uint pos;

			if (res.get_uint(out pos)) {
				playback_playtime(pos);
			}

			res.restart();
		}

		[InstanceLast]
		private void on_playlist_loaded(Xmms.Result res) {
			weak string name;

			if (res.get_string(out name)) {
				playlist_loaded(name);
			}
		}

		[InstanceLast]
		private void on_playlist_changed(Xmms.Result res) {
			int change, pos;
			uint id;

			res.get_dict_entry_int("type", out change);
			res.get_dict_entry_int("pos", out pos);
			res.get_dict_entry_uint("id", out id);

			switch (change) {
				case Xmms.PlaylistChange.ADD:
					playlist_add(id);
					break;
				case Xmms.PlaylistChange.INSERT:
					GLib.stdout.printf("PlaylistChange.INSERT not implemented!\n");
					break;
				case Xmms.PlaylistChange.REMOVE:
					GLib.stdout.printf("PlaylistChange.REMOVE not implemented!\n");
					break;
				case Xmms.PlaylistChange.MOVE:
					GLib.stdout.printf("PlaylistChange.MOVE not implemented!\n");
					break;
				case Xmms.PlaylistChange.UPDATE:
					GLib.stdout.printf("PlaylistChange.UPDATE not implemented!\n");
					break;
				case Xmms.PlaylistChange.CLEAR:
				case Xmms.PlaylistChange.SHUFFLE:
				case Xmms.PlaylistChange.SORT:
					xmms.playlist_current_active().notifier_set(
						on_playlist_loaded, this
					);
					break;
				default:
					break;
			}
		}
	}
}
