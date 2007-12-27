/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;
using Gtk;

namespace Abraca {
	public class MainHPaned : Gtk.HPaned {
		construct {
			position = 120;
			position_set = false;

			create_widgets();
		}

		private void create_widgets() {
			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.add_with_viewport(new CollectionsTree());

			pack1(scrolled, false, true);
			pack2(new RightHPaned(), true, true);
		}
	}
}
