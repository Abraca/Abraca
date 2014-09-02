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

public class Abraca.ServerBrowser
{
	private static const string EXECUTABLE = "xmms2-launcher";
	private static const string[] ARGS = { EXECUTABLE };

	private const string DEFAULT_UNIX_PATH = "/tmp";

	private ServerDiscover discover_network = new ServerDiscoverTcp();
	private ServerDiscover discover_unix = new ServerDiscoverUnix(DEFAULT_UNIX_PATH);

	private ServerBrowserDialog dialog;

	private Client client;

	private GLib.Subprocess launcher = null;

	public ServerBrowser(Gtk.Window parent, Client client)
	{
		this.client = client;

		var may_launch = (GLib.Environment.find_program_in_path(EXECUTABLE) != null);

		dialog = new ServerBrowserDialog(may_launch);
		dialog.transient_for = parent;
		dialog.launch.connect(on_launch_activated);
		dialog.remote_selected.connect(on_remote_selected);

		discover_network.service_added.connect(dialog.add_service);
		discover_network.service_removed.connect(dialog.remove_service);

		discover_unix.service_added.connect(dialog.add_service);
		discover_unix.service_removed.connect(dialog.remove_service);
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

	public void on_remote_selected(string name, string path)
	{
		client.try_connect(path);
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
}
