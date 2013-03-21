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

public abstract class Abraca.TargetEntry {
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

public abstract class Abraca.DragDropUtil {
	private static unowned uchar[] get_selection_data(Gtk.SelectionData selection_data)
	{
		unowned uchar[] data = selection_data.get_data();
		data.length = selection_data.get_length();
		return data;
	}

	public static Xmms.Value receive_playlist_entries(Gtk.SelectionData selection_data)
	{
		unowned uchar[] data = get_selection_data(selection_data);
		return new Xmms.Value.from_bin(data).deserialize();
	}

	public static Xmms.Collection receive_collection(Gtk.SelectionData selection_data)
	{
		Xmms.Collection collection;

		unowned uchar[] data = get_selection_data(selection_data);
		var value = new Xmms.Value.from_bin(data).deserialize();

		value.get_coll(out collection);

		return collection;
	}

	public static void send_playlist_entries(Gtk.SelectionData selection_data, Xmms.Value value)
	{
		unowned uchar[] data;

		var bin = value.serialize();
		bin.get_bin(out data);

		var atom = Gdk.Atom.intern_static_string(Abraca.TargetEntry.PlaylistEntries.target);
		selection_data.set(atom, 8, data);
	}

	public static void send_collection(Gtk.SelectionData selection_data, Xmms.Collection collection)
	{
		unowned uchar[] data;

#if XMMS_API_COLLECTIONS_TWO_DOT_ZERO
		var bin = collection.serialize();
#else
		var bin = new Xmms.Value.from_coll(collection).serialize();
#endif
		bin.get_bin(out data);

		var atom = Gdk.Atom.intern_static_string(Abraca.TargetEntry.Collection.target);
		selection_data.set(atom, 8, data);
	}
}
