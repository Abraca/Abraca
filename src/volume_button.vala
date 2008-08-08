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

public class Abraca.VolumeButton : Gtk.Button {
	public signal void volume_changed (uint volume);

	private int _old_icon = -1;

	private uint _volume = 0;

	public uint volume {
		get {
			return _volume;
		}
		set {
			if (value > min && value < max) {
				_volume = value;
				update_icon();
				volume_changed(value);
				tooltip_text = "%d%%".printf((int)(100.0 * value / (max - min)));
			}
		}
		default = 0;
	}

	public uint step {
		get; set; default = 3;
	}

	public uint min {
		get; set; default = 0;
	}

	public uint max {
		get; set; default = 100;
	}

	public Gtk.IconSize size {
		get; set; default = Gtk.IconSize.SMALL_TOOLBAR;
	}

	construct {
		has_tooltip = true;
		relief = Gtk.ReliefStyle.NONE;
		volume = 50;

		scroll_event += on_scroll_event;

		Client c = Client.instance();
		c.playback_volume += (client, res) => {
			uint tmp;
			res.get_dict_entry_uint("master", out tmp);
			volume = tmp;
		};
	}

	private void update_icon() {
		Gdk.Pixbuf buf;
		int icon = (int)(4.0 * volume / (max - min));

		/* Still the same icon */
		if (icon == _old_icon) {
			return;
		}

		try {
			Gdk.Pixbuf tmp;

			switch (icon) {
				case 0:
			 		tmp = new Gdk.Pixbuf.from_inline (
						-1, Resources.audio_volume_muted, false
					);
					break;
				case 1:
			 		tmp = new Gdk.Pixbuf.from_inline (
						-1, Resources.audio_volume_low, false
					);
					break;
				case 2:
			 		tmp = new Gdk.Pixbuf.from_inline (
						-1, Resources.audio_volume_medium, false
					);
					break;
				case 3:
			 		tmp = new Gdk.Pixbuf.from_inline (
						-1, Resources.audio_volume_high, false
					);
					break;
				default:
					GLib.stdout.printf("noes %d\n", icon);
					break;
			}
			buf = tmp;
		} catch (GLib.Error e) {
			GLib.stderr.printf("ERROR: %s\n", e.message);
		}

		image = new Gtk.Image.from_pixbuf(buf);

		_old_icon = icon;
	}

	public bool on_scroll_event (VolumeButton w, Gdk.EventScroll e) {
		Client c = Client.instance();
		if (e.direction == Gdk.ScrollDirection.UP) {
			c.xmms.playback_volume_set("master", (uint) volume + step);
		} else if (e.direction == Gdk.ScrollDirection.DOWN) {
			c.xmms.playback_volume_set("master", (uint) volume - step);
		}

		return true;
	}
}
