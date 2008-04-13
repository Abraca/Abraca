/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008  Abraca Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

namespace Abraca {
	public class Abraca : GLib.Object {
		static Abraca _instance;
		private MainWindow _main_window;
		private Medialib _medialib;

		construct {
			_main_window = new MainWindow();
			_medialib = new Medialib();
		}

		public MainWindow main_window {
			get {
				return _main_window;
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
			Config.instance().save();

			Gtk.main_quit();
		}

		public static int main(string[] args) {
			Client c = Client.instance();

			Gtk.init(ref args);

			GLib.Environment.set_application_name("Abraca");

			Config conf = Config.instance();
			Abraca a = Abraca.instance();

			conf.load();

			a.main_window.show_all();

			/**
			 * TODO: Server Browser is a bit stupid, fix it.
			 * ServerBrowser sb = new ServerBrowser(a.main_window);
			 */

			if (!c.try_connect())
				GLib.Timeout.add(500, c.reconnect);


			Gtk.main();

			return 0;
		}
	}
}
