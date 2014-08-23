SubZero
=======

A minimalistic cross-platform GObject based zeroconf library.

Motivation
----------
I used to use the zeroconf-parts from libdmapsharing, but it turned out they were
racy on Mac OS X due to how the DNS-SD APIs were used / worked. Another downside
was having the same wrapper implementation duplicated for DNS-SD and Avahi which
could require duplicate work when fixing bugs or adding features.

So started to toy with the idea of writing a browsing implementation, instead of a
wrapper, in a lot less lines of code, with a simple API and so SubZero was born.

The name SubZero is to denote that it's a subpar zeroconf implementation, good enough to
discover the services I need on the network and possibly others.

Goals
-----
Stability, readability, and never ever support for registering services or taking the role as a proxy.

Supported Platforms
-------------------
The library and the examples have been tested on both Debian GNU/Linux and Mac OS X 10.8.

Install
-------

    ./waf configure --prefix=/usr
    ./waf build
    sudo ./waf install
    sudo ldconfig
    
License
-------
[GNU Lesser General Public License, version 2.1](https://www.gnu.org/licenses/lgpl-2.1.html), more details in COPYING.