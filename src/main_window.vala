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
		private Gtk.HPaned _main_hpaned;
		private Gtk.HPaned _right_hpaned;
		private Gtk.CheckMenuItem _repeat_all;
		private Gtk.CheckMenuItem _repeat_one;

		public MainWindow (Client client)
		{
			create_widgets(client);

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

			_main_hpaned.set_sensitive(false);

			client.disconnected.connect(c => {
				_main_hpaned.set_sensitive(false);
			});

			client.connected.connect(c => {
				_main_hpaned.set_sensitive(true);
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

			if (file.has_group("panes")) {
				if (file.has_key("panes", "pos1")) {
					var pos = file.get_integer("panes", "pos1");
					if (pos >= 0) {
						_main_hpaned.position = pos;
					}
				}
				if (file.has_key("panes", "pos2")) {
					var pos = file.get_integer ("panes", "pos2");
					if (pos >= 0) {
						_right_hpaned.position = pos;
					}
				}
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

			file.set_integer("panes", "pos1", _main_hpaned.position);
			file.set_integer("panes", "pos2", _right_hpaned.position);
		}


		private void create_widgets(Client client) {
			var config = Config.instance();

			var accel_group = new Gtk.AccelGroup();

			var vbox = new Gtk.VBox(false, 0);

			var menubar = create_menubar(client);
			vbox.pack_start(menubar, false, true, 0);

			var toolbar = new ToolBar(client);
			vbox.pack_start(toolbar, false, false, 6);

			var scrolled = new Gtk.ScrolledWindow (null, null);
			scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type (Gtk.ShadowType.IN);

			_right_hpaned = new Gtk.HPaned ();
			_right_hpaned.position = 430;
			_right_hpaned.position_set = true;

			var medialib = new Medialib (this, client);

			var filter = new FilterWidget (client, config, medialib, accel_group);
			var search = filter.get_searchable ();

			var playlist = new PlaylistWidget (client, config, medialib, search);

			_right_hpaned.pack1(filter, true, true);
			_right_hpaned.pack2(playlist, false, true);

			var collections = new CollectionsView (client, search);
			scrolled.add (collections);

			_main_hpaned = new Gtk.HPaned ();
			_main_hpaned.position = 135;
			_main_hpaned.position_set = true;
			_main_hpaned.pack1 (scrolled, false, true);
			_main_hpaned.pack2 (_right_hpaned, true, true);

			vbox.pack_start(_main_hpaned, true, true, 0);

			add(vbox);

			add_accel_group(accel_group);
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

		private Gtk.Widget create_menubar(Client client) {
			var builder = new Gtk.Builder ();

			try {
				builder.add_from_string(
					Resources.XML.main_menu, Resources.XML.main_menu.length
				);
			} catch (GLib.Error e) {
				GLib.assert_not_reached ();
			}

			var uiman = builder.get_object("uimanager") as Gtk.UIManager;

			var group = uiman.get_accel_group();
			add_accel_group(group);

			var menubar = uiman.get_widget("/Menu");

			_repeat_all = uiman.get_widget("/Menu/Playlist/RepeatAll") as Gtk.CheckMenuItem;
			_repeat_one = uiman.get_widget("/Menu/Playlist/RepeatOne") as Gtk.CheckMenuItem;

			uiman.get_action("/Menu/Music/Quit").activate.connect((action) => {
				Configurable.save();
				Gtk.main_quit();
			});

			uiman.get_action("/Menu/Music/Connect").activate.connect ((action) => {
				var sb = ServerBrowser.build(this);
				while (sb.run() == 1) {
					GLib.debug("host: %s", sb.selected_host);
					if (client.try_connect (sb.selected_host)) {
						break;
					}
				}
			});

			uiman.get_action("/Menu/Music/Add/Files").activate.connect((action) => {
				var parent = get_ancestor (typeof(Gtk.Window)) as Gtk.Window;
				Medialib.create_add_file_dialog(parent, client, Gtk.FileChooserAction.OPEN);
			});

			uiman.get_action("/Menu/Music/Add/Directory").activate.connect((action) => {
				var parent = get_ancestor (typeof(Gtk.Window)) as Gtk.Window;
				Medialib.create_add_file_dialog(parent, client, Gtk.FileChooserAction.SELECT_FOLDER);
			});

			uiman.get_action("/Menu/Music/Add/URL").activate.connect((action) => {
				var parent = get_ancestor (typeof(Gtk.Window)) as Gtk.Window;
				Medialib.create_add_url_dialog(parent, client);
			});

			uiman.get_action("/Menu/Playlist/ConfigureSorting").activate.connect((action) => {

				Config.instance().show_sorting_dialog(this);
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

				about.transient_for = get_ancestor (typeof(Gtk.Window)) as Gtk.Window;

				about.run();
				about.hide();
			});

			return menubar;
		}
	}
}
