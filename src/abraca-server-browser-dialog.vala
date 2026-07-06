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
public class Abraca.ServerBrowserDialog : Gtk.Window
{
	public signal void launch ();
	public signal void remote_selected (string name, string path);

	/* Emitted when the dialog is done (selection made or cancelled) so the
	 * ServerBrowser can stop discovery; replaces the deprecated Gtk.Dialog
	 * response signal. */
	public signal void response (int id);

	private class ServerItem : GLib.Object {
		public string name { get; construct; }
		public string path { get; construct; }
		public ServerItem (string name, string path) {
			Object (name: name, path: path);
		}
	}

	private bool location_entry_valid = false;

	private GLib.ListStore location_store;
	private Gtk.SingleSelection selection;

	[GtkChild]
	private Gtk.Entry location_entry;
	[GtkChild]
	private Gtk.ColumnView location_view;
	[GtkChild]
	private Gtk.Button connect_button;
	[GtkChild]
	private Gtk.Expander expander;

	public ServerBrowserDialog(bool may_launch)
	{
		expander.visible = may_launch;

		location_store = new GLib.ListStore (typeof (ServerItem));
		selection = new Gtk.SingleSelection (location_store) {
			autoselect = false,
			can_unselect = true
		};
		selection.notify["selected"].connect (on_selection_changed);
		location_view.set_model (selection);

		var factory = new Gtk.SignalListItemFactory ();
		factory.setup.connect (li => {
			((Gtk.ListItem) li).set_child (new Gtk.Label (null) { xalign = 0 });
		});
		factory.bind.connect (li => {
			var item = (ServerItem) ((Gtk.ListItem) li).get_item ();
			var label = (Gtk.Label) ((Gtk.ListItem) li).get_child ();
			label.label = item.name;
			label.tooltip_text = item.path;
		});
		location_view.append_column (new Gtk.ColumnViewColumn (null, factory));

		location_view.activate.connect (on_activate);
	}

	private void on_activate (uint position)
	{
		var item = selection.get_item (position) as ServerItem;
		if (item != null)
			emit_remote_selected (item);
	}

	private void emit_remote_selected (ServerItem item)
	{
		remote_selected (item.name, item.path);
		response (0);
		close ();
	}

	private void on_selection_changed ()
	{
		if (selection.selected != Gtk.INVALID_LIST_POSITION) {
			connect_button.sensitive = true;
			location_entry.text = "";
		} else {
			connect_button.sensitive = false;
		}
	}

	[GtkCallback]
	private void on_location_entry_activated(Gtk.Entry entry)
	{
		if (location_entry_valid) {
			remote_selected(location_entry.text, location_entry.text);
			response(0);
			close();
		}
	}

	[GtkCallback]
	private void on_location_entry_changed(Gtk.Editable entry)
	{
		if (location_entry.text.length > 0) {
			selection.unselect_all();
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
		} else if (selection.selected != Gtk.INVALID_LIST_POSITION) {
			emit_remote_selected((ServerItem) selection.get_item(selection.selected));
		}
	}

	[GtkCallback]
	private void on_cancel_clicked()
	{
		response(1);
		close();
	}

	[GtkCallback]
	private void on_launch_clicked()
	{
		launch();
	}

	public void add_service(string name, string path)
	{
		location_store.append(new ServerItem(name, path));
	}

	public void remove_service(string name, string path)
	{
		for (uint i = 0; i < location_store.get_n_items(); i++) {
			if (((ServerItem) location_store.get_item(i)).path == path) {
				location_store.remove(i);
				break;
			}
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
