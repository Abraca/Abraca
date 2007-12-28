/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class Abraca : Object {
		static Abraca _instance;
		private MainWindow _main_window;
		private Config _config;
		private Xmms.Client _xmms;

		construct {
			_main_window = new MainWindow();

			_config = new Config();
			_config.load();

			_xmms = new Xmms.Client("Abraca");
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

		public Xmms.Client xmms {
			get {
				return _xmms;
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

		public void try_connect() {
			_xmms.connect(Environment.get_variable("XMMS_PATH"));
			Xmms.MainLoop.GMain.init(_xmms);
		}

		public static int main(string[] args) {
			Gtk.init(out args);

			Environment.set_application_name("Abraca");

			Abraca.instance().main_window.eval_config();
			Abraca.instance().main_window.show_all();
			Abraca.instance().try_connect();

			Gtk.main();

			return 0;
		}
	}
}
