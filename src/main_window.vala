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
	public class MainWindow : Gtk.Window, IConfigurable {
		private MainHPaned _main_hpaned;
		private Gtk.CheckMenuItem _repeat_all;
		private Gtk.CheckMenuItem _repeat_one;

		public MainHPaned main_hpaned {
			get {
				return _main_hpaned;
			}
		}

		construct {
			var client = Client.instance();

			create_widgets();

			try {
				set_icon(new Gdk.Pixbuf.from_inline (
					-1, Resources.abraca_32, false
				));
			} catch (GLib.Error e) {
				GLib.assert_not_reached ();
			}

			width_request = 800;
			height_request = 600;
			allow_shrink = true;

			delete_event.connect((ev) => {
				Abraca.instance().quit();
				return false;
			});

			main_hpaned.set_sensitive(false);

			client.disconnected.connect(c => {
				main_hpaned.set_sensitive(false);
			});

			client.connected.connect(c => {
				main_hpaned.set_sensitive(true);
			});

			Configurable.register(this);
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			int xpos, ypos, width, height;

			if (!file.has_group("main_win")) {
				return;
			}


			if (file.has_key("main_win", "gravity")) {
				gravity = (Gdk.Gravity) file.get_integer("main_win", "gravity");
			}

			get_position(out xpos, out ypos);

			if (file.has_key("main_win", "x")) {
				xpos = file.get_integer("main_win", "x");
			}

			if (file.has_key("main_win", "y")) {
				ypos = file.get_integer("main_win", "y");
			}

			move(xpos, ypos);

			get_size(out width, out height);

			if (file.has_key("main_win", "width")) {
				width =  file.get_integer("main_win", "width");
			}

			if (file.has_key("main_win", "height")) {
				height = file.get_integer("main_win", "height");
			}

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
			var vbox = new Gtk.VBox(false, 0);

			var menubar = create_menubar();
			vbox.pack_start(menubar, false, true, 0);

			var toolbar = new ToolBar();
			vbox.pack_start(toolbar, false, false, 6);

			_main_hpaned = new MainHPaned();
			vbox.pack_start(_main_hpaned, true, true, 0);

			add(vbox);
		}


		private void on_config_changed (Client client, string key, string value) {
			Gtk.CheckMenuItem item;

			if (key == "playlist.repeat_all") {
				item = _repeat_all;
			} else if (key == "playlist.repeat_one") {
				item = _repeat_one;
			} else {
				return;
			}

			if (value == "1") {
				item.active = true;
			} else {
				item.active = false;
			}
			item.sensitive = true;
		}

		private Gtk.Widget create_menubar() {
			var builder = new Gtk.Builder ();
			var client = Client.instance();

			try {
				builder.add_from_string(
					Resources.XML.main_menu, Resources.XML.main_menu.length
				);
			} catch (GLib.Error e) {
				GLib.assert_not_reached ();
			}

			var uiman = builder.get_object("uimanager") as Gtk.UIManager;

			var menubar = uiman.get_widget("/Menu");

			_repeat_all = uiman.get_widget("/Menu/Playlist/RepeatAll") as Gtk.CheckMenuItem;
			_repeat_one = uiman.get_widget("/Menu/Playlist/RepeatOne") as Gtk.CheckMenuItem;

			uiman.get_action("/Menu/Music/Quit").activate.connect((action) => {
				Abraca.instance().quit();
			});

			uiman.get_action("/Menu/Music/Add/Files").activate.connect((action) => {
				Abraca.instance().medialib.create_add_file_dialog(Gtk.FileChooserAction.OPEN);
			});

			uiman.get_action("/Menu/Music/Add/Directory").activate.connect((action) => {
				Abraca.instance().medialib.create_add_file_dialog(Gtk.FileChooserAction.SELECT_FOLDER);
			});

			uiman.get_action("/Menu/Music/Add/URL").activate.connect((action) => {
				Abraca.instance().medialib.create_add_url_dialog();
			});

			uiman.get_action("/Menu/Playlist/ConfigureSorting").activate.connect((action) => {
				Config.instance().show_sorting_dialog();
			});

			uiman.get_action("/Menu/Playlist/Clear").activate.connect((action) => {
				client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
			});

			uiman.get_action("/Menu/Playlist/Shuffle").activate.connect((action) => {
				client.xmms.playlist_shuffle(Xmms.ACTIVE_PLAYLIST);
			});

			_repeat_all.toggled.connect((action) => {
				client.xmms.config_set_value("playlist.repeat_all",
				                             "%d".printf((int) action.active));
			});

			_repeat_one.toggled.connect((action) => {
				client.xmms.config_set_value("playlist.repeat_one",
				                             "%d".printf((int) action.active));
			});

			client.configval_changed.connect(on_config_changed);

			uiman.get_action("/Menu/Help/About").activate.connect((action) => {
				var about_builder = new Gtk.Builder ();

				try {
					about_builder.add_from_string(
						Resources.XML.about, Resources.XML.about.length
					);
				} catch (GLib.Error e) {
					GLib.assert_not_reached ();
				}

				var about = about_builder.get_object("abraca_about") as Gtk.AboutDialog;

				try {
					about.set_logo(new Gdk.Pixbuf.from_inline (
						-1, Resources.abraca_192, false
					));
				} catch (GLib.Error e) {
					GLib.assert_not_reached ();
				}

				about.version = Build.Config.VERSION;

				about.transient_for = Abraca.instance().main_window;

				about.run();
				about.hide();
			});

			return menubar;
		}
	}
}
