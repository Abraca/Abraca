/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class MainWindow : Gtk.Window {
		static MainWindow _instance;

		private MenuBar menubar;
		private ToolBar toolbar;
		private MainHPaned main_hpaned;

		construct {
			create_widgets();

			width_request = 800;
			height_request = 600;

			destroy += on_quit;
		}

		public static MainWindow instance() {
			if (_instance == null)
				_instance = new MainWindow();

			return _instance;
		}

		public void quit() {
			// configuration.save();
			Gtk.main_quit();
		}

		private void create_widgets() {
			Gtk.VBox vbox6 = new Gtk.VBox(false, 0);

			menubar = new MenuBar();
			vbox6.pack_start(menubar, false, true, 0);

			toolbar = new ToolBar();
			vbox6.pack_start(toolbar, false, false, 6);

			vbox6.pack_start(new Gtk.HSeparator(), false, true, 0);

			main_hpaned = new MainHPaned();
			vbox6.pack_start(main_hpaned, true, true, 0);

			add(vbox6);
		}

		private void on_quit(Gtk.Widget w) {
			quit();
		}
	}
}
