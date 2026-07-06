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
using GLib;

namespace Abraca {
	public class FilterEditor : Adw.Dialog {
		public signal void column_changed (string property, bool enabled);

		private class PropertyItem : GLib.Object {
			public string name { get; construct; }
			public bool active { get; set; default = false; }
			public PropertyItem (string name) { Object (name: name); }
		}

		private const string[] _properties = {
			"id", "added", "album", "artist", "bitrate", "comment", "date",
			"duration", "genre", "laststarted", "lmod", "mime", "size",
			"status", "timesplayed", "title", "tracknr", "url"
		};

		private GLib.ListStore store;

		public FilterEditor ()
		{
			title = _("Select Columns");
			content_width = 260;
			content_height = 360;

			store = new GLib.ListStore (typeof (PropertyItem));
			foreach (unowned string prop in _properties)
				store.append (new PropertyItem (prop));

			var factory = new Gtk.SignalListItemFactory ();
			factory.setup.connect (li => {
				((Gtk.ListItem) li).set_child (new Gtk.CheckButton ());
			});
			factory.bind.connect (li => {
				var item = (PropertyItem) ((Gtk.ListItem) li).get_item ();
				var check = (Gtk.CheckButton) ((Gtk.ListItem) li).get_child ();
				check.label = item.name;
				check.active = item.active;
				var handler = check.toggled.connect (() => {
					on_toggled (item, check);
				});
				((Gtk.ListItem) li).set_data<ulong> ("handler", handler);
			});
			factory.unbind.connect (li => {
				var check = (Gtk.CheckButton) ((Gtk.ListItem) li).get_child ();
				var handler = ((Gtk.ListItem) li).get_data<ulong> ("handler");
				if (handler != 0)
					check.disconnect (handler);
			});

			var view = new Gtk.ColumnView (new Gtk.NoSelection (store));
			view.append_column (new Gtk.ColumnViewColumn (null, factory));

			var scrolled = new Gtk.ScrolledWindow () {
				hscrollbar_policy = Gtk.PolicyType.NEVER,
				vexpand = true,
				child = view
			};

			set_child (scrolled);
		}

		private int count_active ()
		{
			int n = 0;
			for (uint i = 0; i < store.get_n_items (); i++)
				if (((PropertyItem) store.get_item (i)).active)
					n++;
			return n;
		}

		private void on_toggled (PropertyItem item, Gtk.CheckButton check)
		{
			/* Never let the last active column be turned off. */
			if (!check.active && count_active () <= 1) {
				check.active = true;
				return;
			}
			item.active = check.active;
			column_changed (item.name, item.active);
		}

		public void set_active (string[] active)
		{
			for (uint i = 0; i < store.get_n_items (); i++) {
				var item = (PropertyItem) store.get_item (i);
				item.active = (item.name in active);
			}
		}
	}
}
