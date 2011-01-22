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

public class Abraca.VolumeButton : Gtk.ScaleButton {
	private const int GRACE_PERIOD_USEC = 250 * 1000;

	private const string[] _icons = {
		"stock_volume-mute",
		"stock_volume-max",
		"stock_volume-0",
		"stock_volume-min",
		"stock_volume-med",
		null
	};

	private bool _accept_updates = true;

	private int _requested_volume = 0;
	private uint _event_source = 0;
	private GLib.TimeVal _request_volume_updated;

	private Client client;

	public VolumeButton (Client c)
	{
		client = c;

		has_tooltip = true;
		relief = Gtk.ReliefStyle.NONE;

		adjustment.lower = 0;
		adjustment.upper = 100;
		adjustment.step_increment = 5;

		sensitive = false;

		set_icons(_icons);

		pressed.connect((w) => {
			_accept_updates = false;
		});

		released.connect((w) => {
			_accept_updates = true ;
		});

		scroll_event.connect(on_scroll_event);
		value_changed.connect(on_request_volume);
		client.playback_volume.connect(on_volume_changed);
	}


	private void on_request_volume (Gtk.ScaleButton w, double volume)
	{
		request_volume (volume);
	}


	private void request_volume (double volume)
	{
		_request_volume_updated = GLib.TimeVal ();
		_request_volume_updated.add (GRACE_PERIOD_USEC);

		_requested_volume = (int) volume;

		if (_event_source == 0)
			_event_source = GLib.Timeout.add (125, apply_volume);
	}


	private bool apply_volume () {
		var now = GLib.TimeVal ();

		var d_sec = now.tv_sec - _request_volume_updated.tv_sec;
		var d_usec = now.tv_usec - _request_volume_updated.tv_usec;

		if (!(d_sec > 0 || (d_sec == 0 && d_usec > 0))) {
			/* Too soon since last volume request was performed */
			return true;
		}

		client.xmms.playback_volume_get().notifier_set((val) => {
			if (!val.is_error ()) {
				val.dict_foreach((key, val) => {
					client.xmms.playback_volume_set (key, _requested_volume);
				});
			}
			return true;
		});

		tooltip_text = "%d%%".printf((int) value);

		_event_source = 0;

		return false;
	}


	public bool on_scroll_event (Gtk.Widget w, Gdk.EventScroll e) {
		switch (e.direction) {
			case Gdk.ScrollDirection.UP:
				value += 5;
				break;
			case Gdk.ScrollDirection.DOWN:
				value -= 5;
				break;
			default:
				break;
		}

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
			value = (int) (total_volume / channels * 1.0);
		}

		sensitive = (channels > 0);
	}
}
