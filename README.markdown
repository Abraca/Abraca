Abraca
------
A GTK-based client for the XMMS2 music player which makes managing
your music a breeze.

Goals
-----
* Fast interaction with very large media libraries.
* Reward metadata addicts.
* Experiment with latest GTK technologies.
* Provide deep context around currently playing media.
* Fast and easy to switch between which XMMS2 to control.
* Full Linux, BSD and Mac OS X support, and possibly also Windows.

Build Status
------------
* Ubuntu 12.10
    * [![Build Status](https://travis-ci.org/Abraca/Abraca.png)](https://travis-ci.org/Abraca/Abraca)

Download
--------
Release tarballs can be downloaded at [GitHub](https://github.com/Abraca/Abraca/tags).

For the more adventurous, snapshots can be checked out via Git:

    git clone --recursive git://github.com/Abraca/Abraca.git
    
The `--recursive` flag is needed to configure the submodule(s).

Future updates of the source code can be fetched via:

    git pull --rebase
    git submodule update

Install
-------
    ./waf configure --prefix=/usr
    ./waf build
    sudo ./waf install

License
-------
[GNU General Public License, version 2.0](https://www.gnu.org/licenses/gpl-2.0.html), more details in COPYING.
