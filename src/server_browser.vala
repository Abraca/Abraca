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
	enum ServerBrowserColumn {
		Url,
		Name,
		Total,
	}

	/**
	 * TODO: Add support for zeroconf-isch stuff that can be
	 *       abstracted for diffrent backends, and not required.
	 */
	public class ServerBrowser : Gtk.Window {
		private Gtk.TreeView view;

		private Gtk.Window parent { get; construct; }

		public ServerBrowser (construct Gtk.Window parent) { }

		construct {
			transient_for = parent;
			modal = true;
			position = (uint) Gtk.WindowPosition.CENTER_ON_PARENT;

			allow_grow = false;
			allow_shrink = false;

			set_size_request(250, 200);

			title = "Available Servers";

			view = new Gtk.TreeView();
			view.headers_visible = false;

 			view.insert_column_with_attributes(
				-1, null, new Gtk.CellRendererText(),
				"markup", ServerBrowserColumn.Name, null
			);

			Gtk.ListStore model = new Gtk.ListStore(
				ServerBrowserColumn.Total,
				typeof(string), typeof(string)
			);

			view.set_model(model);

			Gtk.VBox box = new Gtk.VBox(false, 0);

			box.pack_start(view, true, true, 10);

			Gtk.HBox hbox = new Gtk.HBox(false, 0);

			Gtk.Button btn;
			btn = new Gtk.Button.from_stock(Gtk.STOCK_CONNECT);
			btn.set_size_request(80, -1);

			hbox.pack_end(btn, false, false, 0);
			btn.clicked += on_server_connect;

			btn = new Gtk.Button.from_stock(Gtk.STOCK_NEW);
			btn.set_size_request(80, -1);

			hbox.pack_end(btn, false, false, 6);

			box.pack_end(hbox, false, false, 0);

			border_width = 12;

			add(box);

			resize(200, 150);

			string path, name;

			path = GLib.Environment.get_variable("XMMS_PATH");
			name = GLib.Environment.get_host_name();

			add_entry(name, path);

			show_all();
		}

		private void add_entry(string name, string path) {
			Gtk.ListStore store = (Gtk.ListStore) view.model;
			Gtk.TreeIter iter;
			int pos;

			pos = store.iter_n_children(null);

			store.insert_with_values(
				out iter, pos,
				ServerBrowserColumn.Url, path,
				ServerBrowserColumn.Name, name
			);
		}

		[InstanceLast]
		private void on_server_connect (Gtk.Button btn) {
			Gtk.TreeSelection sel = view.get_selection();
			Gtk.TreeIter iter;

			if (sel.get_selected(null, out iter)) {
				string path;
				view.model.get(iter, ServerBrowserColumn.Url, out path);

				Client c = Client.instance();
				c.try_connect(path);
			}
		}
	}
}
