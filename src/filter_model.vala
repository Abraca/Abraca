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

		/* Map medialib id to row */
		/* TODO: Should probably be iters instead */
		private GLib.HashTable<int,Gtk.TreeRowReference> pos_map;

		construct {
			/* To be set dynamically
			 * TODO: Pos 0 = status, Pos 1 = mid always
			 */
			set_column_types(new GLib.Type[7] {
					typeof(int),
					typeof(uint),
					typeof(string),
					typeof(string),
					typeof(string),
					typeof(string),
					typeof(string)
			});

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
			bool first = true;

			clear();

			pos_map.for_each((key, val) => {
				((Gtk.TreeRowReference) val).free();
			}, null);

			pos_map.remove_all();

			get_iter_first(out iter);

			for (res.list_first(); res.list_valid(); res.list_next()) {
				Gtk.TreeRowReference row;
				Gtk.TreePath path;
				uint id;
				int pos;

				if (!res.get_uint(out id))
					continue;

				if (first) {
					insert_after(out iter, null);
					first = !first;
				} else {
					insert_after(out iter, sibling);
				}

				set(iter, Column.STATUS, Status.UNRESOLVED);
				set(iter, Column.ID, id);

				sibling = iter;

				path = get_path(iter);
				row = new Gtk.TreeRowReference(this, path);

				pos_map.insert(id.to_pointer(), #row);
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

		/**
		 * TODO: This sucks a bit, should handle dynamic columns.
		 */
		private void on_medialib_info(Xmms.Result #res) {
			weak string artist, album, title;
			weak Gtk.TreeRowReference row;
			weak Gtk.TreePath path;
			Gtk.TreeIter iter;
			int mid, pos, id;
			string info;

			res.get_dict_entry_int("id", out mid);

			row = (Gtk.TreeRowReference) pos_map.lookup(mid.to_pointer());
			if (row == null || !row.valid()) {
				return;
			}

			if (!res.get_dict_entry_string("artist", out artist)) {
				artist = _("Unknown");
			}
			if (!res.get_dict_entry_string("album", out album)) {
				album = _("Unknown");
			}
			if (!res.get_dict_entry_string("title", out title)) {
				title = _("Unknown");
			}

			path = row.get_path();

			if (get_iter(out iter, path)) {
				set(iter, Column.STATUS, Status.RESOLVED, 2, artist, 3, title, 4, album);
			}
		}
	}
}
