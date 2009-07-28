/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008  Abraca Team
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
	public class FilterModel : Gtk.ListStore, Gtk.TreeModel {
		/* Metadata resolve status */

		enum Status {
			UNRESOLVED,
			RESOLVING,
			RESOLVED
		}

		public enum Column {
			STATUS,
			ID
		}

		/* TODO: This should be a property, not just a member variable */
		public string[] dynamic_columns;

		/* Map medialib id to row */
		/* TODO: Should probably be iters instead */
		private GLib.HashTable<int,Gtk.TreeRowReference> pos_map;

		/**
		 * TODO: Get rid of this one...
		 * This method exists due to a bug in Vala that prevents constructors
		 * to accept string[] parameters for initialization. Get rid of this
		 * hack as soon as possible!
		 */
		public static FilterModel create(owned string[] props) {
			FilterModel model = new FilterModel();

			model._set_dynamic_columns((owned) props);

			return model;
		}

		/**
		 * TODO: Get rid of this one too...
		 * Helper method for the factory hack above.
		 */
		public void _set_dynamic_columns (owned string[] props) {
			int n_columns = props.length;

			GLib.Type[] types = new GLib.Type[2 + n_columns];

			types[0] = typeof(int);
			types[1] = typeof(uint);

			for (int i = 0; i < n_columns; i++) {
				types[2 + i] = typeof(string);
			}

			set_column_types(types);

			dynamic_columns = (owned) props;
		}

		construct {
			// TODO: Add proper unreffing here
			pos_map = new GLib.HashTable<int,Gtk.TreeRowReference>(GLib.direct_hash, GLib.direct_equal);

			Client c = Client.instance();
			c.medialib_entry_changed += (client, res) => {
				on_medialib_info(res);
			};
		}


		/**
		 * Replaces the content of the filter list model with the
		 * result of a medialib query
		 */
		public bool replace_content (Xmms.Value val) {
			Gtk.TreeIter? iter, sibling = null;
			bool is_first = !get_iter_first(out iter);

			clear();

			pos_map.remove_all();

			
			weak Xmms.ListIter list_iter;
			val.get_list_iter(out list_iter);

			for (list_iter.first(); list_iter.valid(); list_iter.next()) {
				Gtk.TreeRowReference row;
				Gtk.TreePath path;
				Xmms.Value entry;
				int id = 0;

				if (!(list_iter.entry(out entry) && entry.get_int(out id))) {
					GLib.stdout.printf("crapping out\n");
					continue;
				}

				if (is_first) {
					insert_after(out iter, null);
					is_first = !is_first;
				} else {
					insert_after(out iter, sibling);
				}

				set(iter, Column.ID, id, Column.STATUS, Status.UNRESOLVED);

				sibling = iter;

				path = get_path(iter);
				row = new Gtk.TreeRowReference(this, path);

				pos_map.insert((int) id, (owned) row);
			}

			return true;
		}


		/**
		 * When GTK asks for the value of a column, check if the row
		 * has been resolved or not, otherwise resolve it.
		 */
		public void get_value(Gtk.TreeIter iter, int column, ref GLib.Value val) {
			GLib.Value tmp1;

			base.get_value(iter, Column.STATUS, out tmp1);
			if (((Status)tmp1.get_int()) == Status.UNRESOLVED) {
				GLib.Value tmp2;
				Client c = Client.instance();

				base.get_value(iter, Column.ID, out tmp2);

				set(iter, Column.STATUS, Status.RESOLVING);

				c.xmms.medialib_get_info(tmp2.get_uint()).notifier_set(
					on_medialib_info
				);
			}

			base.get_value(iter, column, out val);
		}

		private bool on_medialib_info(Xmms.Value propdict) {
			weak Gtk.TreeRowReference row;
			Gtk.TreePath path;
			Gtk.TreeIter iter;
			int mid;

			Xmms.Value val = propdict.propdict_to_dict();

			val.dict_entry_get_int("id", out mid);

			row = (Gtk.TreeRowReference) pos_map.lookup(mid);
			if (row == null || !row.valid()) {
				return false;
			}

			path = row.get_path();

			if (get_iter(out iter, path)) {
				set(iter, Column.STATUS, Status.RESOLVED);

				int pos = 2;
				foreach (weak string key in dynamic_columns) {
					string formatted = "";
					Client.transform_dict (val, key, out formatted);
					set(iter, pos++, formatted);
				}
			}

			return false;
		}
	}
}
