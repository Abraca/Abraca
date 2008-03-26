/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */

namespace Abraca {
	public class Abraca : GLib.Object {
		static Abraca _instance;
		private MainWindow _main_window;
		private Config _config;
		private Medialib _medialib;

		construct {
			_main_window = new MainWindow();

			_config = new Config();
			_config.load();
			_medialib = new Medialib();
		}

		public MainWindow main_window {
			get {
				return _main_window;
			}
		}

		public Config config {
			get {
				return _config;
			}
		}

		public Medialib medialib {
			get {
				return _medialib;
			}
		}

		public static Abraca instance() {
			if (_instance == null)
				_instance = new Abraca();

			return _instance;
		}

		public void quit() {
			_config.save();

			Gtk.main_quit();
		}

		public static int main(string[] args) {
			Client c = Client.instance();

			Gtk.init(ref args);

			GLib.Environment.set_application_name("Abraca");

			Abraca a = Abraca.instance();

			a.main_window.eval_config();
			a.main_window.show_all();

			/**
			 * TODO: Server Browser is a bit stupid, fix it.
			 * ServerBrowser sb = new ServerBrowser(a.main_window);
			 */

			c.try_connect();

			Gtk.main();

			return 0;
		}
	}
}
