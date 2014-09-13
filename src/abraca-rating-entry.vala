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
	public class RatingEntry : Gtk.DrawingArea, Gtk.Buildable {
		private static Gdk.Pixbuf unrated_icon = Abraca.Icons.by_name("abraca-unrated", Gtk.IconSize.MENU);
		private static Gdk.Pixbuf rated_icon = Abraca.Icons.by_name("abraca-rated", Gtk.IconSize.MENU);

		private int? volatile_rating = null;

		public int min_rating { get; set; default = 0; }
		public int max_rating { get; set; default = 5; }
		public int rating { get; set; }

		public signal void changed();

		construct
		{
			add_events (Gdk.EventMask.BUTTON_PRESS_MASK |
			            Gdk.EventMask.POINTER_MOTION_MASK |
			            Gdk.EventMask.LEAVE_NOTIFY_MASK);
			update_size_request();
		}


		/* TODO: Should use adjust_size_request but that's broken in GIR */
		public void update_size_request ()
		{
			set_size_request(rated_icon.width * (max_rating - min_rating + 1), rated_icon.height);
		}


		public override bool motion_notify_event (Gdk.EventMotion ev)
		{
			var val = (ev.x / (double) rated_icon.width) + 0.75;
			var tmp = (int) Math.fmin (max_rating, Math.fmax (min_rating, val));

			if (volatile_rating == null || tmp != volatile_rating) {
				volatile_rating = tmp;
				queue_draw ();
			} else {
				volatile_rating = tmp;
			}

			return false;
		}


		public override bool leave_notify_event (Gdk.EventCrossing ev)
		{
			volatile_rating = null;
			queue_draw ();
			return false;
		}


		public override bool button_press_event (Gdk.EventButton ev)
		{
			if (volatile_rating != null) {
				rating = volatile_rating;
				volatile_rating = null;
				changed();
			}

			return false;
		}


		public override bool draw (Cairo.Context cr)
		{
			var value = (volatile_rating == null) ? rating : volatile_rating;

			for (var i = min_rating; i < max_rating; i++) {
				if (i < (value - min_rating)) {
					Gdk.cairo_set_source_pixbuf (cr, rated_icon, i * rated_icon.width, 0);
				} else {
					Gdk.cairo_set_source_pixbuf (cr, unrated_icon, i * rated_icon.width, 0);
				}
				cr.paint ();
			}

			return false;
		}
	}
}
