/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class ToolBar : Gtk.HBox {
		private Gtk.Button play_pause;

		private int _status;
		private int _duration;
		private bool _seek;

		private Gtk.Label _track_label;
		private Gtk.Label _time_label;
		private Gtk.HScale _time_slider;

		construct {
			Client c = Client.instance();
			Gtk.Button btn;

			homogeneous = false;
			spacing = 0;

			_seek = false;

			btn = create_playback_button(Gtk.STOCK_MEDIA_PLAY);
			btn.clicked += on_media_play;

			play_pause = btn;

			btn = create_playback_button(Gtk.STOCK_MEDIA_STOP);
			btn.clicked += on_media_stop;

			btn = create_playback_button(Gtk.STOCK_MEDIA_PREVIOUS);
			btn.clicked += on_media_prev;

			btn = create_playback_button(Gtk.STOCK_MEDIA_NEXT);
			btn.clicked += on_media_next;

			create_seekbar();
			create_cover_image();
			create_track_label();

			c.playback_status += on_playback_status_change;
			c.playback_current_id += on_playback_current_id;
			c.playback_playtime += on_playback_playtime;
		}

		private Gtk.Button create_playback_button(weak string s) {
			Gtk.Button button = new Gtk.Button();

			button.relief = Gtk.ReliefStyle.NONE;
			button.image = new Gtk.Image.from_stock(s, Gtk.IconSize.SMALL_TOOLBAR);

			pack_start(button, false, false, 0);

			return button;
		}

		private void create_seekbar() {
			Gtk.VBox vbox = new Gtk.VBox(false, 0);

			_time_slider = new Gtk.HScale.with_range(0, 1, 0.01);

			_time_slider.digits = 1;
			_time_slider.draw_value = false;
			_time_slider.width_request = 130;
			_time_slider.sensitive = false;

			_time_slider.button_press_event += on_time_slider_press;
			_time_slider.button_release_event += on_time_slider_release;

			vbox.pack_start(_time_slider, true, true, 0);

			_time_label = new Gtk.Label("");
			vbox.pack_start(_time_label, true, true, 0);

			pack_start(vbox, false, true, 0);
		}

		[InstanceLast]
		private bool on_time_slider_press(Gtk.HScale scale, Gdk.EventButton e) {
			_seek = true;
			_time_slider.motion_notify_event += on_time_slider_motion_notify;

			return false;
		}

		[InstanceLast]
		private bool on_time_slider_release(Gtk.HScale scale, Gdk.EventButton e) {
			Client c = Client.instance();

			double percent = scale.get_value();
			uint pos = (uint) _duration * percent;

			c.xmms.playback_seek_ms(pos);

			_time_slider.motion_notify_event -= on_time_slider_motion_notify;

			_seek = false;

			return false;
		}

		[InstanceLast]
		private bool on_time_slider_motion_notify(Gtk.HScale scale, Gdk.EventMotion e) {
			double percent = scale.get_value();
			uint pos = (uint) _duration * percent;

			update_time(pos);

			return false;
		}

		private void create_cover_image() {
			// FIXME
		}

		private void create_track_label() {
			_track_label = new Gtk.Label("No Track");

			pack_start(_track_label, false, true, 4);
		}

		private void on_playback_current_id(Client c, uint mid) {
			c.xmms.medialib_get_info(mid).notifier_set(
				on_medialib_get_info
			);
		}

		private void update_time(uint pos) {
			/* This is a HACK to circumvent a bug in XMMS2 */
			if (_status == Xmms.PlaybackStatus.STOP) {
				pos = 0;
			}

			if (_duration > 0) {
				double percent = (double) pos / (double) _duration;
				_time_slider.set_value(percent);
				_time_slider.set_sensitive(true);
			} else {
				_time_slider.set_value(0);
				_time_slider.set_sensitive(false);
			}

			uint dur_min, dur_sec, pos_min, pos_sec;
			string info;

			dur_min = _duration / 60000;
			dur_sec = (_duration % 60000) / 1000;

			pos_min = pos / 60000;
			pos_sec = (pos % 60000) / 1000;

			info = Markup.printf_escaped("%3d:%02d  of %3d:%02d", pos_min, pos_sec, dur_min, dur_sec);

			_time_label.set_markup(info);
		}

		private void on_playback_playtime(Client c, uint pos) {
			if (_seek == false) {
				update_time(pos);
			}
		}

		[InstanceLast]
		private void on_medialib_get_info(Xmms.Result res) {
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

			info = Markup.printf_escaped(
				"<b>%s</b>\n" +
				"<small>by</small> %s <small>from</small> %s",
				title, artist, album
			);

			_track_label.set_markup(info);
			_duration = duration;
		}


		[InstanceLast]
		private void on_media_play(Gtk.Button btn) {
			Client c = Client.instance();

			if (_status == Xmms.PlaybackStatus.PLAY) {
				c.xmms.playback_pause();
			} else {
				c.xmms.playback_start();
			}
		}

		[InstanceLast]
		private void on_media_stop(Gtk.Button btn) {
			Client c = Client.instance();
			c.xmms.playback_stop();
		}

		[InstanceLast]
		private void on_media_prev(Gtk.Button btn) {
			Client c = Client.instance();
			c.xmms.playlist_set_next_rel(1);
			c.xmms.playback_tickle();
		}

		[InstanceLast]
		private void on_media_next(Gtk.Button btn) {
			Client c = Client.instance();
			c.xmms.playlist_set_next_rel(-1);
			c.xmms.playback_tickle();
		}

		[InstanceLast]
		private void on_playback_status_change(Client c, int status) {
			Gtk.Image image;

			_status = status;

			if (_status != Xmms.PlaybackStatus.PLAY) {
				image = new Gtk.Image.from_stock(
					Gtk.STOCK_MEDIA_PLAY,
					Gtk.IconSize.SMALL_TOOLBAR
				);
				play_pause.set_image(image);
			} else {
				image = new Gtk.Image.from_stock(
					Gtk.STOCK_MEDIA_PAUSE,
					Gtk.IconSize.SMALL_TOOLBAR
				);
				play_pause.set_image(image);
			}

			if (_status == Xmms.PlaybackStatus.STOP) {
				update_time(0);
			}
		}
	}
}
