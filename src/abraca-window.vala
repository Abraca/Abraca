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
	public class Window : Gtk.ApplicationWindow, IConfigurable {
		private static Gtk.Image PLAYBACK_PAUSE_IMAGE = new Gtk.Image.from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.BUTTON);
		private static Gtk.Image PLAYBACK_PLAY_IMAGE = new Gtk.Image.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.BUTTON);

		private Client client;
		private Config config;
		private Gtk.Paned main_hpaned;
		private Gtk.Paned right_hpaned;
		private Gtk.Widget main_ui;
		private NowPlaying now_playing;
		private MetadataResolver resolver;
		private Searchable search;
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
			{ "fullscreen", on_fullscreen }
		};

		public Window (Gtk.Application app, Client c, GLib.MenuModel menu)
		{
			Object(application: app);

			client = c;

			add_action_entries (actions, this);

			set_hide_titlebar_when_maximized(true);

			var accel_group = new Gtk.AccelGroup();

			main_ui = create_widgets(client, accel_group, menu);

			now_playing = new NowPlaying(client);
			now_playing.hide_now_playing.connect (on_unfullscreen);

			add(main_ui);

			try {
				set_icon(new Gdk.Pixbuf.from_resource ("/org/xmms2/Abraca/abraca-192.png"));
			} catch (GLib.Error e) {
				GLib.assert_not_reached ();
			}

			Configurable.register(this);

			client.configval_changed.connect(on_config_changed);
			client.playback_status.connect(on_playback_status_change);
			client.playback_current_info.connect(on_playback_current_info);

			delete_event.connect(() => {
				Configurable.save();
				return false;
			});
		}

		public void on_fullscreen ()
		{
			remove(main_ui);
			show_menubar = false;
			add(now_playing);
			now_playing.grab_focus();
			fullscreen();
			now_playing.show();
		}

		public void on_unfullscreen ()
		{
			remove(now_playing);
			show_menubar = true;
			unfullscreen();
			add(main_ui);
		}

		private void on_config_changed (Client c, string key, string value, bool initial)
		{
			if ("playlist.repeat_all" == key) {
				change_action_state("playlist-repeat-all", int.parse(value) > 0);
			}
			else if ("playlist.repeat_one" == key) {
				change_action_state("playlist-repeat-one", int.parse(value) > 0);
			}
		}

		private static int get_key(GLib.KeyFile file, string group, string key, double fallback)
		{
			try {
				return file.get_integer(group, key);
			}
			catch (GLib.KeyFileError e) {
				return (int) fallback;
			}
		}

		public void set_configuration (GLib.KeyFile file)
			throws GLib.KeyFileError
		{
			int xpos, ypos, width, height, pos;

			gravity = (Gdk.Gravity) get_key(file, "main_win", "gravity", 0);

			var root = Gdk.get_default_root_window();

			width = get_key(file, "main_win", "width", root.get_width() * 0.8);
			height = get_key(file, "main_win", "height", root.get_height() * 0.8);

			resize(width, height);

			get_position(out xpos, out ypos);

			xpos = get_key(file, "main_win", "x", -1);
			ypos = get_key(file, "main_win", "y", -1);

			if (xpos < 0 || ypos < 0)
				set_position(Gtk.WindowPosition.CENTER);
			else
				move(xpos, ypos);

			main_hpaned.position = get_key(file, "panes", "pos1", width * 0.1);
			right_hpaned.position = get_key(file, "panes", "pos2", width * 0.6);
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

			file.set_integer("panes", "pos1", main_hpaned.position);
			file.set_integer("panes", "pos2", right_hpaned.position);
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
			button.set_tooltip_text(Gtk.accelerator_get_label(key, modifier));

			return button;
		}

		private Gtk.Widget create_widgets (Client client, Gtk.AccelGroup accel_group, GLib.MenuModel menu_model)
		{
			config = new Config ();

			var playback_btns = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			playback_btns.get_style_context().add_class("linked");

			var playback_backward_btn = create_button("media-skip-backward-symbolic", "win.playback-skip-backward",
			                                          "<Primary>Left", accel_group);
			playback_btns.pack_start(playback_backward_btn);
			playback_backward_btn.width_request = 42;

			playback_toggle_btn = create_button("media-playback-start-symbolic", "win.playback-toggle",
			                                    "<Primary>p", accel_group);
			playback_btns.pack_start(playback_toggle_btn);
			playback_toggle_btn.width_request = 60;

			var playback_forward_btn = create_button("media-skip-forward-symbolic", "win.playback-skip-forward",
			                                         "<Primary>Right", accel_group);
			playback_btns.pack_start(playback_forward_btn);
			playback_forward_btn.width_request = 42;

			playback_label = new Gtk.Label("Abraca");
			playback_label.get_style_context().add_class("abraca-playback-label");

			var headerbar = new Gtk.HeaderBar();
			headerbar.show_close_button = true;
			headerbar.custom_title = playback_label;
			headerbar.pack_start(playback_btns);

			playback_label.activate_link.connect(on_playback_label_link_activated);

			var menu = new Gtk.MenuButton();
			menu.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.BUTTON);
			menu.menu_model = menu_model;
			headerbar.pack_end(menu);

			set_titlebar(headerbar);

			var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

			var position = new TimeSlider(client);
			position.margin_top = headerbar.spacing;
			position.margin_left = headerbar.spacing * 2;
			position.margin_right = headerbar.spacing * 2;
			position.margin_bottom = headerbar.spacing;

			vbox.pack_start(position, false, false, 0);

			var scrolled = new Gtk.ScrolledWindow (null, null);
			scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type (Gtk.ShadowType.IN);

			right_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			right_hpaned.position = 430;
			right_hpaned.position_set = true;

			resolver = new MetadataResolver(client);

			var medialib = new Medialib (this, client);

			var filter = new FilterWidget (client, resolver, config, medialib, accel_group);
			search = filter.get_searchable ();

			var playlist = new PlaylistWidget (client, resolver, config, medialib, search);

			right_hpaned.pack1(filter, true, true);
			right_hpaned.pack2(playlist, false, true);

			var collections = new CollectionsView (client, search);
			scrolled.add (collections);

			main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			main_hpaned.position = 135;
			main_hpaned.position_set = true;
			main_hpaned.sensitive = false;
			main_hpaned.pack1 (scrolled, false, true);
			main_hpaned.pack2 (right_hpaned, true, true);

			main_hpaned.vexpand = true;
			main_hpaned.valign = Gtk.Align.FILL;

			client.connection_state_changed.connect((c, state) => {
				main_hpaned.sensitive = (state == Client.ConnectionState.Connected);
			});

			vbox.pack_start(main_hpaned);//, true, true, 0);
			vbox.vexpand = true;
			vbox.valign = Gtk.Align.FILL;

			add_accel_group(accel_group);

			equalizer_dialog = new Equalizer(client);
			equalizer_dialog.window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
			equalizer_dialog.transient_for = this;

			return vbox;
		}

		private void on_menu_connect(GLib.SimpleAction action, GLib.Variant? state)
		{
			GLib.Idle.add(() => {
				var browser = new ServerBrowser(this, client);
				browser.run();
				return false;
			});
		}

		private void on_menu_music_add_url(GLib.SimpleAction action, GLib.Variant? state)
		{
			Medialib.create_add_url_dialog(this, client);
		}

		private void on_menu_music_add_files(GLib.SimpleAction action, GLib.Variant? state)
		{
			Medialib.create_add_file_dialog(this, client, Gtk.FileChooserAction.OPEN);
		}

		private void on_menu_music_add_directories(GLib.SimpleAction action, GLib.Variant? state)
		{
			Medialib.create_add_file_dialog(this, client, Gtk.FileChooserAction.SELECT_FOLDER);
		}

		private void on_menu_playlist_configure_sorting(GLib.SimpleAction action, GLib.Variant? state)
		{
			config.show_sorting_dialog(this);
		}

		private void on_menu_playlist_clear(GLib.SimpleAction action, GLib.Variant? state)
		{
			client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
		}

		private void on_menu_playlist_shuffle(GLib.SimpleAction action, GLib.Variant? state)
		{
			client.xmms.playlist_shuffle(Xmms.ACTIVE_PLAYLIST);
		}

		private void on_menu_playlist_repeat_one(GLib.SimpleAction action, GLib.Variant? state)
		{
			client.xmms.config_set_value("playlist.repeat_one", action.get_state().get_boolean() ? "0" : "1");
		}

		private void on_menu_playlist_repeat_all(GLib.SimpleAction action, GLib.Variant? state)
		{
			client.xmms.config_set_value("playlist.repeat_all", action.get_state().get_boolean() ? "0" : "1");
		}

		private void on_playback_toggle(GLib.SimpleAction action, GLib.Variant? state)
		{
			if (client.current_playback_status == Xmms.PlaybackStatus.PLAY) {
				client.xmms.playback_pause();
			} else {
				client.xmms.playback_start();
			}
		}

		private void on_playback_skip_forward(GLib.SimpleAction action, GLib.Variant? state)
		{
			client.xmms.playlist_set_next_rel(1);
			client.xmms.playback_tickle();
		}

		private void on_playback_skip_backward(GLib.SimpleAction action, GLib.Variant? state)
		{
			client.xmms.playlist_set_next_rel(-1);
			client.xmms.playback_tickle();
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

		private bool on_playback_label_link_activated(string uri) {
			search.search(uri);
			return true;
		}

		private string format_separator(string separator)
		{
			return GLib.Markup.printf_escaped(" <span size=\"smaller\" foreground=\"#666666\"><i>%s</i></span>", separator);
		}

		private string format_link(string query, string text)
		{
			return GLib.Markup.printf_escaped(" <b><span underline=\"none\"><a href=\"%s\">%s</a></span></b>", query, text);
		}

		private void on_playback_current_info (Xmms.Value val)
		{
			string title, info, url;
			int is_compilation;

			if (val.dict_entry_get_string("title", out title)) {
				string artist, album, channel;

				info = GLib.Markup.printf_escaped("<b>%s</b>", title);

				if (val.dict_entry_get_string("artist", out artist)) {
					info += format_separator(_("by"));
					info += format_link("artist:\"%s\"".printf(artist), artist);
				}

				if (val.dict_entry_get_string("album", out album)) {
					string album_artist;

					if (!val.dict_entry_get_int("compilation", out is_compilation))
						is_compilation = 0;

					info += format_separator(_("on"));
					if (val.dict_entry_get_string ("album_artist", out album_artist) && is_compilation == 0)
						info += format_link("album_artist:\"%s\" AND album:\"%s\"".printf(album_artist, album), album);
					else if (artist != null && is_compilation == 0)
						info += format_link("artist:\"%s\" AND album:\"%s\"".printf(artist, album), album);
					else if (artist != null && is_compilation == 1)
						info += format_link("album:\"%s\" AND compilation:1".printf(album), album);
					else
						info += format_link("album:\"%s\"".printf(album), album);
				}

				if (val.dict_entry_get_string("channel", out channel)) {
					info += format_separator(_("from"));
					info += GLib.Markup.printf_escaped(" <b>%s</b>", channel);
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
