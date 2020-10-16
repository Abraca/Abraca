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
		int size;
		unowned string filename;
	}

	/**
	 * GtkIconSize:
	 * @GTK_ICON_SIZE_INVALID: Invalid size.
	 * @GTK_ICON_SIZE_MENU: Size appropriate for menus (16px).
	 * @GTK_ICON_SIZE_SMALL_TOOLBAR: Size appropriate for small toolbars (16px).
	 * @GTK_ICON_SIZE_LARGE_TOOLBAR: Size appropriate for large toolbars (24px)
	 * @GTK_ICON_SIZE_BUTTON: Size appropriate for buttons (16px)
	 * @GTK_ICON_SIZE_DND: Size appropriate for drag and drop (32px)
	 * @GTK_ICON_SIZE_DIALOG: Size appropriate for dialogs (48px)
	 *
	 * Built-in stock icon sizes.
	 */
	private const int[] STOCK_SIZES = { -1, 16, 16, 24, 16, 32, 48 };

	private const Icon[] STOCK_ICONS = {
		{ "abraca-icon",       32, "abraca-32.png"             },
		{ "abraca-equalizer",  24, "abraca-equalizer.png"      },
		{ "abraca-collection", 24, "abraca-collection-24.png"  },
		{ "abraca-collection", 16, "abraca-collection-16.png"  },
		{ "abraca-playlist",   24, "abraca-playlist-24.png"    },
		{ "abraca-playlist",   16, "abraca-playlist-16.png"    },
		{ "abraca-rated",      16, "abraca-rating-rated.png"   },
		{ "abraca-unrated",    16, "abraca-rating-unrated.png" },
		{ "abraca-favorite",   16, "abraca-favorite.png"       }
	};

	public static void initialize() throws GLib.Error {
		for (var i = 0; i < STOCK_ICONS.length; i++) {
			var pixbuf = new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/%s".printf(STOCK_ICONS[i].filename));
			Gtk.IconTheme.add_builtin_icon(STOCK_ICONS[i].name, STOCK_ICONS[i].size, pixbuf);
		}
	}

	public static Gdk.Pixbuf by_name(string name, Gtk.IconSize size)
	{
		try {
			var theme = Gtk.IconTheme.get_default();
			return theme.load_icon(name, STOCK_SIZES[size], Gtk.IconLookupFlags.GENERIC_FALLBACK);
		} catch (GLib.Error e) {
			GLib.error("Could not load icon. Programming error.");
		}
	}
}
