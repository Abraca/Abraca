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
	public class CellRendererCollection : Gtk.CellRendererText {
		public unowned Gdk.Pixbuf pixbuf {
			get; set;
		}

		public override void render (Cairo.Context cr, Gtk.Widget widget,
		                             Gdk.Rectangle background_area,
		                             Gdk.Rectangle cell_area,
		                             Gtk.CellRendererState flags)
		{
			base.render(cr, widget, background_area, cell_area, flags);

			if (pixbuf == null)
				return;

			var xpos = cell_area.x - (pixbuf.width + 4);
			var ypos = cell_area.y;

			Gdk.cairo_set_source_pixbuf (cr, pixbuf, xpos, ypos);
			cr.paint ();
		}
	}
}
