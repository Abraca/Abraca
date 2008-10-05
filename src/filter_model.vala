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

		public PropertyList dynamic_columns {
			get; construct;
		}

		/* Map medialib id to row */
		/* TODO: Should probably be iters instead */
		private GLib.HashTable<int,Gtk.TreeRowReference> pos_map;

		public FilterModel (PropertyList props) {
			dynamic_columns = props;
		}

		construct {
			int n_columns = dynamic_columns.get_length();

			GLib.Type[] types = new GLib.Type[2 + n_columns];

			types[0] = typeof(int);
			types[1] = typeof(uint);

			for (int i = 0; i < n_columns; i++) {
				types[2 + i] = typeof(string);
			}
			set_column_types(types);

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
		public void replace_content (Xmms.Result res) {
			Gtk.TreeIter iter, sibling;
			bool is_first = true;

			clear();

			pos_map.remove_all();

			get_iter_first(out iter);

			for (res.list_first(); res.list_valid(); res.list_next()) {
				Gtk.TreeRowReference row;
				Gtk.TreePath path;
				uint id;
				int pos;

				if (!res.get_uint(out id))
					continue;

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

				pos_map.insert((int) id, #row);
			}
		}


		/**
		 * When GTK asks for the value of a column, check if the row
		 * has been resolved or not, otherwise resolve it.
		 */
		public void get_value(Gtk.TreeIter iter, int column, ref GLib.Value val) {
			GLib.Value tmp1, tmp2;

			base.get_value(iter, Column.STATUS, ref tmp1);
			if (((Status)tmp1.get_int()) == Status.UNRESOLVED) {
				Client c = Client.instance();

				base.get_value(iter, Column.ID, ref tmp2);

				set(iter, Column.STATUS, Status.RESOLVING);

				c.xmms.medialib_get_info(tmp2.get_uint()).notifier_set(
					on_medialib_info
				);
			}

			base.get_value(iter, column, ref val);
		}

		private void on_medialib_info(Xmms.Result #res) {
			weak Gtk.TreeRowReference row;
			Gtk.TreePath path;
			Gtk.TreeIter iter;
			int mid, id;
			string info;

			res.get_dict_entry_int("id", out mid);

			row = (Gtk.TreeRowReference) pos_map.lookup(mid);
			if (row == null || !row.valid()) {
				return;
			}

			path = row.get_path();

			if (get_iter(out iter, path)) {
				set(iter, Column.STATUS, Status.RESOLVED);

				int pos = 2;
				foreach (weak string key in dynamic_columns.get()) {
					GLib.Value tmp;
					get_string_from_dict(res, key, out tmp);
					set_value(iter, pos++, tmp);
					tmp.unset();
				}

			}
		}

		private bool get_string_from_dict (Xmms.Result res, string key, out GLib.Value val) {
			bool ret = true;
			string repr;

			switch (res.get_dict_entry_type(key)) {
				case Xmms.ResultType.INT32:
					int tmp;
					if (!res.get_dict_entry_int(key, out tmp)) {
						repr = "%s".printf(_("Unknown"));
					} else {
						repr = "%d".printf(tmp);
					}
					break;
				case Xmms.ResultType.UINT32:
					uint tmp;
					if (!res.get_dict_entry_uint(key, out tmp)) {
						repr = "%s".printf(_("Unknown"));
					} else {
						repr = "%u".printf(tmp);
					}
					break;
				case Xmms.ResultType.STRING:
					if (!res.get_dict_entry_string(key, out repr)) {
						repr = "%s".printf(_("Unknown"));
					} else {
						repr = "%s".printf(repr);
					}
					break;
				default:
					break;
			}

			val = GLib.Value(typeof(string));
			val.take_string(repr);

			return ret;
		}
	}
}
