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
	/**
	 * A filter row. The metadata columns are dynamic, so instead of fixed
	 * GObject properties the values live in an index-aligned array and a single
	 * `updated` signal tells bound cell widgets to refresh.
	 */
	public class FilterItem : GLib.Object {
		public enum Status {
			UNRESOLVED,
			RESOLVING,
			RESOLVED
		}

		public Status status = Status.UNRESOLVED;
		public uint id { get; construct; }

		private string[] columns;

		public signal void updated ();

		public FilterItem (uint id, int n_columns) {
			Object (id: id);
			columns = new string[n_columns];
			for (int i = 0; i < n_columns; i++)
				columns[i] = "";
		}

		public unowned string get_column (int index) {
			return columns[index];
		}

		public void set_column (int index, string value) {
			columns[index] = value;
		}

		public void emit_updated () {
			updated ();
		}
	}

	public class FilterModel : GLib.Object {
		public GLib.ListStore store { get; private set; }

		/* TODO: This should be a property, not just a member variable */
		public string[] dynamic_columns;

		/* Map medialib id to row */
		private Gee.HashMap<uint,FilterItem> pos_map = new Gee.HashMap<uint,FilterItem>();

		private Client client;
		private MetadataRequestor requestor;

		public FilterModel (Client c, MetadataResolver resolver, owned string[] props)
		{
			store = new GLib.ListStore (typeof (FilterItem));

			client = c;

			dynamic_columns = (owned) props;

			requestor = resolver.register(on_resolver_complete);
			requestor.set_attributes(dynamic_columns);

			client.medialib_entry_changed.connect((client, res) => {
				on_medialib_info(res);
			});
		}


		/**
		 * Replaces the content of the filter list model with the
		 * result of a medialib query
		 */
		public bool replace_content (Xmms.Value val)
		{
			store.remove_all();
			pos_map.clear();

			unowned Xmms.ListIter list_iter;
			val.get_list_iter(out list_iter);

			for (list_iter.first(); list_iter.valid(); list_iter.next()) {
				Xmms.Value entry;
				int id = 0;

				if (!(list_iter.entry(out entry) && entry.get_int(out id)))
					continue;

				var item = new FilterItem((uint) id, dynamic_columns.length);
				store.append(item);
				pos_map.set((uint) id, item);
			}

			return true;
		}


		/**
		 * Lazily resolve a row's metadata the first time it becomes visible.
		 */
		public void ensure_resolved (FilterItem item)
		{
			if (item.status != FilterItem.Status.UNRESOLVED)
				return;
			item.status = FilterItem.Status.RESOLVING;
			requestor.resolve((int) item.id);
		}


		private void on_resolver_complete(Xmms.Value value)
		{
			unowned Xmms.ListIter iter;
			Xmms.Value entry;

			value.get_list_iter(out iter);

			while (iter.entry(out entry)) {
				on_medialib_info(entry);
				iter.next();
			}
		}


		private bool on_medialib_info (Xmms.Value val)
		{
			int mid;

			val.dict_entry_get_int("id", out mid);

			var item = pos_map.get((uint) mid);
			if (item == null)
				return false;

			item.status = FilterItem.Status.RESOLVED;

			int i = 0;
			foreach (unowned string key in dynamic_columns) {
				string formatted = "";
				Transform.normalize_dict (val, key, out formatted);
				item.set_column(i++, formatted);
			}

			item.emit_updated();

			return false;
		}
	}
}
