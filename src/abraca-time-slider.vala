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

public class Abraca.TimeSlider : Gtk.Scale {
	private Client client;

	private bool is_seeking = false;

	private uint position_msec = 0;
	private uint duration_msec = 0;

	public TimeSlider(Client c)
	{
		Object(orientation: Gtk.Orientation.HORIZONTAL, digits: 4, draw_value: false);

		adjustment.lower = 0.0;
		adjustment.upper = 1.0;

		client = c;
		client.playback_playtime.connect(on_playback_playtime);
		client.playback_current_info.connect(on_playback_current_info);

		/* Observe presses/releases in the capture phase so the Scale's own
		 * drag gesture keeps working; we only track the seeking state and
		 * commit the seek once the user lets go. */
		var click = new Gtk.GestureClick ();
		click.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
		click.pressed.connect (on_pressed);
		click.released.connect (on_released);
		add_controller (click);
	}

	private void on_pressed (int n_press, double x, double y)
	{
		is_seeking = true;
	}

	private void on_released (int n_press, double x, double y)
	{
		var position_msec = (uint)(duration_msec * get_value());
		client.xmms.playback_seek_ms(position_msec, Xmms.PlaybackSeekMode.SET);
		is_seeking = false;
	}

	private void on_playback_current_info (Xmms.Value current_info)
	{
		if (!current_info.dict_entry_get_int("duration", out duration_msec)) {
			duration_msec = 0;
		}
	}

	private void on_playback_playtime (Client c, int position)
	{
		if (!is_seeking) {
			if (client.current_playback_status == Xmms.PlaybackStatus.STOP) {
				position_msec = 0;
			} else {
				position_msec = position;
			}

			if (duration_msec > 0) {
				double percent = (double) position_msec / (double) duration_msec;
				set_value(percent);
				set_sensitive(true);
			} else {
				set_value(0);
				set_sensitive(false);
			}
		}
	}
}