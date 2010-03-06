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
		"stock_volume-med",
		null
	};

	private bool _accept_updates = true;

	// TODO: Remove this when vala supports proper closures.
	private int _tmp_apply_volume_value = 0;

	construct {
		has_tooltip = true;
		relief = Gtk.ReliefStyle.NONE;

		adjustment.lower = 0;
		adjustment.upper = 100;

		set_icons(_icons);

		pressed.connect((w) => {
			_accept_updates = false;
		});

		released.connect((w) => {
			_accept_updates = true ;
		});

		scroll_event.connect(on_scroll_event);

		Client c = Client.instance();
		c.playback_volume.connect(on_volume_changed);

		value_changed.connect((w, volume) => {
			// TODO: Remove this once vala supports proper closures.
			_tmp_apply_volume_value = (int) value;
			_apply_volume((int) volume);
		});
	}

	private void _apply_volume (int volume) {
		Client c = Client.instance();
		c.xmms.playback_volume_get().notifier_set((val) => {
			val.dict_foreach((key, val) => {
				Client c2 = Client.instance();
				c2.xmms.playback_volume_set (key, _tmp_apply_volume_value);
			});
			return true;
		});

		tooltip_text = "%d%%".printf((int) value);
	}

	public bool on_scroll_event (Gtk.Widget w, Gdk.EventScroll e) {
		uint tmp;

		if (e.direction == Gdk.ScrollDirection.UP) {
			tmp = (uint) value + 5;
		} else if (e.direction == Gdk.ScrollDirection.DOWN) {
			tmp = (uint) value - 5;
		} else {
			return true;
		}

		// TODO: Remove this once vala supports proper closures.
		_tmp_apply_volume_value = (int) tmp;

		_apply_volume (0);

		return true;
	}

	public void on_volume_changed (Client c, Xmms.Value val) {
		unowned Xmms.DictIter iter;
		int total_volume, channels;

		if (!_accept_updates) {
			return;
		}

		total_volume = 0;
		channels = 0;

		val.get_dict_iter (out iter);
		while (iter.valid ()) {
			unowned Xmms.Value volume;
			unowned string name;
			int tmp = 0;

			if (iter.pair (out name, out volume)) {
				if (volume.get_int (out tmp)) {
					total_volume += tmp;
					channels++;
				}
			}
			iter.next ();
		}

		if (channels > 0) {
			_tmp_apply_volume_value = (int) (total_volume / channels * 1.0);
			value = _tmp_apply_volume_value;
		}
	}
}
