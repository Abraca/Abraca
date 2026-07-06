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
	public class RatingEntry : Gtk.Widget, Gtk.Buildable {
		private static Gdk.Texture unrated_icon = Abraca.Icons.texture_by_name("abraca-unrated");
		private static Gdk.Texture rated_icon = Abraca.Icons.texture_by_name("abraca-rated");

		private int? volatile_rating = null;

		public int min_rating { get; set; default = 0; }
		public int max_rating { get; set; default = 5; }
		public int rating { get; set; }

		public signal void changed();

		construct
		{
			var motion = new Gtk.EventControllerMotion ();
			motion.motion.connect (on_motion);
			motion.leave.connect (on_leave);
			add_controller (motion);

			var click = new Gtk.GestureClick ();
			click.pressed.connect (on_pressed);
			add_controller (click);

			update_size_request();
		}


		public void update_size_request ()
		{
			set_size_request(rated_icon.get_width() * (max_rating - min_rating + 1), rated_icon.get_height());
		}


		private void on_motion (double x, double y)
		{
			var val = (x / (double) rated_icon.get_width()) + 0.75;
			var tmp = (int) Math.fmin (max_rating, Math.fmax (min_rating, val));

			if (volatile_rating == null || tmp != volatile_rating) {
				volatile_rating = tmp;
				queue_draw ();
			} else {
				volatile_rating = tmp;
			}
		}


		private void on_leave ()
		{
			volatile_rating = null;
			queue_draw ();
		}


		private void on_pressed (int n_press, double x, double y)
		{
			if (volatile_rating != null) {
				rating = volatile_rating;
				volatile_rating = null;
				changed();
			}
		}


		public override void snapshot (Gtk.Snapshot snapshot)
		{
			var value = (volatile_rating == null) ? rating : volatile_rating;
			var w = rated_icon.get_width ();

			for (var i = min_rating; i < max_rating; i++) {
				var icon = (i < (value - min_rating)) ? rated_icon : unrated_icon;
				Graphene.Rect rect = {};
				rect.init (i * w, 0, icon.get_width (), icon.get_height ());
				snapshot.append_texture (icon, rect);
			}
		}
	}
}
