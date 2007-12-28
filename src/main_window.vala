/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class MainWindow : Gtk.Window {
		private MenuBar menubar;
		private ToolBar toolbar;
		private MainHPaned _main_hpaned;

		public MainHPaned main_hpaned {
			get {
				return _main_hpaned;
			}
		}

		construct {
			create_widgets();

			width_request = 800;
			height_request = 600;

			destroy += on_quit;
		}

		public void eval_config() {
			/* window size */
			int w = Abraca.instance().config.main_window_width;
			int h = Abraca.instance().config.main_window_height;

			if (w > 0 && h > 0)
				resize(w, h);

			/* maximized state */
			if (Abraca.instance().config.main_window_maximized)
				maximize();

			/* gravity */
			gravity = Abraca.instance().config.main_window_gravity;

			/* window position */
			int x = Abraca.instance().config.main_window_x;
			int y = Abraca.instance().config.main_window_y;

			move(x, y);

			/* other widgets */
			_main_hpaned.eval_config();
		}

		private void create_widgets() {
			Gtk.VBox vbox6 = new Gtk.VBox(false, 0);

			menubar = new MenuBar();
			vbox6.pack_start(menubar, false, true, 0);

			toolbar = new ToolBar();
			vbox6.pack_start(toolbar, false, false, 6);

			vbox6.pack_start(new Gtk.HSeparator(), false, true, 0);

			_main_hpaned = new MainHPaned();
			vbox6.pack_start(_main_hpaned, true, true, 0);

			add(vbox6);
		}

		private void on_quit(Gtk.Widget w) {
			Abraca.instance().quit();
		}
	}
}
