/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2013 Abraca Team
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

public class Abraca.ServerProber
{
	private const ssize_t HEADER_SIZE = 4 + 4 + 4 + 4;
	private const string CLIENT_NAME= "abraca-version-check";
	private const int COOKIE = 0xCACA;

	private const int TIMEOUT = 5;

	private static async bool send_main_cmd_hello (GLib.DataOutputStream stream)
		throws GLib.Error
	{
		unowned uchar[] data;

		stream.put_int32(Xmms.IpcObject.MAIN);
		stream.put_int32(Xmms.IpcMainCommand.HELLO);
		stream.put_int32(COOKIE);

		var value = new Xmms.Value.from_list();
		value.list_append_int(Xmms.IPC_PROTOCOL_VERSION);
		value.list_append_string(CLIENT_NAME);

		var bb = value.serialize();
		bb.get_bin(out data);

		stream.put_int32(data.length);

		for (int i = 0; i < data.length; i++)
			stream.put_byte(data[i]);

		return true;
	}

	private static async bool recv_cmd_reply (GLib.DataInputStream stream)
		throws GLib.Error
	{
		unowned string msg;
		bool success = false;

		yield stream.fill_async(HEADER_SIZE);

		var object = stream.read_int32();
		if (object != Xmms.IpcObject.MAIN)
			return false;

		var reply = stream.read_int32();
		if (reply == Xmms.IpcReply.OK)
			success = true;

		var reply_cookie = stream.read_int32();
		if (reply_cookie != COOKIE)
			return false;

		var payload_length = stream.read_int32();
		if (payload_length > 1024) /* Arbitrary, but unplausible limit */
			return false;

		yield stream.fill_async(payload_length);

		var data = new uchar[payload_length];
		stream.read(data);

		var payload = new Xmms.Value.from_bin(data).deserialize();
		if (success) {
			/* Before Service Clients, no response */
			if (payload.is_type(Xmms.ValueType.NONE))
				return true;

			/* After Service Clients, client id */
			if (payload.is_type(Xmms.ValueType.INT32))
				return true;
		}

		if (payload.get_error(out msg))
			GLib.warning("Could not connect: %s", msg);

		return false;
	}

	public static async bool check_version (GLib.SocketConnectable address)
	{
		GLib.SocketConnection conn = null;

		try {
			var client = new GLib.SocketClient ();
			client.timeout = TIMEOUT;

			conn = yield client.connect_async (address);

			var dis = new GLib.DataInputStream(conn.input_stream);
			var dos = new GLib.DataOutputStream(conn.output_stream);

			yield send_main_cmd_hello (dos);

			var result = yield recv_cmd_reply (dis);

			yield conn.close_async();

			return result;
		} catch (GLib.Error e) {
			if (conn != null) {
				try {
					yield conn.close_async();
				} catch (GLib.IOError ioe) {
					GLib.warning(ioe.message);
				}
			}
			return false;
		}
	}
}
