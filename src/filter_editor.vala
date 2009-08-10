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
	public class FilterEditor : Gtk.Dialog {
		public signal void column_changed(string property, bool enabled);

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

		construct {
			Gtk.Notebook notebook;
			Gtk.Widget child;

			set_size_request(310, 310);

			title = _("Select Columns");
			
			border_width = 5;
			transient_for = Abraca.instance().main_window;
			has_separator = false;
			resizable = false;

			notebook = new Gtk.Notebook();
			notebook.show_tabs = false;

			child = create_child();

			notebook.append_page(child, new Gtk.Label("Columns"));
			notebook.border_width = 6;


			Gtk.Button button = new Gtk.Button.from_stock(Gtk.STOCK_OK);
			button.clicked += (widget) => {
				destroy();
			};

			action_area.add(button);
			action_area.border_width = 0;
			action_area.spacing = 0;

			vbox.border_width = 0;
			vbox.pack_start(notebook, true, true, 0);
			vbox.set_child_packing(action_area, false, false, 0, Gtk.PackType.END);

			response += (widget,response) => {
				destroy();
			};

			show_all();
		}

		public void set_active(string[] active) {
			Gtk.ListStore model;
			Gtk.TreeIter iter;

			model = (Gtk.ListStore) _view.model;

			model.get_iter_first(out iter);
			do {
				weak string prop;

				model.get(iter, Column.NAME, out prop);

				foreach (weak string active_prop in active) {
					if (prop == active_prop) {
						model.set(iter, Column.ACTIVE, true);
						break;
					}
				}
			} while (_view.model.iter_next(ref iter));
		}

		private Gtk.Widget create_child() {
			Gtk.CellRendererToggle renderer;
			Gtk.ScrolledWindow scrolled;
			Gtk.TreeViewColumn column;
			Gtk.ListStore model;

			model = new Gtk.ListStore(2, typeof(bool), typeof(string));

			foreach (weak string prop in _properties) {
				Gtk.TreeIter iter;

				model.append(out iter);
				model.set(iter, Column.ACTIVE, false, Column.NAME, prop);
			}

			_view = new Gtk.TreeView();
			_view.headers_visible = false;
			_view.model = model;

			renderer = new Gtk.CellRendererToggle();
			renderer.toggled += on_entry_toggled;

			column = new Gtk.TreeViewColumn.with_attributes(
				"column", renderer, "active", 0
		  	);
			column.resizable = false;
			column.fixed_width = 30;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			_view.append_column(column);
						
			column = new Gtk.TreeViewColumn.with_attributes(
				"column", new Gtk.CellRendererText(), "text", 1, null
			);
			column.resizable = false;
			column.fixed_width = 120;
			column.sizing = Gtk.TreeViewColumnSizing.FIXED;
			_view.append_column(column);

			scrolled = new Gtk.ScrolledWindow(null, null);
			scrolled.add_with_viewport(_view);
			scrolled.set_border_width(10);
			scrolled.set_policy(
				Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC
			);

			return scrolled;
		}

		private void on_entry_toggled (Gtk.CellRendererToggle renderer, string updated) {
			Gtk.ListStore store;
			Gtk.TreePath path;
			Gtk.TreeIter iter;
			weak string property;
			bool state;

			store = (Gtk.ListStore) _view.model;

			path = new Gtk.TreePath.from_string(updated);
			store.get_iter(out iter, path);

			store.get(iter, Column.ACTIVE, out state, Column.NAME, out property);
			state = !state;
			store.set(iter, Column.ACTIVE, state);

			column_changed(property, state);
		}
	}
}