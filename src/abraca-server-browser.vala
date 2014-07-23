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

public class Abraca.ServerBrowser : GLib.Object
{
	private static const string EXECUTABLE = "xmms2-launcher";
	private static const string[] ARGS = { EXECUTABLE };

	private const string DEFAULT_UNIX_PATH = "/tmp";

	private enum Column {
		NAME, PATH
	}

	private ServerDiscover discover_network = new ServerDiscoverTcp();
	private ServerDiscover discover_unix = new ServerDiscoverUnix(DEFAULT_UNIX_PATH);

	private Gtk.Dialog dialog;

	private Gtk.Entry location_entry;
	private bool location_entry_valid = false;

	private Gtk.TreeView location_tree;
	private Gtk.ListStore location_store;
	private Gtk.TreeSelection location_selection;

	private Gtk.Action connect_action;

	private Client client;

	private GLib.Subprocess launcher = null;

	private static Gtk.Builder get_builder ()
	{
		var builder = new Gtk.Builder();

		try {
			builder.add_from_resource("/org/xmms2/Abraca/ui/server_browser.xml");
		} catch (GLib.Error e) {
			GLib.error(e.message);
		}

		return builder;
	}

	public ServerBrowser(Gtk.Window parent, Client client)
	{
		var builder = get_builder();

		dialog = builder.get_object("server-browser") as Gtk.Dialog;
		dialog.transient_for = parent;

		location_entry = builder.get_object("location-entry") as Gtk.Entry;

		location_tree = builder.get_object("location-tree") as Gtk.TreeView;
		location_store = builder.get_object("location-store") as Gtk.ListStore;
		location_selection = builder.get_object("location-selection") as Gtk.TreeSelection;

		connect_action = builder.get_object("connect-action") as Gtk.Action;

		builder.connect_signals(this);

		discover_network.service_added.connect(on_service_added);
		discover_network.service_removed.connect(on_service_removed);

		discover_unix.service_added.connect(on_service_added);
		discover_unix.service_removed.connect(on_service_removed);

		this.client = client;

		if (GLib.Environment.find_program_in_path(EXECUTABLE) != null) {
			var launch_action = builder.get_object("launch-action") as Gtk.Action;
			launch_action.sensitive = true;
		}
	}

	public void run ()
	{
		discover_network.start();
		discover_unix.start();
		dialog.run();
		discover_network.stop();
		discover_unix.stop();

		if (launcher != null) {
			launcher.force_exit();
			launcher = null;
		}
	}

	public void on_location_row_activated (Gtk.TreeView view, Gtk.TreePath path, Gtk.TreeViewColumn colunm)
	{
		on_connect_activated();
	}

	public void on_location_entry_activated(Gtk.Entry entry)
	{
		if (location_entry_valid) {
			on_connect_activated();
		}
	}

	public void on_connect_activated ()
	{
		var selection = location_tree.get_selection();

		foreach (var path in selection.get_selected_rows(null)) {
			unowned string connection_path;
			Gtk.TreeIter iter;

			location_store.get_iter(out iter, path);
			location_store.get(iter, Column.PATH, out connection_path);
			client.try_connect(connection_path);
			dialog.response(Gtk.ResponseType.OK);
			dialog.destroy();
			return;
		}

		client.try_connect(location_entry.text);
		dialog.destroy();
	}

	public void on_location_row_selected (Gtk.TreeSelection selection)
	{
		if (selection.count_selected_rows() > 0) {
			connect_action.sensitive = true;
			location_entry.text = "";
		} else {
			connect_action.sensitive = false;
		}
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
				if (!location_entry.text.has_prefix("tcp://")) {
					location_entry.text = "tcp://" + location_entry.text;
				}
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

	public void on_location_entry_changed(Gtk.Entry entry)
	{
		if (location_entry.text.length > 0) {
			location_selection.unselect_all();
			connect_action.sensitive = false;
			check_location.begin(location_entry.text, (obj, res) => {
				var success = check_location.end(res);
				location_entry_valid = success;
				connect_action.sensitive = success;
			});
		}
	}

	public void on_cancel_activated ()
	{
		dialog.response(Gtk.ResponseType.CANCEL);
		dialog.destroy();
	}

	public void on_launch_activated ()
	{
		if (launcher != null)
			return;

		try {
			launcher = new GLib.Subprocess.newv(ARGS,
			                                    GLib.SubprocessFlags.STDOUT_SILENCE |
			                                    GLib.SubprocessFlags.STDERR_SILENCE);
			launcher.wait_async.begin(null, (obj, res) => {
				launcher = null;
			});
		}
		catch (GLib.Error e) {
			launcher = null;
		}
	}

	private void on_service_added(string name, string path)
	{
		Gtk.TreeIter iter;
		location_store.append(out iter);
		location_store.set(iter, Column.NAME, name, Column.PATH, path);
	}

	private void on_service_removed(string name, string path)
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
}
