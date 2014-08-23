#!/usr/bin/gjs
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

const GLib = imports.gi.GLib
const SubZero = imports.gi.SubZero

var sz = new SubZero.Browser();
sz.services = ['_xmms2._tcp.local'];
sz.connect('service-added', function(obj, service, hostname, port) {
	print(service + " added " + hostname + ":" + port);
});
sz.connect('service-removed', function(obj, service, hostname, port) {
	print(service + " removed " + hostname + ":" + port);
});

sz.start();

var ml = GLib.MainLoop.new(null, true);
ml.run();

sz.stop();
