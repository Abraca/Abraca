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

namespace Abraca {

	public class TreeRowMap : GLib.Object
	{
		private Gee.Map<int,Gee.List<Gtk.TreeRowReference>> map =
			new Gee.HashMap<int,Gee.List<Gtk.TreeRowReference>>();

		private unowned Gtk.TreeModel model;

		private static bool compare_refs (void *a, void *b)
		{
			unowned Gtk.TreeRowReference fst = (Gtk.TreeRowReference) a;
			unowned Gtk.TreeRowReference snd = (Gtk.TreeRowReference) b;

			return fst.get_path().compare(snd.get_path()) == 0;
		}

		public TreeRowMap (Gtk.TreeModel model)
		{
			this.model = model;
		}

		public void add_iter (int mid, Gtk.TreeIter iter)
		{
			add_path(mid, model.get_path(iter));
		}

		public void add_path (int mid, Gtk.TreePath path)
		{
			if (!map.contains(mid)) {
				map.set(mid, new Gee.LinkedList<Gtk.TreeRowReference>(compare_refs));
			}

			var row_refs = map.get(mid);
			row_refs.add(new Gtk.TreeRowReference(model, path));
		}

		public bool remove_iter (int mid, Gtk.TreeIter iter)
		{
			return remove_path(mid, model.get_path(iter));
		}

		public bool remove_path (int mid, Gtk.TreePath path)
		{
			if (!map.contains(mid)) {
				return false;
			}

			var row_refs = map.get(mid);

			foreach (var row_ref in row_refs) {
				if (row_ref.get_path().compare(path) != 0) {
					continue;
				}

				row_refs.remove(row_ref);

				if (row_refs.size == 0) {
					map.remove(mid);
				}

				return true;
			}

			return false;
		}

		public Gee.List<Gtk.TreeRowReference> get_paths (int mid)
		{
			if (!map.contains(mid)) {
				return new Gee.LinkedList<Gtk.TreeRowReference>();
			}
			return map.get(mid);
		}

		public void clear ()
		{
			map.clear();
		}
	}
}