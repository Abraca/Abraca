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
	public class FilterEditor : Gtk.Dialog {
		public signal void column_changed (string property, bool enabled);

		public enum Column {
			ACTIVE,
			NAME,
		}

		private const string[] _properties = {
			"id",
			"added",
			"album",
			"artist",
			"bitrate",
			"comment",
			"date",
			"duration",
			"genre",
			"laststarted",
			"lmod",
			"mime",
			"size",
			"status",
			"timesplayed",
			"title",
			"tracknr",
			"url"
		};

		private Gtk.TreeView _view;

		public FilterEditor ()
		{
			set_size_request(310, 310);

			title = _("Select Columns");

			var child = create_child();

			add_button(_("Ok"), 0);

			var box = get_content_area() as Gtk.Box;
			box.pack_start(child, true, true, 0);

			response.connect((widget,response) => {
				destroy();
			});

			show_all();
		}


		public void set_active (string[] active)
		{
			Gtk.TreeIter iter;

			var model = _view.model as Gtk.ListStore;

			model.get_iter_first(out iter);
			do {
				unowned string prop;

				model.get(iter, Column.NAME, out prop);

				foreach (unowned string active_prop in active) {
					if (prop == active_prop) {
						model.set(iter, Column.ACTIVE, true);
						break;
					}
				}
			} while (_view.model.iter_next(ref iter));
		}


		private Gtk.Widget create_child ()
		{
			Gtk.TreeViewColumn column;

			var model = new Gtk.ListStore(2, typeof(bool), typeof(string));

			foreach (unowned string prop in _properties) {
				Gtk.TreeIter iter;

				model.append(out iter);
				model.set(iter, Column.ACTIVE, false, Column.NAME, prop);
			}

			_view = new Gtk.TreeView();
			_view.headers_visible = false;
			_view.model = model;

			var renderer = new Gtk.CellRendererToggle();
			renderer.toggled.connect(on_entry_toggled);

			column = new Gtk.TreeViewColumn.with_attributes(
				"column", renderer, "active", Column.ACTIVE
			);
			column.resizable = false;
			column.fixed_width = 30;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			_view.append_column(column);

			column = new Gtk.TreeViewColumn.with_attributes(
				"column", new Gtk.CellRendererText(), "text", Column.NAME, null
			);
			column.resizable = false;
			column.fixed_width = 120;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			_view.append_column(column);

			var scrolled = new Gtk.ScrolledWindow(null, null);
			scrolled.add(_view);
			scrolled.set_border_width(10);
			scrolled.set_policy(
				Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC
			);

			return scrolled;
		}


		private void on_entry_toggled (Gtk.CellRendererToggle renderer, string updated)
		{
			Gtk.TreeIter iter;
			unowned string property;
			bool state;
			int n_active = 0;

			var store = _view.model as Gtk.ListStore;

			store.get_iter_first(out iter);
			do {
				store.get(iter, Column.ACTIVE, out state);
				if (state) {
					n_active++;
				}
			} while (store.iter_next(ref iter));

			var path = new Gtk.TreePath.from_string(updated);
			store.get_iter(out iter, path);
			store.get(iter, Column.ACTIVE, out state, Column.NAME, out property);

			state = !state;
			if (n_active > 1 || state) {
				store.set(iter, Column.ACTIVE, state);
				column_changed(property, state);
			}
		}
	}
}
