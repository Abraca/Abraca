/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2009-2013 Abraca Team
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
	public const string STOCK_EQUALIZER  = "abraca-equalizer";
	public const string STOCK_COLLECTION = "abraca-collection";
	public const string STOCK_PLAYLIST   = "abraca-playlist";
	public const string STOCK_RATED      = "abraca-rated";
	public const string STOCK_UNRATED    = "abraca-unrated";
	public const string STOCK_FAVORITE   = "abraca-favorite";

	public static Gtk.IconFactory create_icon_factory() throws GLib.Error {
		Gtk.IconFactory factory = new Gtk.IconFactory();
		Gtk.IconSet set;
		Gtk.IconSource source;


		/* Equalizer icon */
		set = new Gtk.IconSet();

		source = new Gtk.IconSource();
		source.set_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-equalizer.png"));
		set.add_source(source);

		factory.add(STOCK_EQUALIZER, set);

		/* Collection icon */

		set = new Gtk.IconSet();

		source = new Gtk.IconSource();
		source.set_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-collection-24.png"));
		set.add_source(source);

		source = new Gtk.IconSource();
		source.set_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-collection-16.png"));
		source.set_size(Gtk.IconSize.MENU);
		source.set_size_wildcarded(false);
		set.add_source(source);

		factory.add(STOCK_COLLECTION, set);

		/* Playlist icon */

		set = new Gtk.IconSet();

		source = new Gtk.IconSource();
		source.set_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-playlist-24.png"));
		set.add_source(source);

		source = new Gtk.IconSource();
		source.set_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-playlist-16.png"));
		source.set_size(Gtk.IconSize.MENU);
		source.set_size_wildcarded(false);
		set.add_source(source);

		factory.add(STOCK_PLAYLIST, set);

		/* Other icons */

		factory.add(STOCK_RATED,    new Gtk.IconSet.from_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-rating-rated.png")));
		factory.add(STOCK_UNRATED,  new Gtk.IconSet.from_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-rating-unrated.png")));
		factory.add(STOCK_FAVORITE, new Gtk.IconSet.from_pixbuf(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-favorite.png")));

		return factory;
	}
}
