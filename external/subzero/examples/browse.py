#!/usr/bin/env python
# SubZero, a MDNS browser.
# Copyright (C) 2012 Daniel Svensson
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

from gi.repository import GLib
from gi.repository import SubZero

def on_service_added(obj, service, hostname, port):
	print "%s added %s:%d" % (service, hostname, port)

def on_service_removed(obj, service, hostname, port):
	print "%s removed %s:%d" % (service, hostname, port)

sz = SubZero.Browser()
sz.props.services = ['_xmms2._tcp.local']
sz.connect('service-added', on_service_added)
sz.connect('service-removed', on_service_removed)

sz.start()

ml = GLib.MainLoop()
ml.run()

sz.stop()
