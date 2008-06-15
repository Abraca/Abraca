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
	public class MainWindow : Gtk.Window, IConfigurable {
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
				Gdk.Pixbuf tmp = new Gdk.Pixbuf.from_inline (
					-1, Resources.abraca_32, false
				);
				set_icon(tmp);
			} catch (GLib.Error e) {
				GLib.stderr.printf("ERROR: %s\n", e.message);
			}

			width_request = 800;
			height_request = 600;
			allow_shrink = true;

			delete_event += on_quit;

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

			Configurable.register(this);
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			int xpos, ypos, width, height;
			bool is_maximized;

			gravity = file.get_integer("main_win", "gravity");
			xpos = file.get_integer("main_win", "x");
			ypos = file.get_integer("main_win", "y");

			move(xpos, ypos);

			width =  file.get_integer("main_win", "width");
			height = file.get_integer("main_win", "height");

			if (width > 0 && height > 0) {
				resize(width, height);
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			int xpos, ypos, width, height;

			file.set_integer("main_win", "gravity", gravity);

			get_position(out xpos, out ypos);

			file.set_integer("main_win", "x", xpos);
			file.set_integer("main_win", "y", ypos);

			get_size(out width, out height);

			file.set_integer("main_win", "width", width);
			file.set_integer("main_win", "height", height);
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
		private bool on_quit(MainWindow w) {
			Abraca.instance().quit();

			return false;
		}
	}
}
