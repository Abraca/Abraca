/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2009-2011  Abraca Team
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
	public class CellRendererTogglePixbuf : Gtk.CellRendererPixbuf {
		public bool active { get; set; default=false; }
		public bool activatable { get; set; default=true; }

		public signal void toggled(string updated);

		construct {
			mode = Gtk.CellRendererMode.ACTIVATABLE;
		}

		public override void render (Cairo.Context cr, Gtk.Widget widget,
		                             Gdk.Rectangle background_area,
		                             Gdk.Rectangle cell_area,
		                             Gtk.CellRendererState flags)
		{
			if (active) {
				base.render(cr, widget, background_area, cell_area, flags);
				return;
			}

			if (pixbuf == null) {
				if (stock_id == null) {
					return;
				}
				pixbuf = widget.render_icon(stock_id, (Gtk.IconSize) stock_size, stock_detail);
			}

			var pixels = (uchar*) pixbuf.pixels;
			var rowstride = pixbuf.rowstride;
			var n_channels = pixbuf.n_channels;

			GLib.return_if_fail(pixbuf.colorspace == Gdk.Colorspace.RGB);
			GLib.return_if_fail(n_channels >= 3);
			GLib.return_if_fail(pixbuf.bits_per_sample == 8);

			var original_pixbuf = pixbuf.copy();

			for (int y = 0; y < pixbuf.height; y++) {
				uchar* p = pixels + y * rowstride;

				for (int x = 0; x < pixbuf.width; x++) {
					p[0] = p[1] = p[2] = (uchar) (0.3 * (double) p[0] + 0.6 * (double) p[1] + 0.1 * (double) p[2]);
					p += n_channels;
				}
			}

			base.render(cr, widget, background_area, cell_area, flags);

			pixbuf = original_pixbuf;
		}

		public override bool activate(Gdk.Event event, Gtk.Widget widget,
									  string path, Gdk.Rectangle background_area,
									  Gdk.Rectangle cell_area,
									  Gtk.CellRendererState flags) {
			if (activatable) {
				toggled(path);
				return true;
			}

			return false;
		}
	}
}
