/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2013 Abraca Team
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

public class Abraca.FilterWidget : Gtk.Paned {
	private FilterSearchBox searchbox;

	public FilterWidget (Client client, MetadataResolver resolver, Config config, Medialib medialib,  Gtk.AccelGroup group)
	{
		Object (orientation: Gtk.Orientation.VERTICAL, position: 200);
		var scrolled = new Gtk.ScrolledWindow(null, null);

		scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
		                    Gtk.PolicyType.AUTOMATIC);

		scrolled.set_shadow_type(Gtk.ShadowType.IN);

		var treeview = new FilterView(client, resolver, medialib);
		scrolled.add(treeview);

		Gdk.ModifierType accel_type;
		uint accel_key;

		Gtk.accelerator_parse("<Primary>l", out accel_key, out accel_type);

		searchbox = new FilterSearchBox (client, config, treeview);
		searchbox.add_accelerator("grab-focus", group, accel_key, accel_type, 0);

		var browser = new FilterBrowser (client, config, searchbox);

		var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
		vbox.pack_start(searchbox, false, false, 2);
		vbox.pack_start(scrolled, true, true, 0);

		pack1 (browser, true, true);
		pack2 (vbox, true, true);
	}

	/** TODO: remove this hack */
	public Searchable get_searchable ()
	{
		return searchbox;
	}
}
