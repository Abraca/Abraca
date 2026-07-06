/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2014 Abraca Team
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

/*
 * GTK4 drag-and-drop. Unlike the GTK3 GtkTargetEntry/GtkSelectionData world,
 * all of Abraca's drags are in-process, so we carry the live Xmms values inside
 * small GObject wrappers and hand them to Gdk.ContentProvider.for_value(). The
 * matching Gtk.DropTarget is configured for these GTypes and receives the very
 * same objects back. External URI drops arrive as a Gdk.FileList / string.
 */

namespace Abraca {
	/** A set of playlist positions being reordered within the playlist. */
	public class PlaylistEntriesTransfer : GLib.Object {
		/* Xmms.Value list of int positions. */
		public Xmms.Value positions { get; construct; }

		public PlaylistEntriesTransfer (Xmms.Value positions)
		{
			Object (positions: positions);
		}
	}

	/** A collection (idlist or reference) being dragged. */
	public class CollectionTransfer : GLib.Object {
		public Xmms.Collection collection { get; construct; }

		public CollectionTransfer (Xmms.Collection collection)
		{
			Object (collection: collection);
		}
	}

	namespace DragDropUtil {
		public static Gdk.ContentProvider content_for_playlist_entries (Xmms.Value positions)
		{
			var payload = new PlaylistEntriesTransfer (positions);
			var value = GLib.Value (typeof (PlaylistEntriesTransfer));
			value.set_object (payload);
			return new Gdk.ContentProvider.for_value (value);
		}

		public static Gdk.ContentProvider content_for_collection (Xmms.Collection collection)
		{
			var payload = new CollectionTransfer (collection);
			var value = GLib.Value (typeof (CollectionTransfer));
			value.set_object (payload);
			return new Gdk.ContentProvider.for_value (value);
		}
	}
}
