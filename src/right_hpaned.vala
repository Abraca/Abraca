/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class RightHPaned : Gtk.HPaned {
		construct {
			position = 433;
			position_set = false;

			create_widgets();
		}

		private void create_widgets() {
			pack1(create_left_box(), false, true);
			pack2(create_right_box(), true, true);
		}

		private Gtk.Box create_left_box() {
			Gtk.VBox box = new Gtk.VBox(false, 0);

			Gtk.HBox hbox = new Gtk.HBox(false, 6);

			Gtk.Label label = new Gtk.Label("Filter:");
			hbox.pack_start(label, false, false, 0);

			Gtk.Entry entry = new Gtk.Entry();
			hbox.pack_start(entry, true, true, 0);

			box.pack_start(hbox, false, false, 2);

			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
			                    Gtk.PolicyType.AUTOMATIC);
			scrolled.add_with_viewport(new FilterTree());
			box.pack_start(scrolled, true, true, 0);

			return box;
		}

		private Gtk.Box create_right_box() {
			Gtk.VBox box = new Gtk.VBox(false, 0);

			Gtk.Expander exp = new Gtk.Expander("Playlist");
			box.pack_start(exp, false, false, 2);

			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
			                    Gtk.PolicyType.AUTOMATIC);
			scrolled.add_with_viewport(new PlaylistTree());
			box.pack_start(scrolled, true, true, 0);

			return box;
		}
	}
}
