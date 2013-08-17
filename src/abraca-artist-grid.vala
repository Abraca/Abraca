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


/*
  var order = new Xmms.Value.from_list ();
  order.list_append (new Xmms.Value.from_string ("tracknr"));

  var fetch = new Xmms.Value.from_list ();
  fetch.list_append (new Xmms.Value.from_string ("id"));
  fetch.list_append (new Xmms.Value.from_string ("album"));
  fetch.list_append (new Xmms.Value.from_string ("album_id"));
  fetch.list_append (new Xmms.Value.from_string ("album_artist"));
  fetch.list_append (new Xmms.Value.from_string ("artist"));
  fetch.list_append (new Xmms.Value.from_string ("duration"));
  fetch.list_append (new Xmms.Value.from_string ("picture_front"));
  fetch.list_append (new Xmms.Value.from_string ("title"));
  fetch.list_append (new Xmms.Value.from_string ("tracknr"));
*/

public class Abraca.ArtistGrid : Gtk.Grid {
	private Client client;

	public enum ArtistReferenceType
	{
		ARTIST_NAME,
		ALBUM_ARTIST_NAME,
		ARTIST_MBID;


		public string to_string() {
			switch (this) {
			case ARTIST_NAME:
				return "artist";
			case ALBUM_ARTIST_NAME:
				return "album_artist";
			case ARTIST_MBID:
				return "artist_id";
			default:
				GLib.assert_not_reached();
			}
		}
	}

	private static Xmms.Collection universe()
	{
#if XMMS_API_COLLECTIONS_TWO_DOT_ZERO
		var universe = new Xmms.Collection (Xmms.CollectionType.UNIVERSE);
#else
		var universe = new Xmms.Collection (Xmms.CollectionType.REFERENCE);
		universe.attribute_set ("namespace", "Collections");
		universe.attribute_set ("reference", "All Media");
#endif
		return universe;
	}


	public ArtistGrid(Client client)
	{
		Object();
		this.client = client;
	}

	public void show_artist(string name, ArtistReferenceType typ = ArtistReferenceType.ARTIST_NAME)
	{
		var coll = new Xmms.Collection(Xmms.CollectionType.INTERSECTION);
		{
			var match = new Xmms.Collection(Xmms.CollectionType.MATCH);
			match.add_operand(universe());
			match.attribute_set("field", typ.to_string());
			match.attribute_set("value", name);
			coll.add_operand(match);
		}
		{
			var has = new Xmms.Collection(Xmms.CollectionType.HAS);
			has.add_operand(universe());
			has.attribute_set("field", "album");
			coll.add_operand(has);
		}

		var order = new Xmms.Value.from_list();

		var groupby = new Xmms.Value.from_list();
		groupby.list_append(new Xmms.Value.from_string("album"));

		var fetch = new Xmms.Value.from_list();
		fetch.list_append(new Xmms.Value.from_string("artist"));
		fetch.list_append(new Xmms.Value.from_string("album_artist"));
		fetch.list_append(new Xmms.Value.from_string("artist_id"));
		fetch.list_append(new Xmms.Value.from_string("album"));
		fetch.list_append(new Xmms.Value.from_string("catalognumber"));
		fetch.list_append(new Xmms.Value.from_string("date"));
		fetch.list_append(new Xmms.Value.from_string("originaldate"));
		fetch.list_append(new Xmms.Value.from_string("picture_front"));
		fetch.list_append(new Xmms.Value.from_string("publisher"));
		fetch.list_append(new Xmms.Value.from_string("compilation"));

		client.xmms.coll_query_infos(coll, order, 0, 0, fetch, groupby).notifier_set/*_full*/((value) => {
			album_done(value/*, typ*/);
			return true;
		});
	}

	private bool album_done(Xmms.Value value /*, ArtistReferenceType typ*/ )
	{
		unowned Xmms.Value album;
		unowned Xmms.ListIter iter;

		var albums = new Gee.ArrayList<AlbumView>();

		value.get_list_iter(out iter);
		while (iter.entry(out album)) {
			albums.add(add_album(album /*, typ */));
			iter.next();
		}

		albums.sort((v1,v2) => {
			var a = v1 as AlbumView;
			var b = v2 as AlbumView;
			var a_date = (a.original_date != null) ? a.original_date : a.release_date;
			var b_date = (b.original_date != null) ? b.original_date : b.release_date;
			return GLib.strcmp(b_date, a_date);
		});

		foreach (var child in albums)
			attach_next_to(child, null, Gtk.PositionType.BOTTOM, 1, 1);

		return true;
	}

	private AlbumView add_album(Xmms.Value entry /*, ArtistReferenceType typ*/)
	{
		unowned string value;
		int number;

		var view = AlbumView.create();
		if (entry.dict_entry_get_string("date", out value))
			view.release_date = value;
		if (entry.dict_entry_get_string("originaldate", out value))
			view.original_date = value;
		if (entry.dict_entry_get_string("album", out value))
			view.album = value;
		if (entry.dict_entry_get_string("artist", out value))
			view.artist = value;
		if (entry.dict_entry_get_string("album_artist", out value))
			view.album_artist = value;
		if (entry.dict_entry_get_string("catalognumber", out value))
			view.catalognumber = value;
		if (entry.dict_entry_get_string("publisher", out value))
			view.publisher = value;

		view.set_cover_art(client.default_coverart);

		/* With strict mode we could simply rely on musicbrainz tags */

		var order = new Xmms.Value.from_list();
		order.list_append(new Xmms.Value.from_string("partofset"));
		order.list_append(new Xmms.Value.from_string("tracknr"));

		var fetch = new Xmms.Value.from_list();
		fetch.list_append(new Xmms.Value.from_string("title"));
		fetch.list_append(new Xmms.Value.from_string("partofset"));
		fetch.list_append(new Xmms.Value.from_string("tracknr"));
		fetch.list_append(new Xmms.Value.from_string("artist")); /* may not be same as album_artist */
		fetch.list_append(new Xmms.Value.from_string("duration"));

		/* should cancel out duplicate albums */
		var groupby = new Xmms.Value.from_list();
		groupby.list_append(new Xmms.Value.from_string("partofset"));
		groupby.list_append(new Xmms.Value.from_string("tracknr"));
		groupby.list_append(new Xmms.Value.from_string("title"));

		var album_match = new Xmms.Collection(Xmms.CollectionType.MATCH);
		album_match.add_operand(universe());
		album_match.attribute_set("field", "album");
		album_match.attribute_set("value", view.album);

		var artist_match = new Xmms.Collection(Xmms.CollectionType.UNION);
		{
			var coll = new Xmms.Collection(Xmms.CollectionType.MATCH);
			coll.add_operand(universe());
			coll.attribute_set("field", "album_artist");
			coll.attribute_set("value", view.album_artist);
			artist_match.add_operand(coll);
		}
		{
			var coll = new Xmms.Collection(Xmms.CollectionType.MATCH);
			coll.add_operand(universe());
			coll.attribute_set("field", "artist");
			coll.attribute_set("value", view.artist);
			artist_match.add_operand(coll);
		}

		if (entry.dict_entry_get_int("compilation", out number) && number == 1) {
			groupby.list_append(new Xmms.Value.from_string(view.album));
			client.xmms.coll_query_infos(album_match, order, 0, 0, fetch, groupby);
		} else {
			var intersection = new Xmms.Collection(Xmms.CollectionType.INTERSECTION);
			intersection.add_operand(artist_match);
			intersection.add_operand(album_match);

			client.xmms.coll_query_infos(intersection, order, 0, 0, fetch, groupby).notifier_set_full((val) => {
					GLib.print("got searching album\n");

				unowned Xmms.ListIter iter;
				unowned Xmms.Value song;

					GLib.print("size: %d\n", val.list_get_size());


				view.begin_songs();

				val.get_list_iter(out iter);
				while (iter.entry(out song)) {
					string title;
					int tracknr, duration;
					song.dict_entry_get_int("tracknr", out tracknr);
					song.dict_entry_get_string("title", out title);
					song.dict_entry_get_int("duration", out duration);
					view.add_song(tracknr, title, duration);
					iter.next();
				}
				view.commit_songs();


					if (entry.dict_entry_get_string("picture_front", out value)) {
						client.xmms.bindata_retrieve(value).notifier_set_full((data) => {
								add_cover_art(data, view);
								return true;
							});
					}
				return true;
			});
		}

		return view;
	}

	private void add_cover_art(Xmms.Value value, AlbumView view)
	{
		unowned uchar[] data;
		if (value.get_bin(out data)) {
			var loader = new Gdk.PixbufLoader();
			try {
				loader.write(data);
				loader.close();
				view.set_cover_art(loader.get_pixbuf());
			} catch (GLib.Error e) {
				// TODO: ...
			}
		}
	}
}
