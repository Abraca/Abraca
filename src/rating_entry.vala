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

namespace Abraca {
	public class RatingEntry : Gtk.EventBox {
		private Gdk.Pixbuf _canvas;
		private int _width;
		private int _height;

		public int min_rating {
			get; set; default = 0;
		}

		public int max_rating {
			get; set; default = 5;
		}

		private int _rating = -1;

		public int rating {
			get {
				return _rating;
			}
			set {
				if (_rating != value) {
					_rating = value;
					changed();
				} else {
					_rating = value;
				}
			}
		}

		/* TODO: Load icon here */
		public Gdk.Pixbuf unrated_icon {
			get; set;
		}
		/* TODO: Load icon here */
		public Gdk.Pixbuf rated_icon {
			get; set;
		}

		public signal void changed();

		construct {
			string filename;

			try {
				Gdk.Pixbuf tmp = new Gdk.Pixbuf.from_inline (
					-1, Resources.abraca_rating_unrated, false
				);
				unrated_icon = tmp;
			} catch (GLib.Error e) {
				GLib.stderr.printf("ERROR: %s\n", e.message);
			}

			try {
				Gdk.Pixbuf tmp = new Gdk.Pixbuf.from_inline (
					-1, Resources.abraca_rating_rated, false
				);
				rated_icon = tmp;
			} catch (GLib.Error e) {
				GLib.stderr.printf("ERROR: %s\n", e.message);
			}

			_width =  rated_icon.width * (max_rating - min_rating + 1);
			_height = rated_icon.height;

			_canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, _width, _height);

			expose_event += on_expose_event;
			size_request += on_size_request;

			motion_notify_event += (w, e) => {
				rating_from_position(((Gdk.EventMotion) e).x);
				return true;
			};
			button_press_event += (w, e) => {
				rating_from_position(((Gdk.EventButton) e).x);
				return true;
			};

			changed += update_rating;

			rating = min_rating;
		}


		/**
		 * Update the canvas to match the new rating.
		 */
		public void update_rating (RatingEntry entry) {
			_canvas.fill((uint) 0xffffff00);

			for (int i = min_rating; i < max_rating; i++) {
				if (i < _rating - min_rating) {
					rated_icon.copy_area(
						0, 0, rated_icon.width, rated_icon.height,
						_canvas, i * rated_icon.width, 0
					);
				} else {
					unrated_icon.copy_area(
						0, 0, unrated_icon.width, unrated_icon.height,
						_canvas, i * unrated_icon.width, 0
					);
				}
			}

			queue_draw();
		}


		/**
		 * Translate a position to a rating value.
		 */
		public void rating_from_position (double pos) {
			int val = (int) (pos / (double) rated_icon.width) + 1;

			if (val > max_rating) {
				val = max_rating;
			} else if (val < min_rating) {
				val = min_rating;
			}

			rating = val;
		}


		/**
		 * Paint our canvas on the window.
		 */
		public bool on_expose_event(Gtk.Widget w, Gdk.Event evnt) {
			weak Gdk.EventExpose e = (Gdk.EventExpose) evnt;

			e.window.draw_pixbuf(
				style.bg_gc[0], _canvas,
				0, 0, 0, 0, _width, _height,
				Gdk.RgbDither.NONE, 0, 0
			);
			
			return true;
		}


		/**
		 * Update the size of the rating widget.
		 */
		public void on_size_request (Gtk.Widget w, Gtk.Requisition req) {
			req.width = _canvas.width;
			req.height = _canvas.height;
		}
	}
}
