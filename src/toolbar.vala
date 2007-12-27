/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class ToolBar : Gtk.HBox {
		construct {
			homogeneous = false;
			spacing = 0;

			create_playback_button("gtk-media-play");
			create_playback_button("gtk-media-stop");
			create_playback_button("gtk-media-previous");
			create_playback_button("gtk-media-next");

			create_seekbar();
			create_cover_image();
			create_track_label();
		}

		private void create_playback_button(weak string s) {
			Gtk.Button button = new Gtk.Button();
			button.relief = Gtk.ReliefStyle.NONE;
			button.image = Gtk.Image.from_stock(s, Gtk.IconSize.SMALL_TOOLBAR);
			pack_start(button, false, false, 0);
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
	}
}
