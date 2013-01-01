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

public class Abraca.FilterBrowserModel : Gtk.ListStore, Gtk.TreeModel {
	private Client client;

	public string field {
		get; construct;
	}

	public Xmms.Collection filter {
		set; get; default = Xmms.Collection.universe();
	}

	public signal void selection_changed (Xmms.Collection selection);

	private GLib.Type[] types = new GLib.Type[] { typeof(string) };

	public FilterBrowserModel (Client client, string field) {
		Object (field: field);

		set_column_types(types);

		this.client = client;

		client.connection_state_changed.connect ((_,state) => {
			if (state == Client.ConnectionState.Connected)
				refresh();
		});

		notify["filter"].connect ((s, p) => {
			refresh();
		});
	}

	private bool on_coll_query_infos(Xmms.Value values) {
		unowned Xmms.ListIter iter;

		clear();

		if (values.is_error()) {
			unowned string error = "unknown";
			values.get_error(out error);
			GLib.debug("Failed to query (%s)", error);
			return false;
		}

		values.get_list_iter(out iter);
		for (iter.first(); iter.valid(); iter.next()) {
			Gtk.TreeIter? tree_iter;
			unowned string value;
			Xmms.Value entry;

			iter.entry(out entry);

			entry.dict_entry_get_string(field, out value);

			append(out tree_iter);
			set(tree_iter, 0, GLib.Markup.escape_text (value));
		}

		return false;
	}

	private void refresh () {
		var values = new Xmms.Value.from_list();
		values.list_append (new Xmms.Value.from_string (field));

		var coll = new Xmms.Collection (Xmms.CollectionType.HAS);
		coll.attribute_set ("field", field);
		coll.add_operand (filter);

		client.xmms.coll_query_infos (coll, values, 0, 0, values, values).notifier_set (
			on_coll_query_infos
		);
	}
}
