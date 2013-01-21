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

using GLib;

namespace Abraca {
	public class ToolBar : Gtk.HBox {
		private Gtk.Button play_pause;
		private Gtk.Button equalizer_button;
		private Gtk.Dialog equalizer_dialog;

		private int _status;
		private int _duration;
		private uint _pos;
		private bool _seek;

		private Gtk.Image _coverart;
		private Gtk.Label _track_label;
		private Gtk.Label _time_label;
		private Gtk.Scale _time_slider;
		private Client client;
		private CoverArtManager manager;

		public ToolBar (Client c, Gtk.Window parent, Gtk.AccelGroup group)
		{
			Gtk.Button btn;

			client = c;

			homogeneous = false;
			spacing = 0;

			_seek = false;

			btn = create_playback_button(Gtk.Stock.MEDIA_PLAY, group, "<Primary>p");
			btn.clicked.connect(on_media_play);

			play_pause = btn;

			btn = create_playback_button(Gtk.Stock.MEDIA_STOP, group, "<Primary>s");
			btn.clicked.connect(on_media_stop);

			btn = create_playback_button(Gtk.Stock.MEDIA_PREVIOUS, group, "<Primary>Left");
			btn.clicked.connect(on_media_prev);

			btn = create_playback_button(Gtk.Stock.MEDIA_NEXT, group, "<Primary>Right");
			btn.clicked.connect(on_media_next);


			create_seekbar();
			create_cover_image();
			create_track_label();

			btn = new VolumeButton(client);
			pack_end(btn, false, false, 0);

			equalizer_button = new Gtk.Button();
			equalizer_button.no_show_all = true;
			equalizer_button.relief = Gtk.ReliefStyle.NONE;
			equalizer_button.image = new Gtk.Image.from_stock(Abraca.STOCK_EQUALIZER,
			                                                  Gtk.IconSize.SMALL_TOOLBAR);
			equalizer_button.clicked.connect(on_equalizer_show);
			pack_end(equalizer_button, false, false, 0);

			client.playback_status.connect(on_playback_status_change);
			client.playback_playtime.connect(on_playback_playtime);
			client.connection_state_changed.connect(on_connection_state_changed);
			client.playback_current_info.connect(on_playback_current_info);
			client.playback_current_coverart.connect(on_playback_current_coverart);

			manager = new CoverArtManager (client, parent);

			equalizer_dialog = new Gtk.Dialog.with_buttons(
				"Equalizer", parent,
				Gtk.DialogFlags.DESTROY_WITH_PARENT
			);
			equalizer_dialog.window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

			var box = equalizer_dialog.get_content_area () as Gtk.Box;
			box.pack_start (new Equalizer (client));

			set_sensitive(false);
		}



		private Gtk.Button create_playback_button (string stock_id, Gtk.AccelGroup group, string accel)
		{
			Gdk.ModifierType accel_type;
			uint accel_key;

			Gtk.accelerator_parse(accel, out accel_key, out accel_type);

			var button = new Gtk.Button();
			button.relief = Gtk.ReliefStyle.NONE;
			button.image = new Gtk.Image.from_stock(stock_id, Gtk.IconSize.SMALL_TOOLBAR);
			button.add_accelerator("activate", group, accel_key, accel_type, 0);

			pack_start(button, false, false, 0);

			return button;
		}


		private void create_seekbar ()
		{
			var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

			_time_slider = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, 1, 0.01);

			_time_slider.digits = 1;
			_time_slider.draw_value = false;
			_time_slider.width_request = 130;
			_time_slider.sensitive = false;

			_time_slider.button_press_event.connect(on_time_slider_press);
			_time_slider.button_release_event.connect(on_time_slider_release);
			_time_slider.scroll_event.connect (on_time_slider_scroll);

			vbox.pack_start(_time_slider, true, true, 0);

			_time_label = new Gtk.Label("");
			vbox.pack_start(_time_label, true, true, 0);

			pack_start(vbox, false, false, 0);
		}


		private bool on_time_slider_press (Gtk.Widget widget, Gdk.EventButton ev)
		{
			_seek = true;
			_time_slider.motion_notify_event.connect(on_time_slider_motion_notify);

			return false;
		}


		private bool on_time_slider_release (Gtk.Widget widget, Gdk.EventButton ev)
		{
			double percent = (widget as Gtk.Range).get_value();
			uint pos = (uint)(_duration * percent);

			client.xmms.playback_seek_ms(pos, Xmms.PlaybackSeekMode.SET);

			_time_slider.motion_notify_event.connect (on_time_slider_motion_notify);

			_seek = false;

			return false;
		}


		private bool on_time_slider_scroll (Gtk.Widget widget, Gdk.EventScroll ev)
		{
			if (ev.direction == Gdk.ScrollDirection.UP ||
			    ev.direction == Gdk.ScrollDirection.LEFT) {
				client.xmms.playback_seek_ms (10 * 1000, Xmms.PlaybackSeekMode.CUR);
			} else {
				client.xmms.playback_seek_ms (-10 * 1000, Xmms.PlaybackSeekMode.CUR);
			}

			return true;
		}


		private bool on_time_slider_motion_notify (Gtk.Widget widget, Gdk.EventMotion ev)
		{
			var percent = (widget as Gtk.Range).get_value();
			_pos = (uint)(_duration * percent);

			update_time_label();

			return false;
		}


		private bool on_coverart_tooltip (Gtk.Widget widget, int xpos, int ypos,
		                                  bool mode, Gtk.Tooltip tooltip)
		{
			tooltip.set_icon (client.current_coverart);
			return true;
		}


		private void create_cover_image ()
		{
			_coverart = new Gtk.Image();
			_coverart.has_tooltip = true;

			var thumbnail = client.current_coverart.scale_simple(32, 32, Gdk.InterpType.BILINEAR);
			_coverart.set_from_pixbuf(thumbnail);

			_coverart.query_tooltip.connect(on_coverart_tooltip);

			var eventbox = new Gtk.EventBox ();
			eventbox.button_release_event.connect (on_coverart_clicked);
			eventbox.add(_coverart);

			pack_start(eventbox, false, false, 4);
		}


		private void create_track_label ()
		{
			_track_label = new Gtk.Label(
				_("No Track")
			);
			_track_label.ellipsize = Pango.EllipsizeMode.END;
			_track_label.set_alignment (0.0f, 0.5f);

			pack_start(_track_label, true, true, 4);
		}


		private void update_time_label ()
		{
			/* This is a HACK to circumvent a bug in XMMS2 */
			if (_status == Xmms.PlaybackStatus.STOP) {
				_pos = 0;
			}

			if (_duration > 0) {
				double percent = (double) _pos / (double) _duration;
				_time_slider.set_value(percent);
				_time_slider.set_sensitive(true);
			} else {
				_time_slider.set_value(0);
				_time_slider.set_sensitive(false);
			}

			uint dur_min, dur_sec, pos_min, pos_sec;
			string info;

			dur_min = _duration / 60000;
			dur_sec = (_duration % 60000) / 1000;

			pos_min = _pos / 60000;
			pos_sec = (_pos % 60000) / 1000;

			info = GLib.Markup.printf_escaped(
				_("%3d:%02d  of %3d:%02d"),
				pos_min, pos_sec, dur_min, dur_sec
			);

			_time_label.set_markup(info);
		}

		private bool on_coverart_clicked (Gtk.Widget w, Gdk.EventButton button)
		{
			manager.update_coverart (client.current_id);
			return false;
		}


		private void on_playback_playtime (Client c, int pos)
		{
			if (_seek == false) {
				_pos = pos;
				update_time_label();
			}
		}

		private void on_playback_current_info (Xmms.Value val)
		{
			string title, info, url;
			int duration;

			if (!val.dict_entry_get_int("duration", out duration)) {
				duration = 0;
			}

			if (val.dict_entry_get_string("title", out title)) {
				string artist, album;
				if (!val.dict_entry_get_string("artist", out artist)) {
					artist = _("Unknown");
				}

				if (!val.dict_entry_get_string("album", out album)) {
					album = _("Unknown");
				}

				info = GLib.Markup.printf_escaped(
					"<b>%s</b>\n" + _("<span size=\"small\" foreground=\"#666666\">by</span> %s <span size=\"small\" foreground=\"#666666\">on</span> %s"),
					title, artist, album
				);
			} else if (val.dict_entry_get_string("url", out url)) {
				info = GLib.Markup.printf_escaped("<b>%s</b>", url);
			} else {
				info = "%s".printf("Unknown");
			}

			_track_label.set_markup(info);

			_duration = duration;

			update_time_label();
		}

		private void on_playback_current_coverart (Gdk.Pixbuf? pixbuf)
		{
			var thumbnail = pixbuf.scale_simple(32, 32, Gdk.InterpType.BILINEAR);
			_coverart.set_from_pixbuf(thumbnail);
		}

		private void on_media_play (Gtk.Button button)
		{
			if (_status == Xmms.PlaybackStatus.PLAY) {
				client.xmms.playback_pause();
			} else {
				client.xmms.playback_start();
			}
		}


		private void on_media_stop (Gtk.Button button)
		{
			client.xmms.playback_stop();
		}


		private void on_media_prev (Gtk.Button button)
		{
			client.xmms.playlist_set_next_rel(-1);
			client.xmms.playback_tickle();
		}


		private void on_media_next (Gtk.Button button)
		{
			client.xmms.playlist_set_next_rel(1);
			client.xmms.playback_tickle();
		}


		private void on_playback_status_change (Client c, int status)
		{
			_status = status;

			var icon = (_status != Xmms.PlaybackStatus.PLAY) ?
				Gtk.Stock.MEDIA_PLAY : Gtk.Stock.MEDIA_PAUSE;

			var image = new Gtk.Image.from_stock(icon, Gtk.IconSize.SMALL_TOOLBAR);

			play_pause.set_image(image);

			if (_status == Xmms.PlaybackStatus.STOP) {
				update_time_label();
			}
		}

		/**
		 * Only show the icon if the equalizer capability is available.
		 */
		private bool on_list_plugins (Xmms.Value value)
		{
			unowned Xmms.ListIter iter;

			equalizer_button.hide();

			for (value.get_list_iter(out iter); iter.valid(); iter.next()) {
				Xmms.Value entry;
				string name;

				if (!iter.entry(out entry)) {
					continue;
				}

				if (!entry.dict_entry_get_string("shortname", out name)) {
					continue;
				}

				if (name == "equalizer") {
					equalizer_button.show ();
				}
			}

			return true;
		}

		private void on_connection_state_changed (Client client, Client.ConnectionState state)
		{
			if (state != Client.ConnectionState.Connected) {
				return;
			}

			client.xmms.main_list_plugins(Xmms.PluginType.XFORM).notifier_set (
				on_list_plugins
			);
		}

		private void on_equalizer_show (Gtk.Button button)
		{
			equalizer_dialog.show_all ();
			equalizer_dialog.run ();
			equalizer_dialog.hide ();
		}
	}
}
