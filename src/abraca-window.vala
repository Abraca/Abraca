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
	public class Window : Adw.ApplicationWindow, IConfigurable {
		private Client client;
		private Config config;
		private Gtk.Paned main_hpaned;
		private Gtk.Paned right_hpaned;
		private Gtk.Widget main_ui;
		private NowPlaying now_playing;
		private MetadataResolver resolver;
		private Searchable search;
		private Equalizer equalizer_dialog;
		private Gtk.Button playback_toggle_btn;
		private Gtk.Label playback_label;

		/* Held so a late async discovery callback can't deref a freed browser. */
		private ServerBrowser server_browser;

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

			app.set_accels_for_action ("win.playback-skip-backward", { "<Primary>Left" });
			app.set_accels_for_action ("win.playback-toggle", { "<Primary>p" });
			app.set_accels_for_action ("win.playback-skip-forward", { "<Primary>Right" });

			main_ui = create_widgets(client, menu);

			now_playing = new NowPlaying(client);
			now_playing.hide_now_playing.connect (on_unfullscreen);

			set_content(main_ui);

			set_icon_name ("org.xmms2.abraca");

			Configurable.register(this);

			client.configval_changed.connect(on_config_changed);
			client.playback_status.connect(on_playback_status_change);
			client.playback_current_info.connect(on_playback_current_info);

			close_request.connect(() => {
				Configurable.save();
				return false;
			});
		}

		public void on_fullscreen ()
		{
			set_content(now_playing);
			now_playing.grab_focus();
			fullscreen();
		}

		public void on_unfullscreen ()
		{
			unfullscreen();
			set_content(main_ui);
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
			int width, height;

			width = get_key(file, "main_win", "width", 800);
			height = get_key(file, "main_win", "height", 600);

			set_default_size(width, height);

			main_hpaned.position = get_key(file, "panes", "pos1", width * 0.1);
			right_hpaned.position = get_key(file, "panes", "pos2", width * 0.6);
		}

		public void get_configuration (GLib.KeyFile file)
		{
			file.set_integer("main_win", "width", get_width());
			file.set_integer("main_win", "height", get_height());

			file.set_integer("panes", "pos1", main_hpaned.position);
			file.set_integer("panes", "pos2", right_hpaned.position);
		}

		private Gtk.Button create_button(string icon_name, string action, string accel)
		{
			Gdk.ModifierType modifier;
			uint key;

			var button = new Gtk.Button();
			button.set_icon_name(icon_name);
			button.action_name = action;

			Gtk.accelerator_parse(accel, out key, out modifier);
			button.set_tooltip_text(Gtk.accelerator_get_label(key, modifier));

			return button;
		}

		private Gtk.Widget create_widgets (Client client, GLib.MenuModel menu_model)
		{
			config = new Config ();

			var playback_btns = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			playback_btns.add_css_class("linked");

			var playback_backward_btn = create_button("media-skip-backward-symbolic", "win.playback-skip-backward",
			                                          "<Primary>Left");
			playback_btns.append(playback_backward_btn);
			playback_backward_btn.width_request = 42;

			playback_toggle_btn = create_button("media-playback-start-symbolic", "win.playback-toggle",
			                                    "<Primary>p");
			playback_btns.append(playback_toggle_btn);
			playback_toggle_btn.width_request = 60;

			var playback_forward_btn = create_button("media-skip-forward-symbolic", "win.playback-skip-forward",
			                                         "<Primary>Right");
			playback_btns.append(playback_forward_btn);
			playback_forward_btn.width_request = 42;

			playback_label = new Gtk.Label("Abraca");
			playback_label.use_markup = true;
			playback_label.add_css_class("abraca-playback-label");

			var header_cover = new Gtk.Picture() {
				content_fit = Gtk.ContentFit.CONTAIN,
				can_shrink = true,
				width_request = 28,
				height_request = 28,
				valign = Gtk.Align.CENTER
			};
			header_cover.add_css_class("abraca-header-cover");
			header_cover.set_paintable(client.current_coverart_paintable);
			client.playback_current_coverart_paintable.connect((paintable) => {
				header_cover.set_paintable(paintable);
			});

			var title_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8) {
				valign = Gtk.Align.CENTER
			};
			title_box.append(header_cover);
			title_box.append(playback_label);

			var headerbar = new Adw.HeaderBar();
			headerbar.set_title_widget(title_box);
			headerbar.pack_start(playback_btns);

			playback_label.activate_link.connect(on_playback_label_link_activated);

			var menu = new Gtk.MenuButton();
			menu.set_icon_name("open-menu-symbolic");
			menu.menu_model = menu_model;
			headerbar.pack_end(menu);

			var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			vbox.append(headerbar);

			var position = new TimeSlider(client);
			position.margin_top = 6;
			position.margin_start = 12;
			position.margin_end = 12;
			position.margin_bottom = 6;

			vbox.append(position);

			var scrolled = new Gtk.ScrolledWindow ();
			scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

			right_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			right_hpaned.position = 430;
			right_hpaned.position_set = true;

			resolver = new MetadataResolver(client);

			var medialib = new Medialib (this, client);

			var filter = new FilterWidget (client, resolver, config, medialib);
			search = filter.get_searchable ();

			var playlist = new PlaylistWidget (client, resolver, config, medialib, search);

			right_hpaned.set_start_child(filter);
			right_hpaned.set_resize_start_child(true);
			right_hpaned.set_end_child(playlist);
			right_hpaned.set_resize_end_child(false);

			var collections = new CollectionsView (client, search);
			scrolled.set_child (collections);

			main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
			main_hpaned.position = 135;
			main_hpaned.position_set = true;
			main_hpaned.sensitive = false;
			main_hpaned.set_start_child (scrolled);
			main_hpaned.set_resize_start_child (false);
			main_hpaned.set_end_child (right_hpaned);
			main_hpaned.set_resize_end_child (true);

			main_hpaned.vexpand = true;
			main_hpaned.valign = Gtk.Align.FILL;

			client.connection_state_changed.connect((c, state) => {
				main_hpaned.sensitive = (state == Client.ConnectionState.Connected);
			});

			vbox.append(main_hpaned);
			vbox.vexpand = true;
			vbox.valign = Gtk.Align.FILL;

			equalizer_dialog = new Equalizer(client);
			equalizer_dialog.transient_for = this;

			return vbox;
		}

		private void on_menu_connect(GLib.SimpleAction action, GLib.Variant? state)
		{
			GLib.Idle.add(() => {
				server_browser = new ServerBrowser(this, client);
				server_browser.run();
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
			equalizer_dialog.present ();
		}

		private void on_playback_status_change (Client c, int status)
		{
			switch (status) {
			case Xmms.PlaybackStatus.PLAY:
				playback_toggle_btn.set_icon_name("media-playback-pause-symbolic");
				break;
			default:
				playback_toggle_btn.set_icon_name("media-playback-start-symbolic");
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
