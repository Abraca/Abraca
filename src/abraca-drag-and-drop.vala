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

public enum Abraca.TargetInfo {
	PLAYLIST_ENTRIES,
	COLLECTION,
	URI,
	INTERNET,
}

public class Abraca.TargetEntry {
	public const Gtk.TargetEntry PlaylistEntries = {
		"application/x-xmmsclient-playlist-row", 0, TargetInfo.PLAYLIST_ENTRIES
	};

	public const Gtk.TargetEntry Collection = {
		"application/x-xmmsclient-collection", 0, TargetInfo.COLLECTION
	};

	public const Gtk.TargetEntry UriList = {
		"text/uri-list", 0, TargetInfo.URI
	};

	public const Gtk.TargetEntry Internet = {
		"_NETSCAPE_URL", 0, TargetInfo.INTERNET
	};
}
