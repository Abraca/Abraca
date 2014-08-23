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

public interface SubZero.DNSRecordVisitor : GLib.Object
{
	public abstract void pointer_record(string name, uint16 cls, uint32 ttl, string domain);
	public abstract void text_record(string name, uint16 cls, uint32 ttl, string text);
	public abstract void service_record(string name, uint16 cls, uint32 ttl, string domain, uint16 port);
	public abstract void address_record(string name, uint16 cls, uint32 ttl, GLib.InetAddress address);
}

public class SubZero.BaseDNSRecordVisitor : GLib.Object
{
	public void pointer_record(string name, uint16 cls, uint32 ttl, string domain)
	{
	}

	public void text_record(string name, uint16 cls, uint32 ttl, string text)
	{
	}

	public void service_record(string name, uint16 cls, uint32 ttl, string domain, uint16 port)
	{
	}

	public void address_record(string name, uint16 cls, uint32 ttl, GLib.InetAddress address)
	{
	}
}

internal class SubZero.DebugDNSRecordVisitor : GLib.Object, SubZero.DNSRecordVisitor
{
	private SubZero.DNSRecordVisitor? visitor;

	public DebugDNSRecordVisitor(SubZero.DNSRecordVisitor? visitor = null)
	{
		this.visitor = visitor;
	}

	public void pointer_record(string name, uint16 cls, uint32 ttl, string domain)
	{
		GLib.debug(@"Name: $name, Class: $cls, TTL: $ttl, PTR: $domain");
		if (visitor != null)
			visitor.pointer_record(name, cls, ttl, domain);
	}

	public new void text_record(string name, uint16 cls, uint32 ttl, string text)
	{
		GLib.debug(@"Name: $name, Class: $cls, TTL: $ttl, TXT: $text");
		if (visitor != null)
			visitor.pointer_record(name, cls, ttl, text);
	}

	public new void service_record(string name, uint16 cls, uint32 ttl, string domain, uint16 port)
	{
		GLib.debug(@"Name: $name, Class: $cls, TTL: $ttl, SRV: $domain:$port");
		if (visitor != null)
			visitor.service_record(name, cls, ttl, domain, port);
	}

	public new void address_record(string name, uint16 cls, uint32 ttl, GLib.InetAddress address)
	{
		GLib.debug(@"Name: $name, Class: $cls, TTL: $ttl, A/AAAA: $address");
		if (visitor != null)
			visitor.address_record(name, cls, ttl, address);
	}
}
