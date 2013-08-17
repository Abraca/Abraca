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

public class Abraca.AlbumView : Gtk.Grid, Gtk.Buildable {

	private enum Column {
		POSITION,
		MID,
		TITLE,
		DURATION
	}

	private Gtk.TreeView album_treeview;
	private Gtk.Label album_label;
	private Gtk.Label date_label;
	private Gtk.Image cover_image;
	private Gtk.ListStore track_store;
	private Gtk.Widget tracks_viewport;

	public string title {
		get {
			return album_label.label;
		}
		set {
			album_label.label = value;
		}
	}

	public string original_date {
		get {
			return date_label.label;
		}
		set {
			if (date_label.label == null || date_label.label.length == 0)
				date_label.label = value;
		}
	}

	public string release_date {
		get {
			return date_label.label;
		}
		set {
			if (date_label.label == null || date_label.label.length == 0)
				date_label.label = value;
		}
	}

	public string publisher {
		get; set;
	}

	public string catalognumber {
		get; set;
	}

	public string artist {
		get; set;
	}

	public string album_artist {
		get; set;
	}

	public string album {
		get {
			return album_label.label;
		}
		set {
			album_label.label = value;
		}
	}

	public void parser_finished (Gtk.Builder builder)
	{
		album_treeview = builder.get_object("album-tracks") as Gtk.TreeView;
		album_label = builder.get_object("album-title") as Gtk.Label;
		date_label = builder.get_object("album-date") as Gtk.Label;
		cover_image = builder.get_object("album-cover") as Gtk.Image;
		track_store = builder.get_object("album-store") as Gtk.ListStore;
		tracks_viewport = builder.get_object("album-tracks") as Gtk.Widget;

		const string renderers[] = { "track-renderer", "title-renderer", "duration-renderer" };
		foreach (var name in renderers) {
			var renderer = builder.get_object(name) as Gtk.CellRendererText;
			renderer.set_fixed_height_from_font(1);
		}

		notify["album"].connect((s,p) => {
			album_label.label = album;
		});
	}

	public static AlbumView create ()
	{
		var builder = new Gtk.Builder ();

		try {
			builder.add_from_resource ("/org/xmms2/Abraca/ui/album-view.xml");
		} catch (GLib.Error e) {
			GLib.error (e.message);
		}

		return builder.get_object ("album-view") as AlbumView;
	}

	public void set_cover_art(Gdk.Pixbuf image)
	{
		cover_image.pixbuf = image.scale_simple (175, 175, Gdk.InterpType.HYPER);
	}

	public void begin_songs()
	{
		album_treeview.model = null;
		track_store.clear();
	}

	public void commit_songs()
	{
		album_treeview.model = track_store;
		queue_draw();
		tracks_viewport.queue_resize();
	}

	public void add_song(int position, string title, int milliseconds)
	{
		Gtk.TreeIter iter;
		string duration;
		int minutes, seconds;

		minutes = milliseconds / 60000;
		seconds = (milliseconds % 60000) / 1000;

		duration = "%d:%02d".printf (minutes, seconds);

		track_store.append(out iter);
		track_store.set(iter, Column.POSITION, position, Column.TITLE, title, Column.DURATION, duration);
	}
}
