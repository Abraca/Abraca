/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class MainWindow : Gtk.Window {
		private MenuBar menubar;
		private ToolBar _toolbar;
		private MainHPaned _main_hpaned;

		public MainHPaned main_hpaned {
			get {
				return _main_hpaned;
			}
		}

		public ToolBar toolbar {
			get {
				return _toolbar;
			}
		}

		construct {
			Client c = Client.instance();

			create_widgets();

			try {
				set_icon_from_file(Build.Config.PREFIX + "/share/pixmaps/abraca.svg");
			} catch (Error e) {
				GLib.stdout.printf("Abraca not properly installed, missing icon.");
			}

			width_request = 800;
			height_request = 600;

			destroy += on_quit;

			main_hpaned.set_sensitive(false);
			toolbar.set_sensitive(false);


			c.disconnected += c => {
				main_hpaned.set_sensitive(false);
				toolbar.set_sensitive(false);
			};

			c.connected += c => {
				main_hpaned.set_sensitive(true);
				toolbar.set_sensitive(true);
			};
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

			_toolbar = new ToolBar();
			vbox6.pack_start(_toolbar, false, false, 6);

			vbox6.pack_start(new Gtk.HSeparator(), false, true, 0);

			_main_hpaned = new MainHPaned();
			vbox6.pack_start(_main_hpaned, true, true, 0);

			add(vbox6);
		}

		private void on_quit(Gtk.Object w) {
			Abraca.instance().quit();
		}
	}
}
