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

public static void main (string[] args)
{
	var ml = new GLib.MainLoop();

	var sc = new SubZero.Browser();
	sc.services = { "_xmms2._tcp.local" };

	sc.service_added.connect((service, hostname, port) => {
		GLib.print(@"$service added $hostname:$port\n");
	});

	sc.service_removed.connect((service, hostname, port) => {
		GLib.print(@"$service removed $hostname:$port\n");
	});

	sc.start();
	ml.run();
	sc.stop();
}
