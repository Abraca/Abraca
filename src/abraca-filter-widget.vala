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

/* TODO: This is a hack.. fix me... */
public interface Abraca.Searchable : GLib.Object {
	public abstract void search (string query);
}

/* GtkPaned is final in GTK4, so wrap it rather than subclass. */
public class Abraca.FilterWidget : Gtk.Widget {
	private FilterSearchBox searchbox;
	private Gtk.Paned paned;

	public FilterWidget (Client client, MetadataResolver resolver, Config config, Medialib medialib)
	{
		set_layout_manager (new Gtk.BinLayout ());
		hexpand = true;
		vexpand = true;

		paned = new Gtk.Paned (Gtk.Orientation.VERTICAL) { position = 200 };

		var scrolled = new Gtk.ScrolledWindow();
		scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
		                    Gtk.PolicyType.AUTOMATIC);
		scrolled.vexpand = true;

		var treeview = new FilterView(client, resolver, medialib);
		scrolled.set_child(treeview);

		searchbox = new FilterSearchBox (client, config, treeview);

		var browser = new FilterBrowser (client, config, searchbox);

		var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
		vbox.append(searchbox);
		vbox.append(scrolled);

		paned.set_start_child (browser);
		paned.set_resize_start_child (true);
		paned.set_end_child (vbox);
		paned.set_resize_end_child (true);

		paned.set_parent (this);
	}

	public override void dispose ()
	{
		if (paned != null) {
			paned.unparent ();
			paned = null;
		}
		base.dispose ();
	}

	/** TODO: remove this hack */
	public Searchable get_searchable ()
	{
		return searchbox;
	}
}
