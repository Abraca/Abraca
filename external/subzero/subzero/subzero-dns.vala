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

internal class SubZero.DNS {
	private const int MAX_NAME_LENGTH = 255;
	private const int MAX_LABEL_LENGTH = 63;


	public enum Flags
	{
		Query               =  0 <<  0,
		Response            =  1 << 15,
		Opcode              = 15 << 11,
		Authorative         =  1 << 10,
		Truncated           =  1 <<  9,
		RecursionDesired    =  1 <<  8,
		RecursionAvailable  =  1 <<  7,
		Z                   =  1 <<  6,
		AnswerAuthenticated =  1 <<  5,
		NonAuthenticated    =  1 <<  4,
		ReplyCode           = 15 <<  0;

		public bool matches(uint16 value) {
			return (((uint16) this) & value) > 0;
		}
	}

	public enum RecordType
	{
		A    = 0x01,
		PTR  = 0x0c,
		TXT  = 0x10,
		AAAA = 0x1c,
		SRV  = 0x21,
		NSEC = 0x2f,
	}

	public static uint8[] generate_ptr_query(string[] services)
		throws GLib.IOError
	{
		var memory = new GLib.MemoryOutputStream(null, GLib.realloc, GLib.free);
		var stream = new GLib.DataOutputStream(memory);

		/* Transaction ID */
		stream.put_uint16(0x0000);
		stream.put_uint16(Flags.Query);

		/* Questions */
		stream.put_uint16((uint8) services.length);
		/* Answer RRs */
		stream.put_uint16(0x0000);
		/* Authorative RRs */
		stream.put_uint16(0x0000);
		/* Additional RRs */
		stream.put_uint16(0x0000);

		foreach (var service in services) {
			foreach (var part in service.split(".")) {
				stream.put_byte((uint8) part.length);
				stream.put_string(part);
			}

			stream.put_byte(0x0);
			stream.put_uint16(RecordType.PTR);
			stream.put_uint16(0x0001);
		}

		unowned uint8[] data = memory.get_data();
		return data[0:memory.data_size];
	}


	private static string parse_record_name(GLib.DataInputStream stream)
		throws GLib.Error
	{
		uint8 buffer[256]; // MAX_NAME_LENGTH
		uint8 pos = 0;

		parse_record_name_recurse(stream, buffer, ref pos);

		return (string) buffer;
	}

	private static void parse_record_name_recurse(GLib.DataInputStream stream, uint8[] name, ref uint8 pos)
		throws GLib.Error
	{
		while (true) {
			var len = stream.read_byte();
			if (len == 0)
				break;

			/* If first two bits sets, remaining part of the name
			 * can be found at the offset found in 14 bits.
			 */
			if ((len & 0xc0) != 0) {
				var seek_pos = (uint16)((len & ~0xc0) << 8 | stream.read_byte());
				var restore_pos = stream.tell();
				stream.seek(seek_pos, GLib.SeekType.SET);
				parse_record_name_recurse(stream, name, ref pos);
				stream.seek(restore_pos, GLib.SeekType.SET);
				/* A jump is always the tail */
				break;
			}

			if (len > MAX_LABEL_LENGTH)
				break;

			if ((pos + len + 1) >= name.length)
				break;

			if (pos > 0)
				name[pos++] = '.';

			stream.read(name[pos:pos + len]);
			pos += len;
		}
	}

	private static GLib.InetAddress parse_inet_address(GLib.DataInputStream stream, uint16 len)
		throws GLib.IOError
		requires(len == 4 || len == 16)
	{
		uint8 buffer[16];
		stream.read(buffer[0:len]);
		return new GLib.InetAddress.from_bytes(buffer[0:len], (len == 4) ? GLib.SocketFamily.IPV4 : GLib.SocketFamily.IPV6);
	}

	private static void parse_record(GLib.DataInputStream stream, uint16 count, DNSRecordVisitor visitor)
		throws GLib.Error
	{
		for (var i = 0; i < count; i++) {
			var name = parse_record_name(stream);
			var type = stream.read_uint16();
			var cls = stream.read_uint16();
			var ttl = stream.read_uint32();
			var data_len = stream.read_uint16();

			switch (type) {
			case RecordType.PTR:
				var ptr_name = parse_record_name(stream);
				visitor.pointer_record(name, cls, ttl, ptr_name);
				break;
			case RecordType.TXT:
				var data = new uint8[data_len];
				stream.read_byte();
				stream.read(data[0:data.length - 1]);
				visitor.text_record(name, cls, ttl, (string) data);
				break;
			case RecordType.SRV:
				stream.read_uint16(); // priority
				stream.read_uint16(); // weight
				var port = stream.read_uint16();
				var service_name = parse_record_name(stream);
				visitor.service_record(name, cls, ttl, service_name, port);
				break;
			case RecordType.A:
				var addr = parse_inet_address(stream, data_len);
				visitor.address_record(name, cls, ttl, addr);
				break;
			case RecordType.AAAA:
				var addr = parse_inet_address(stream, data_len);
				visitor.address_record(name, cls, ttl, addr);
				break;
			case RecordType.NSEC:
				parse_record_name(stream); // next domain thing
				for (var j = stream.read_byte(); j > 0; j--)
					stream.read_byte();
				break;
			default:
				GLib.warning("Unknown type: %04x", type);
				break;
			}
		}
	}

	public static void parse(GLib.DataInputStream stream, DNSRecordVisitor visitor)
		throws GLib.Error
	{
		stream.read_uint16(); /* transaction_id */

		var flags = stream.read_uint16();
		if (Flags.Response.matches(flags)) {
			GLib.debug("Got Response");
		} else {
			GLib.debug("Got Query");
			return;
		}

		var questions = stream.read_uint16();
		var answer_rrs = stream.read_uint16();
		var authority_rrs = stream.read_uint16();
		var additional_rrs = stream.read_uint16();

		GLib.debug(@"questions: $questions, answer_rrs: $answer_rrs, authority_rrs: $authority_rrs, additional_rrs: $additional_rrs");

		if (questions > 0) {
			GLib.debug("Parsing questions:");
			parse_record(stream, questions, visitor);
		}

		if (answer_rrs > 0) {
			GLib.debug("Parsing answers rrs:");
			parse_record(stream, answer_rrs, visitor);
		}

		if (authority_rrs > 0) {
			GLib.debug("Parsing authority rrs:");
			parse_record(stream, authority_rrs, visitor);
		}

		if (additional_rrs > 0) {
			GLib.debug("Parsing additional rrs:");
			parse_record(stream, additional_rrs, visitor);
		}
	}
}
