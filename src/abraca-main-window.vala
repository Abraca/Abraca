/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2014 Abraca Team
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
		private static Gtk.Image PLAYBACK_PAUSE_IMAGE = new Gtk.Image.from_icon_name("media-playback-pause", Gtk.IconSize.BUTTON);
		private static Gtk.Image PLAYBACK_PLAY_IMAGE = new Gtk.Image.from_icon_name("media-playback-start", Gtk.IconSize.BUTTON);

		private Client _client;
		private Config _config;
		private Gtk.Widget _toolbar;
		private Gtk.Paned _main_hpaned;
		private Gtk.Paned _right_hpaned;
		private Gtk.Widget _main_ui;
		private NowPlaying _now_playing;
		private bool is_idle = false;
		private MetadataResolver resolver;
		private Gtk.Dialog equalizer_dialog;
		private Gtk.Button playback_toggle_btn;
		private Gtk.Label playback_label;

		private const ActionEntry[] actions = {
			{ "connect", on_menu_connect },
			{ "add-url", on_menu_music_add_url },
			{ "add-files", on_menu_music_add_files },
			{ "add-directories", on_menu_music_add_directories },
			{ "playlist-sorting", on_menu_playlist_configure_sorting },
			{ "playlist-clear", on_menu_playlist_clear },
			{ "playlist-shuffle", on_menu_playlist_shuffle },
			{ "playlist-repeat-all", on_menu_playlist_repeat_all, null, "false" },
			{ "playlist-repeat-one", on_menu_playlist_repeat_one, null, "false" },
			{ "playback-toggle", on_playback_toggle },
			{ "playback-skip-forward", on_playback_skip_forward },
			{ "playback-skip-backward", on_playback_skip_backward },
			{ "equalizer", on_open_equalizer },
		};

		public MainWindow (Gtk.Application app, Client client, GLib.MenuModel menu)
		{
			Object(application: app);

			_client = client;

			add_action_entries (actions, this);

			var accel_group = new Gtk.AccelGroup();

			_main_ui = create_widgets(client, accel_group, menu);

			_now_playing = new NowPlaying(client);
			_now_playing.hide_now_playing.connect (on_hide_now_playing);

			add(_main_ui);

			try {
				set_icon(new Gdk.Pixbuf.from_resource ("/org/xmms2/Abraca/abraca-192.png"));
			} catch (GLib.Error e) {
				GLib.assert_not_reached ();
			}

			width_request = 800;
			height_request = 600;

			Configurable.register(this);

			client.configval_changed.connect(on_config_changed);
			client.playback_status.connect(on_playback_status_change);
			client.playback_current_info.connect(on_playback_current_info);

			delete_event.connect(() => {
				Configurable.save();
				return false;
			});
		}

		public void on_application_idle ()
		{
			GLib.warning("idle...");

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

		private static Gtk.Button create_button(string icon_name, string action, string accel, Gtk.AccelGroup accel_group)
		{
			Gdk.ModifierType modifier;
			uint key;

			var button = new Gtk.Button();
			button.image = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.BUTTON);
			button.always_show_image = true;
			button.action_name = action;

			Gtk.accelerator_parse(accel, out key, out modifier);
			button.add_accelerator("activate", accel_group, key, modifier, 0);

			return button;
		}

		private Gtk.Widget create_widgets (Client client, Gtk.AccelGroup accel_group, GLib.MenuModel menu_model)
		{
			_config = new Config ();

			var playback_btns = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			playback_btns.get_style_context().add_class("linked");

			var playback_backward_btn = create_button("media-skip-backward", "win.playback-skip-backward",
			                                          "<Primary>Left", accel_group);
			playback_btns.pack_start(playback_backward_btn);

			playback_toggle_btn = create_button("media-playback-start", "win.playback-toggle",
			                                    "<Primary>p", accel_group);
			playback_btns.pack_start(playback_toggle_btn);

			var playback_forward_btn = create_button("media-skip-forward", "win.playback-skip-forward",
			                                         "<Primary>Left", accel_group);
			playback_btns.pack_start(playback_forward_btn);

			playback_label = new Gtk.Label("Start playback!");

			var headerbar = new Gtk.HeaderBar();
			headerbar.show_close_button = true;
			headerbar.custom_title = playback_label;
			headerbar.pack_start(playback_btns);

			var menu = new Gtk.MenuButton();
			menu.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.BUTTON);
			menu.menu_model = menu_model;
			headerbar.pack_end(menu);

			set_titlebar(headerbar);

			var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

			var position = new TimeSlider(client);

			var align = new Gtk.Alignment(0.5f, 0.5f, 1.0f, 1.0f);
			align.add(position);
			align.top_padding = headerbar.spacing;
			align.left_padding = headerbar.spacing * 2;
			align.right_padding = headerbar.spacing * 2;
			align.bottom_padding = headerbar.spacing;
			vbox.pack_start(align, false, false, 0);

			var scrolled = new Gtk.ScrolledWindow (null, null);
			scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type (Gtk.ShadowType.IN);

			_right_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			_right_hpaned.position = 430;
			_right_hpaned.position_set = true;

			resolver = new MetadataResolver(client);

			var medialib = new Medialib (this, client);

			var filter = new FilterWidget (client, resolver, _config, medialib, accel_group);
			var search = filter.get_searchable ();

			var playlist = new PlaylistWidget (client, resolver, _config, medialib, search);

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

			_main_hpaned.vexpand = true;
			_main_hpaned.valign = Gtk.Align.FILL;

			client.connection_state_changed.connect((c, state) => {
				_main_hpaned.sensitive = (state == Client.ConnectionState.Connected);
			});

			vbox.pack_start(_main_hpaned);//, true, true, 0);
			vbox.vexpand = true;
			vbox.valign = Gtk.Align.FILL;

			add_accel_group(accel_group);

			equalizer_dialog = new Gtk.Dialog.with_buttons(
				"Equalizer", this, Gtk.DialogFlags.DESTROY_WITH_PARENT
			);
			equalizer_dialog.window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

			var box = equalizer_dialog.get_content_area () as Gtk.Box;
			box.pack_start (new Equalizer (_client));
			box.expand = true;
			box.halign = Gtk.Align.FILL;

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

		private void on_playback_toggle(GLib.SimpleAction action, GLib.Variant? state)
		{
			if (_client.current_playback_status == Xmms.PlaybackStatus.PLAY) {
				_client.xmms.playback_pause();
			} else {
				_client.xmms.playback_start();
			}
		}

		private void on_playback_skip_forward(GLib.SimpleAction action, GLib.Variant? state)
		{
			_client.xmms.playlist_set_next_rel(1);
			_client.xmms.playback_tickle();
		}

		private void on_playback_skip_backward(GLib.SimpleAction action, GLib.Variant? state)
		{
			_client.xmms.playlist_set_next_rel(-1);
			_client.xmms.playback_tickle();
		}

		private void on_open_equalizer(GLib.SimpleAction action, GLib.Variant? state)
		{
			equalizer_dialog.show_all ();
			equalizer_dialog.run ();
			equalizer_dialog.hide ();
		}

		private void on_playback_status_change (Client c, int status)
		{
			switch (status) {
			case Xmms.PlaybackStatus.PLAY:
				playback_toggle_btn.image = PLAYBACK_PAUSE_IMAGE;
				break;
			default:
				playback_toggle_btn.image = PLAYBACK_PLAY_IMAGE;
				break;
			}
		}

		private void on_playback_current_info (Xmms.Value val)
		{
			string title, info, url;

			if (val.dict_entry_get_string("title", out title)) {
				string artist, album, channel;

				info = GLib.Markup.printf_escaped("<b>%s</b>", title);

				if (val.dict_entry_get_string("artist", out artist)) {
					info += GLib.Markup.printf_escaped(" <span size=\"smaller\" foreground=\"#666666\"><i>" + _("by") + "</i></span> <b>%s</b>", artist);
				}

				if (val.dict_entry_get_string("album", out album)) {
					info += GLib.Markup.printf_escaped(" <span size=\"smaller\" foreground=\"#666666\"><i>" + _("on") + "</i></span> <b>%s</b>", album);
				}

				if (val.dict_entry_get_string("channel", out channel)) {
					info += GLib.Markup.printf_escaped(" <span size=\"smaller\" foreground=\"#666666\"><i>" + _("from") + "</i></span> <b>%s</b>", channel);
				}
			} else if (val.dict_entry_get_string("channel", out title)) {
				info = GLib.Markup.printf_escaped("<b>%s</b>", title);
			} else if (val.dict_entry_get_string("url", out url)) {
				info = GLib.Markup.printf_escaped("<b>%s</b>", url);
			} else {
				info = "%s".printf("Unknown");
			}

			playback_label.set_markup(info);
		}
	}
}
