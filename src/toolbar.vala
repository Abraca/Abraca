/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class ToolBar : Gtk.HBox {
		private Gtk.Button play_pause;
		private uint _status;

		construct {
			homogeneous = false;
			spacing = 0;
			Gtk.Button btn;

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

		}

		public void query_playback_status() {
			Xmms.Client xmms = Abraca.instance().xmms;

			xmms.broadcast_playback_status().notifier_set(
				on_playback_status_change, this
			);
			
			xmms.playback_status().notifier_set(
				on_playback_status_change, this
			);
		}

		private Gtk.Button create_playback_button(weak string s) {
			Gtk.Button button = new Gtk.Button();
			button.relief = Gtk.ReliefStyle.NONE;
			button.image = Gtk.Image.from_stock(s, Gtk.IconSize.SMALL_TOOLBAR);
			pack_start(button, false, false, 0);

			return button;
		}

		private void create_seekbar() {
			Gtk.VBox vbox = new Gtk.VBox(false, 0);

			Gtk.HScale scale = new Gtk.HScale(
				new Gtk.Adjustment(
					0.0, 0.0, 110.0, 1.0, 10.0, 10.0
				)
			);

			scale.digits = 1;
			scale.draw_value = false;
			scale.width_request = 130;

			vbox.pack_start(scale, true, true, 0);

			Gtk.Label time = new Gtk.Label("label");
			vbox.pack_start(time, true, true, 0);

			pack_start(vbox, false, true, 0);
		}

		private void create_cover_image() {
			// FIXME
		}

		private void create_track_label() {
			Gtk.Label label = new Gtk.Label("label");

			pack_start(label, false, true, 4);
		}

		[InstanceLast]
		private void on_media_play(Gtk.Button btn) {
			Xmms.Client xmms = Abraca.instance().xmms;

			if ((int)_status == Xmms.PlaybackStatus.PLAY) {
				xmms.playback_pause();
			} else {
				xmms.playback_start();
			}
		}

		[InstanceLast]
		private void on_media_stop(Gtk.Button btn) {
			Xmms.Client xmms = Abraca.instance().xmms;
			xmms.playback_stop();
		}

		[InstanceLast]
		private void on_media_prev(Gtk.Button btn) {
			Xmms.Client xmms = Abraca.instance().xmms;
			xmms.playlist_set_next_rel(1);
			xmms.playback_tickle();
		}

		[InstanceLast]
		private void on_media_next(Gtk.Button btn) {
			Xmms.Client xmms = Abraca.instance().xmms;
			xmms.playlist_set_next_rel(-1);
			xmms.playback_tickle();
		}

		[InstanceLast]
		private void on_playback_status_change(Xmms.Result res) {
			Gtk.Image image;

			res.get_uint(out _status);

			if ((int)_status != Xmms.PlaybackStatus.PLAY) {
				image = Gtk.Image.from_stock(
					Gtk.STOCK_MEDIA_PLAY,
					Gtk.IconSize.SMALL_TOOLBAR
				);
				play_pause.set_image(image);
			} else {
				image = Gtk.Image.from_stock(
					Gtk.STOCK_MEDIA_PAUSE,
					Gtk.IconSize.SMALL_TOOLBAR
				);
				play_pause.set_image(image);
			}
		}
	}
}
