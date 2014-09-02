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

[GtkTemplate(ui = "/org/xmms2/Abraca/ui/abraca-server-browser.ui")]
public class Abraca.ServerBrowserDialog : Gtk.Dialog
{
	public signal void launch ();
	public signal void remote_selected (string name, string path);

	private enum Column {
		NAME, PATH
	}

	private bool location_entry_valid = false;

	[GtkChild]
	private Gtk.Entry location_entry;
	[GtkChild]
	private Gtk.ListStore location_store;
	[GtkChild]
	private Gtk.TreeView location_tree;
	[GtkChild]
	private Gtk.Button connect_button;
	[GtkChild]
	private Gtk.Expander expander;

	public ServerBrowserDialog(bool may_launch)
	{
		Object(use_header_bar: 1);
		expander.visible = may_launch;
	}

	private void emit_remote_selected(Gtk.TreeIter iter)
	{
		unowned string name, connection_path;
		location_store.get(iter,
		                   Column.NAME, out name,
		                   Column.PATH, out connection_path);

		remote_selected(name, connection_path);

		response(Gtk.ResponseType.OK);
		destroy();
	}

	[GtkCallback]
	private void on_location_row_activated(Gtk.TreeView view, Gtk.TreePath path, Gtk.TreeViewColumn colunm)
	{
		Gtk.TreeIter iter;
		location_store.get_iter(out iter, path);
		emit_remote_selected(iter);
	}

	[GtkCallback]
	private void on_location_entry_activated(Gtk.Entry entry)
	{
		if (location_entry_valid) {
			remote_selected(location_entry.text, location_entry.text);
			response(Gtk.ResponseType.OK);
			destroy();
		}
	}

	[GtkCallback]
	private void on_location_row_selected(Gtk.TreeSelection selection)
	{
		if (selection.count_selected_rows() > 0) {
			connect_button.sensitive = true;
			location_entry.text = "";
		} else {
			connect_button.sensitive = false;
		}
	}

	[GtkCallback]
	private void on_location_entry_changed(Gtk.Editable entry)
	{
		if (location_entry.text.length > 0) {
			location_tree.get_selection().unselect_all();
			connect_button.sensitive = false;
			check_location.begin(location_entry.text, (obj, res) => {
				var success = check_location.end(res);
				location_entry_valid = success;
				connect_button.sensitive = success;
			});
		}
	}

	[GtkCallback]
	private void on_connect_clicked()
	{
		if (location_entry.text.length > 0) {
			on_location_entry_activated(location_entry);
		} else {
			Gtk.TreeIter iter;
			location_tree.get_selection().get_selected(null, out iter);
			emit_remote_selected(iter);
		}
	}

	[GtkCallback]
	private void on_cancel_clicked()
	{
		response(Gtk.ResponseType.CANCEL);
		destroy();
	}

	[GtkCallback]
	private void on_launch_clicked()
	{
		launch();
	}

	public void add_service(string name, string path)
	{
		Gtk.TreeIter iter;
		location_store.append(out iter);
		location_store.set(iter, Column.NAME, name, Column.PATH, path);
	}

	public void remove_service(string name, string path)
	{
		Gtk.TreeIter iter;

		if (!location_store.get_iter_first(out iter))
			return;

		do {
			unowned string entry_name, entry_path;
			location_store.get(iter, Column.NAME, out entry_name, Column.PATH, out entry_path);
			if (path == entry_path) {
				location_store.remove(iter);
				break;
			}
		} while (location_store.iter_next(ref iter));
	}

	/* Happily attempt to interpret what Layer-8 dropped on us, aka Death-to-Layer-8 */
	private async bool check_location(owned string path)
	{
		if (path.length == 0 || path[-1] == ':')
			return false;

		if (path.has_prefix("unix://"))
			path = path[7:path.length];

		if (path[0] == '/' && path.length > 1) {
			var success = yield ServerProber.check_version(new GLib.UnixSocketAddress(path));
			if (success) {
				if (!location_entry.text.has_prefix("unix://"))
					location_entry.text = "unix://" + location_entry.text;
				location_entry.set_position(location_entry.text.length);
				return true;
			}
		}

		if (path.has_prefix("tcp://"))
			path = path[6:path.length];

		uint16 port = Xmms.DEFAULT_TCP_PORT;

		var index = path.last_index_of_char(':');
		if (index > 0) {
			/* Check for incomplete IPv6 address */
			if (path[0] == '[' && path[index - 1] != ']')
				return false;

			var result = long.parse(path[index + 1:path.length]);
			if (result <= 0)
				return false;
			port = (uint16) result;

			path = path[0:index];
		}

		/* Rip out the brackets if path is an IPv6 address with port definition */
		if (path[0] == '[' && path[path.length - 1] == ']')
			path = path[1:path.length - 1];

		if (path[0].isdigit()) {
			GLib.InetAddress address = new GLib.InetAddress.from_string(path);
			if (address == null)
				return false;

			var success = yield ServerProber.check_version(new GLib.InetSocketAddress(address, port));
			if (success) {
				if (!location_entry.text.has_prefix("tcp://"))
					location_entry.text = "tcp://" + location_entry.text;
				if (address.family == GLib.SocketFamily.IPV4)
					location_entry.text = location_entry.text.replace("[", "").replace("]", "");
				location_entry.set_position(location_entry.text.length);
				return true;
			}
		}

		/* Alright.. maybe a domain then... */
		var resolver = GLib.Resolver.get_default();

		try {
			var addresses = yield resolver.lookup_by_name_async(path, null);
			foreach (var address in addresses) {
				var success = yield ServerProber.check_version(new GLib.InetSocketAddress(address, port));
				if (success) {
					if (!location_entry.text.has_prefix("tcp://"))
						location_entry.text = "tcp://" + location_entry.text;
					location_entry.text = location_entry.text.replace("[", "").replace("]", "");
					location_entry.set_position(location_entry.text.length);
					return true;
				}
			}
		}
		catch (GLib.Error e) {
			return false;
		}

		return false;
	}
}
