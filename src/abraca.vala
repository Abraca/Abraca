/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2010  Abraca Team
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
			_main_window.delete_event.connect ((ev) => {
				Configurable.save();
				Gtk.main_quit();
				return true;
			});
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
			Configurable.save();

			Gtk.main_quit();
		}

		public void server_browser ()
		{
			var c = Client.instance();
			var sb = ServerBrowser.build (main_window);

			while (sb.run() == ServerBrowser.Action.Connect) {
				if (c.try_connect (sb.selected_host)) {
					break;
				}
			}
		}

		public static int main(string[] args) {
			Client c = Client.instance();

			var context = new OptionContext (_("- Abraca, an XMMS2 client."));
			context.add_group (Gtk.get_option_group (false));

			try {
				context.parse (ref args);
			} catch (GLib.OptionError err) {
				var help = context.get_help (true, null);
				GLib.print ("%s\n%s", err.message, help);
				Posix.exit (1);
			}

			Gtk.init(ref args);

			try {
				create_icon_factory().add_default();
			} catch (GLib.Error e) {
				GLib.error(e.message);
			}

			GLib.Environment.set_application_name("Abraca");

			GLib.Intl.textdomain(Build.Config.APPNAME);
			GLib.Intl.bindtextdomain(Build.Config.APPNAME, Build.Config.LOCALEDIR);
			GLib.Intl.bind_textdomain_codeset(Build.Config.APPNAME, "UTF-8");

			Abraca a = Abraca.instance();

			Configurable.load();

			a.main_window.show_all();


			if (!c.try_connect())
				GLib.Timeout.add(500, c.reconnect);

			/*
			c.disconnected.connect (() => {
				var sb = ServerBrowser.build(a.main_window);
				while (sb.run() == 1) {
					GLib.debug("host: %s", sb.selected_host);
					if (c.try_connect (sb.selected_host)) {
						break;
					}
				}
			});

			c.try_connect ("apa");
			*/


			Gtk.main();

			return 0;
		}
	}
}
