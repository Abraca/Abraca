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

using GLib;

namespace Abraca {
	public class ToolBar : Gtk.HBox {
		private Gtk.Button play_pause;

		private uint _current_id;
		private int _status;
		private int _duration;
		private uint _pos;
		private bool _seek;

		private Gtk.Image _coverart;
		private Gdk.Pixbuf _coverart_big;
		private Gtk.Label _track_label;
		private Gtk.Label _time_label;
		private Gtk.HScale _time_slider;


		construct {
			Client c = Client.instance();
			Gtk.Button btn;

			homogeneous = false;
			spacing = 0;

			_seek = false;

			btn = create_playback_button(Gtk.STOCK_MEDIA_PLAY);
			btn.clicked += on_media_play;

			play_pause = btn;

			btn = create_playback_button(Gtk.STOCK_MEDIA_STOP);
			btn.clicked += on_media_stop;

			btn = create_playback_button(Gtk.STOCK_MEDIA_PREVIOUS);
			btn.clicked += on_media_prev;

			btn = create_playback_button(Gtk.STOCK_MEDIA_NEXT);
			btn.clicked += on_media_next;

			create_seekbar();
			create_cover_image();
			create_track_label();

			btn = new VolumeButton();
			pack_end(btn, false, false, 0);

			c.playback_status += on_playback_status_change;
			c.playback_current_id += on_playback_current_id;
			c.playback_playtime += on_playback_playtime;

			c.medialib_entry_changed += (client, res) => {
				on_media_info(res);
			};

			c.disconnected += (c) => {
				set_sensitive(false);
			};

			c.connected += (c) => {
				set_sensitive(true);
			};

			set_sensitive(false);
		}


		private Gtk.Button create_playback_button(string s) {
			Gtk.Button button = new Gtk.Button();

			button.relief = Gtk.ReliefStyle.NONE;
			button.image = new Gtk.Image.from_stock(s, Gtk.IconSize.SMALL_TOOLBAR);

			pack_start(button, false, false, 0);

			return button;
		}


		private void create_seekbar() {
			Gtk.VBox vbox = new Gtk.VBox(false, 0);

			_time_slider = new Gtk.HScale.with_range(0, 1, 0.01);

			_time_slider.digits = 1;
			_time_slider.draw_value = false;
			_time_slider.width_request = 130;
			_time_slider.sensitive = false;

			_time_slider.button_press_event += on_time_slider_press;
			_time_slider.button_release_event += on_time_slider_release;

			vbox.pack_start(_time_slider, true, true, 0);

			_time_label = new Gtk.Label("");
			vbox.pack_start(_time_label, true, true, 0);

			pack_start(vbox, false, false, 0);
		}


		private bool on_time_slider_press(Gtk.HScale widget, Gdk.EventButton button) {
			_seek = true;
			_time_slider.motion_notify_event += on_time_slider_motion_notify;

			return false;
		}


		private bool on_time_slider_release(Gtk.HScale scale, Gdk.EventButton button) {
			Client c = Client.instance();

			double percent = scale.get_value();
			uint pos = (uint)(_duration * percent);

			c.xmms.playback_seek_ms(pos);

			_time_slider.motion_notify_event -= on_time_slider_motion_notify;

			_seek = false;

			return false;
		}


		private bool on_time_slider_motion_notify(Gtk.HScale scale, Gdk.EventMotion motion) {
			double percent = scale.get_value();
			_pos = (uint)(_duration * percent);

			update_time_label();

			return false;
		}

		private bool on_coverart_tooltip (Gtk.Image image, int x, int y, bool keyboard_mode, Gtk.Tooltip tooltip) {
			if (_coverart_big != null) {
				tooltip.set_icon (_coverart_big);
				return true;
			}
			return false;
		}


		private void create_cover_image() {
			_coverart = new Gtk.Image.from_stock(
				Gtk.STOCK_CDROM, Gtk.IconSize.LARGE_TOOLBAR
			);

			_coverart.has_tooltip = true;
			_coverart.query_tooltip += on_coverart_tooltip;

			pack_start(_coverart, false, false, 4);
		}


		private void create_track_label() {
			_track_label = new Gtk.Label(
				_("No Track")
			);
			_track_label.ellipsize = Pango.EllipsizeMode.END;
			_track_label.set_alignment (0.0f, 0.5f);

			pack_start(_track_label, true, true, 4);
		}


		private void on_playback_current_id(Client c, int mid) {
			_current_id = mid;
			_pos = 0;

			c.xmms.medialib_get_info(mid).notifier_set(
				on_media_info
			);
		}


		private void update_time_label() {
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


		private void on_playback_playtime(Client c, int pos) {
			if (_seek == false) {
				_pos = pos;
				update_time_label();
			}
		}


		private bool on_media_info(Xmms.Value propdict) {
			string title, cover, info, url;
			int duration, id;

			Xmms.Value val = propdict.propdict_to_dict();

			val.dict_entry_get_int("id", out id);
			if (_current_id != id) {
				return true;
			}

			if (!val.dict_entry_get_int("duration", out duration)) {
				duration = 0;
			}

			if (!val.dict_entry_get_string("picture_front", out cover)) {
				_coverart.set_from_stock(
					Gtk.STOCK_CDROM, Gtk.IconSize.LARGE_TOOLBAR
				);
				_coverart_big = null;
			} else {
				Client c = Client.instance();

				c.xmms.bindata_retrieve(cover).notifier_set(
					on_bindata_retrieve
				);
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
					_("<b>%s</b>\n" +
					"<span size=\"small\" foreground=\"#666666\">by</span> %s <span size=\"small\" foreground=\"#666666\">from</span> %s"),
					title, artist, album
				);
			} else if (val.dict_entry_get_string("url", out url)) {
				info = GLib.Markup.printf_escaped(_("<b>%s</b>"), url);
			} else {
				info = "%s".printf("Unknown");
			}


			_track_label.set_markup(info);

			_duration = duration;

			update_time_label();

			return true;
		}


		private bool on_bindata_retrieve(Xmms.Value val) {
			unowned uchar[] data;

			if (val.get_bin(out data)) {
				Gdk.PixbufLoader loader;
				unowned Gdk.Pixbuf pixbuf;
				Gdk.Pixbuf modified;

				loader = new Gdk.PixbufLoader();
				try {
					loader.write(data);
					loader.close();
				} catch (GLib.Error ex) {
					GLib.stdout.printf("never happens, should default to CDROM icon\n");
				}

				pixbuf = loader.get_pixbuf();
				modified = pixbuf.scale_simple(32, 32, Gdk.InterpType.BILINEAR);

				_coverart.set_from_pixbuf(modified);
				_coverart_big = pixbuf;
			}

			return true;
		}


		private void on_media_play(Gtk.Button btn) {
			Client c = Client.instance();

			if (_status == Xmms.PlaybackStatus.PLAY) {
				c.xmms.playback_pause();
			} else {
				c.xmms.playback_start();
			}
		}


		private void on_media_stop(Gtk.Button btn) {
			Client c = Client.instance();
			c.xmms.playback_stop();
		}


		private void on_media_prev(Gtk.Button btn) {
			Client c = Client.instance();
			c.xmms.playlist_set_next_rel(-1);
			c.xmms.playback_tickle();
		}


		private void on_media_next(Gtk.Button btn) {
			Client c = Client.instance();
			c.xmms.playlist_set_next_rel(1);
			c.xmms.playback_tickle();
		}


		private void on_playback_status_change(Client c, int status) {
			Gtk.Image image;

			_status = status;

			if (_status != Xmms.PlaybackStatus.PLAY) {
				image = new Gtk.Image.from_stock(
					Gtk.STOCK_MEDIA_PLAY,
					Gtk.IconSize.SMALL_TOOLBAR
				);
				play_pause.set_image(image);
			} else {
				image = new Gtk.Image.from_stock(
					Gtk.STOCK_MEDIA_PAUSE,
					Gtk.IconSize.SMALL_TOOLBAR
				);
				play_pause.set_image(image);
			}

			if (_status == Xmms.PlaybackStatus.STOP) {
				update_time_label();
			}
		}
	}
}
