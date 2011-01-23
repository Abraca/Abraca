/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2011  Abraca Team
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
		private Gdk.Pixbuf _unrated_icon = null;
		private Gdk.Pixbuf _rated_icon = null;

		private int _rating = 0;
		private int? _volatile_rating = null;

		public int min_rating { get; set; default = 0; }
		public int max_rating { get; set; default = 5; }

		public int rating {
			get {
				return _rating;
			}
			set {
				if (_rating != value) {
					_rating = value;
					changed ();
				}
			}
		}

		public Gdk.Pixbuf unrated_icon {
			get {
				if (_unrated_icon == null)
					_unrated_icon = render_icon (STOCK_UNRATED, Gtk.IconSize.MENU, null);
				return _unrated_icon;
			}
			set {
				_unrated_icon = value;
			}
		}

		public Gdk.Pixbuf rated_icon {
			get {
				if (_rated_icon == null)
					_rated_icon = render_icon (STOCK_RATED, Gtk.IconSize.MENU, null);
				return _rated_icon;
			}
			set {
				_rated_icon = value;
			}
		}

		public signal void changed();


		construct
		{
			add_events (Gdk.EventMask.BUTTON_PRESS_MASK |
			            Gdk.EventMask.POINTER_MOTION_MASK |
			            Gdk.EventMask.LEAVE_NOTIFY_MASK);
		}


		public override void size_request (out Gtk.Requisition requisition)
		{
			requisition.width = rated_icon.width * (max_rating - min_rating + 1);
			requisition.height = rated_icon.height;
		}


		public override bool motion_notify_event (Gdk.EventMotion ev)
		{
			var val = (ev.x / (double) rated_icon.width) + 0.75;
			var tmp = (int) Math.fmin (max_rating, Math.fmax (min_rating, val));

			if (tmp != _volatile_rating) {
				_volatile_rating = tmp;
				queue_draw ();
			} else {
				_volatile_rating = tmp;
			}

			return false;
		}


		public override bool leave_notify_event (Gdk.EventCrossing ev)
		{
			_volatile_rating = null;
			queue_draw ();
			return false;
		}


		public override bool button_press_event (Gdk.EventButton ev)
		{
			if (_volatile_rating != null) {
				rating = _volatile_rating;
				_volatile_rating = null;
			}

			return false;
		}


		public override bool expose_event (Gdk.EventExpose ev)
		{
			var cr = Gdk.cairo_create (ev.window);

			var value = (_volatile_rating == null) ? _rating : _volatile_rating;

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
