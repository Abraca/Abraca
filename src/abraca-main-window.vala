/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2013 Abraca Team
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
	public class MainWindow : Gtk.ApplicationWindow, IConfigurable {
		private Client _client;
		private Config _config;
		private ToolBar _toolbar;
		private Gtk.Paned _main_hpaned;
		private Gtk.Paned _right_hpaned;
		private Gtk.Widget _main_ui;
		private NowPlaying _now_playing;
		private bool is_idle = false;

		private const ActionEntry[] actions = {
			{ "connect", on_menu_connect },
			{ "add-url", on_menu_music_add_url },
			{ "add-files", on_menu_music_add_files },
			{ "add-directories", on_menu_music_add_directories },
			{ "playlist-sorting", on_menu_playlist_configure_sorting },
			{ "playlist-clear", on_menu_playlist_clear },
			{ "playlist-shuffle", on_menu_playlist_shuffle },
			{ "playlist-repeat-all", on_menu_playlist_repeat_all, null, "false" },
			{ "playlist-repeat-one", on_menu_playlist_repeat_one, null, "false" }
		};

		public MainWindow (Gtk.Application app, Client client)
		{
			Object(application: app);

			_client = client;

			add_action_entries (actions, this);

			_main_ui = create_widgets(client);

			_now_playing = new NowPlaying(client);
			_now_playing.hide_now_playing.connect (on_hide_now_playing);

			add(_main_ui);

			try {
				set_icon(new Gdk.Pixbuf.from_resource ("/org/xmms2/Abraca/abraca-32.png"));
			} catch (GLib.Error e) {
				GLib.assert_not_reached ();
			}

			width_request = 800;
			height_request = 600;

			Configurable.register(this);

			client.configval_changed.connect(on_config_changed);

			delete_event.connect(() => {
				Configurable.save();
				return false;
			});
		}

		public void on_application_idle ()
		{
			if (!is_idle) {
				is_idle = true;
				remove(_main_ui);
				show_menubar = false;
				add(_now_playing);
				_now_playing.grab_focus();
				show_all();
			}
		}

		public void on_hide_now_playing ()
		{
			is_idle = false;
			remove(_now_playing);
			show_menubar = true;
			add(_main_ui);
		}

		private void on_config_changed (Client c, string key, string value)
		{
			if ("playlist.repeat_all" == key) {
				change_action_state("playlist-repeat-all", int.parse(value) > 0);
			}
			else if ("playlist.repeat_one" == key) {
				change_action_state("playlist-repeat-one", int.parse(value) > 0);
			}
		}

		public void set_configuration (GLib.KeyFile file)
			throws GLib.KeyFileError
		{
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

		public void get_configuration (GLib.KeyFile file)
		{
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

		private Gtk.Widget create_widgets (Client client)
		{
			_config = new Config ();

			var accel_group = new Gtk.AccelGroup();

			var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

			_toolbar = new ToolBar(client, this);
			vbox.pack_start(_toolbar, false, false, 6);

			var scrolled = new Gtk.ScrolledWindow (null, null);
			scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type (Gtk.ShadowType.IN);

			_right_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			_right_hpaned.position = 430;
			_right_hpaned.position_set = true;

			var medialib = new Medialib (this, client);

			var filter = new FilterWidget (client, _config, medialib, accel_group);
			var search = filter.get_searchable ();

			var playlist = new PlaylistWidget (client, _config, medialib, search);

			_right_hpaned.pack1(filter, true, true);
			_right_hpaned.pack2(playlist, false, true);

			var collections = new CollectionsView (client, search);
			scrolled.add (collections);

			_main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			_main_hpaned.position = 135;
			_main_hpaned.position_set = true;
			_main_hpaned.sensitive = false;
			_main_hpaned.pack1 (scrolled, false, true);
			_main_hpaned.pack2 (_right_hpaned, true, true);

			client.connection_state_changed.connect((c, state) => {
				_main_hpaned.sensitive = (state == Client.ConnectionState.Connected);
				_toolbar.sensitive = (state == Client.ConnectionState.Connected);
			});

			vbox.pack_start(_main_hpaned, true, true, 0);

			add_accel_group(accel_group);

			return vbox;
		}

		private void on_menu_connect(GLib.SimpleAction action, GLib.Variant? state)
		{
			GLib.Idle.add(() => {
				var browser = new ServerBrowser(this, _client);
				browser.run();
				return false;
			});
		}

		private void on_menu_music_add_url(GLib.SimpleAction action, GLib.Variant? state)
		{
			Medialib.create_add_url_dialog(this, _client);
		}

		private void on_menu_music_add_files(GLib.SimpleAction action, GLib.Variant? state)
		{
			Medialib.create_add_file_dialog(this, _client, Gtk.FileChooserAction.OPEN);
		}

		private void on_menu_music_add_directories(GLib.SimpleAction action, GLib.Variant? state)
		{
			Medialib.create_add_file_dialog(this, _client, Gtk.FileChooserAction.SELECT_FOLDER);
		}

		private void on_menu_playlist_configure_sorting(GLib.SimpleAction action, GLib.Variant? state)
		{
			_config.show_sorting_dialog(this);
		}

		private void on_menu_playlist_clear(GLib.SimpleAction action, GLib.Variant? state)
		{
			_client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
		}

		private void on_menu_playlist_shuffle(GLib.SimpleAction action, GLib.Variant? state)
		{
			_client.xmms.playlist_shuffle(Xmms.ACTIVE_PLAYLIST);
		}

		private void on_menu_playlist_repeat_one(GLib.SimpleAction action, GLib.Variant? state)
		{
			_client.xmms.config_set_value("playlist.repeat_one", action.get_state().get_boolean() ? "0" : "1");
		}

		private void on_menu_playlist_repeat_all(GLib.SimpleAction action, GLib.Variant? state)
		{
			_client.xmms.config_set_value("playlist.repeat_all", action.get_state().get_boolean() ? "0" : "1");
		}
	}
}
