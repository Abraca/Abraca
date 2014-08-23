/**
 * SubZero, a MDNS browser.
 * Copyright (C) 2012 Daniel Svensson
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

internal class SubZero.ServiceVisitor : BaseDNSRecordVisitor, DNSRecordVisitor
{
	struct ServiceDescription {
		string hostname;
		uint16 port;
	}

	private GLib.HashTable<string,ServiceDescription?> discovered = new HashTable<string,ServiceDescription?>(str_hash, str_equal);

	private Browser browser;

	public ServiceVisitor(SubZero.Browser browser)
	{
		this.browser = browser;
	}

	public new void pointer_record(string name, uint16 cls, uint32 ttl, string domain)
	{
		if (ttl != 0)
			return;

		foreach (var service in browser.services) {
			if (service != name)
				continue;
			unowned ServiceDescription? description = discovered.lookup(domain);
			if (description != null) {
				browser.service_removed(name, description.hostname, description.port);
				discovered.remove(domain);
				break;
			}
		}
	}

	public new void service_record(string name, uint16 cls, uint32 ttl, string hostname, uint16 port)
	{
		if (ttl == 0)
			return;
		foreach (var service in browser.services) {
			if (!name.has_suffix(service))
			    continue;
			if (!discovered.contains(name)) {
				discovered.insert(name, { hostname, port });
				browser.service_added(service, hostname, port);
				break;
			}
		}
	}
}

public class SubZero.Browser : GLib.Object
{
	private const uint16 MDNS_PORT = 5353;

	private GLib.InetAddress inet_address_any = new GLib.InetAddress.any(GLib.SocketFamily.IPV4);
	// private GLib.InetAddress inet6_address_any = new GLib.InetAddress.any(GLib.SocketFamily.IPV6);

	private GLib.InetAddress inet_address_mdns = new GLib.InetAddress.from_string("224.0.0.251");
	// private GLib.InetAddress inet6_address_mdns = new GLib.InetAddress.from_string("ff02::fb");

	public signal void service_added(string service, string hostname, int port);
	public signal void service_removed(string service, string hostname, int port);

	private GLib.Socket socket;

	private GLib.IOChannel channel;
	private uint server_source = -1;
	private uint client_source = -1;

	private DNSRecordVisitor visitor;
	private uint8[] query;

	public bool is_running { get; private set; default = false; }
	public uint interval { get; set; default = 10; }
	public string[] services { get; set; default = {}; }

	construct
	{
		visitor = new DebugDNSRecordVisitor(new ServiceVisitor(this));

		this.notify["services"].connect((s, p) => {
			try {
				query = DNS.generate_ptr_query(services);
			} catch (GLib.Error e) {
				GLib.warning("Services produced an illegal query, ignoring.");
			}
		});
		this.notify["interval"].connect((s, p) => {
			if (is_running) {
				GLib.Source.remove(client_source);
				client_source = GLib.Timeout.add_seconds(interval, send_query);
			}
		});
	}

	public void start()
	{
		GLib.assert(!is_running);

		try {
			socket = new GLib.Socket(GLib.SocketFamily.IPV4, GLib.SocketType.DATAGRAM, GLib.SocketProtocol.UDP);
			socket.multicast_ttl = 225;
			socket.multicast_loopback = true;
#if HAVE_SO_REUSEPORT
			int32 enable = 1;
			Posix.setsockopt(socket.fd, Platform.Socket.SOL_SOCKET, Platform.Socket.SO_REUSEPORT, &enable, (Posix.socklen_t) sizeof(int));
#endif
			socket.bind(new GLib.InetSocketAddress(inet_address_any, MDNS_PORT), true);
			socket.join_multicast_group(inet_address_mdns, false, "lo");

			channel = new IOChannel.unix_new(socket.fd);
			server_source = channel.add_watch(IOCondition.IN, on_incoming);

			query = DNS.generate_ptr_query(services);
			send_query();

			client_source = GLib.Timeout.add_seconds(interval, send_query);

			is_running = true;
		} catch (GLib.Error e) {
			GLib.warning(@"Could not setup: $(e.message)");
			cleanup();
		}
	}

	public void stop()
	{
		cleanup();
		is_running = false;
	}

	private void cleanup()
	{
		if (client_source != -1)
			GLib.Source.remove(client_source);
		if (server_source != -1)
			GLib.Source.remove(server_source);

		client_source = -1;
		server_source = -1;

		channel = null;

		socket = null;
	}

	private bool send_query()
	{
		try {
			socket.send_to(new GLib.InetSocketAddress(inet_address_mdns, MDNS_PORT), query);
		} catch (GLib.Error e) {
			GLib.warning(@"Could not send query: $(e.message)");
		}
		return true;
	}
	private bool on_incoming()
	{
		uint8 buffer[9000];

		try {
			var bytes_read = socket.receive(buffer);
			GLib.debug(@"received $bytes_read bytes");
			if (bytes_read == 0)
				return true;

			Util.hexdump(buffer[0:bytes_read]);

			DNS.parse(new GLib.DataInputStream(new GLib.MemoryInputStream.from_data (buffer, GLib.free)), visitor);
		} catch (GLib.Error e) {
			GLib.warning(@"Could not parse MDNS packet: $(e.message)");
			try {
				GLib.FileIOStream stream;
				GLib.File.new_tmp("packet-XXXXXX.data", out stream);
				stream.get_output_stream().write(buffer);
				GLib.warning(@"Wrote dns packet in $(GLib.Environment.get_tmp_dir())");
			} catch (GLib.Error e2) {
				GLib.warning(@"Could not write debug file: $(e2.message)");
			}
		}

		return true;
	}
}
