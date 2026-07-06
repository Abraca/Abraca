/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2009-2014 Abraca Team
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

namespace Abraca.Icons {
	private struct Icon {
		unowned string name;
		unowned string filename;
	}

	/**
	 * Abraca's bundled icons, keyed by logical name. GTK4 removed the
	 * builtin-icon registry (Gtk.IconTheme.add_builtin_icon), so these are
	 * loaded straight from the compiled-in GResource on demand.
	 */
	private const Icon[] STOCK_ICONS = {
		{ "abraca-icon",       "abraca-32.png"             },
		{ "abraca-equalizer",  "abraca-equalizer.png"      },
		{ "abraca-collection", "abraca-collection-24.png"  },
		{ "abraca-playlist",   "abraca-playlist-24.png"    },
		{ "abraca-rated",      "abraca-rating-rated.png"   },
		{ "abraca-unrated",    "abraca-rating-unrated.png" },
		{ "abraca-favorite",   "abraca-favorite.png"       }
	};

	private static unowned string filename_for(string name)
	{
		foreach (unowned var icon in STOCK_ICONS) {
			if (icon.name == name)
				return icon.filename;
		}
		GLib.error("Unknown icon '%s'. Programming error.", name);
	}

	public static Gdk.Pixbuf by_name(string name)
	{
		try {
			return new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/%s".printf(filename_for(name)));
		} catch (GLib.Error e) {
			GLib.error("Could not load icon '%s': %s", name, e.message);
		}
	}

	public static Gdk.Texture texture_by_name(string name)
	{
		return Gdk.Texture.for_pixbuf(by_name(name));
	}
}
