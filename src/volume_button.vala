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

public class Abraca.VolumeButton : Gtk.ScaleButton {
	private const string[] _icons = {
		"stock_volume-mute",
		"stock_volume-max",
		"stock_volume-0",
		"stock_volume-min",
		"stock_volume-med"
	};

	private bool _accept_updates = true;
	construct {
		has_tooltip = true;
		relief = Gtk.ReliefStyle.NONE;

		adjustment.lower = 0;
		adjustment.upper = 100;

		set_icons(_icons);

		pressed += (w) => {
			_accept_updates = false;
		};

		released += (w) => {
			_accept_updates = true ;
		};

		scroll_event += on_scroll_event;

		Client c = Client.instance();
		c.playback_volume += (client, val) => {
			if (_accept_updates) {
				value = 0;
				val.dict_foreach((key, val) => {
					int tmp;
					val.get_int(out tmp);

					if (value == 0) {
						value = (int) tmp;
					} else {
						value = (value + (int) tmp) / 2;
					}
				});
			}
		};

		value_changed += (w, volume) => {
			_apply_volume((uint) volume);
		};
	}

	private void _apply_volume (uint volume) {
		Client c = Client.instance();
		c.xmms.playback_volume_get().notifier_set((val) => {
			val.dict_foreach((key, val) => {
				// TODO: Use outer variable when supported by Vala
				Client c2 = Client.instance();
				int tmp;
				if (val.get_int(out tmp)) {
					c2.xmms.playback_volume_set(key, tmp);
				}
			});
			return true;
		});

		tooltip_text = "%d%%".printf((int) value);
	}

	public bool on_scroll_event (VolumeButton w, Gdk.EventScroll e) {
		uint tmp;

		if (e.direction == Gdk.ScrollDirection.UP) {
			tmp = (uint) value + 5;
		} else if (e.direction == Gdk.ScrollDirection.DOWN) {
			tmp = (uint) value - 5;
		} else {
			return true;
		}

		_apply_volume(tmp);

		return true;
	}
}
