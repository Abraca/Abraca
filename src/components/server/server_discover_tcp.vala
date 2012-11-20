/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2012 Abraca Team
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

public class Abraca.ServerDiscoverTcp : ServerDiscover
{
	private SubZero.Browser browser = new SubZero.Browser();
	private GLib.Resolver resolver = GLib.Resolver.get_default();

	private delegate void ApplyInetAddressFunc(string name, GLib.InetAddress address, uint16 port);

	public ServerDiscoverTcp()
	{
		browser.services = { "_xmms2._tcp.local" };
		browser.service_added.connect(on_service_added);
		browser.service_removed.connect(on_service_removed);
	}

	private static string path_from_address(GLib.InetAddress address, uint port)
	{
		if (address.family == GLib.SocketFamily.IPV6)
			return "tcp://[%s]:%u".printf(address.to_string(), port);
		return "tcp://%s:%u".printf(address.to_string(), port);
	}

	private void apply_host(string hostname, uint port, ApplyInetAddressFunc func)
	{
		resolver.lookup_by_name_async.begin(hostname, null, (obj, res) => {
			try {
				var addresses = resolver.lookup_by_name_async.end(res);
				foreach (var address in addresses) {
					func(hostname, address, port == 0 ? Xmms.DEFAULT_TCP_PORT : (uint16) port);
				}
			} catch (GLib.Error e) {
				GLib.debug("Could not resolve host: %s", hostname);
			}
		});
	}

	private void on_service_added(string service, string hostname, int port)
	{
		apply_host(hostname, port, (hostname, address, port) => {
			var path = path_from_address(address, port);
			add_service.begin(hostname, path, new GLib.InetSocketAddress(address, port));
		});
	}

	private void on_service_removed(string service, string hostname, int port)
	{
		apply_host(hostname, port, (hostname, address, port) => {
			var path = path_from_address(address, port);
			remove_service(hostname, path);
		});
	}

	protected override void do_start()
	{
		browser.start();
	}

	protected override void do_stop()
	{
		browser.stop();
	}
}
