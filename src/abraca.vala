/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class Abraca : Object {
		static Abraca _instance;
		private MainWindow _main_window;

		construct {
			_main_window = new MainWindow();
		}

		public MainWindow main_window {
			get {
				return _main_window;
			}
		}

		public static Abraca instance() {
			if (_instance == null)
				_instance = new Abraca();

			return _instance;
		}

		public void quit() {
			// configuration.save();
			Gtk.main_quit();
		}

		public static int main(string[] args) {
			Gtk.init(out args);
			Environment.set_application_name("Abraca");
			Abraca.instance().main_window.show_all();
			Gtk.main();

			return 0;
		}
	}
}
