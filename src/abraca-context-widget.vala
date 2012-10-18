public class Abraca.ContextWidget : Gtk.Grid
{
	private delegate void MusicbrainzIdFoundFunc(string entry_id);

	private MusicBrainz.ArtistParser artist_parser = new MusicBrainz.ArtistParser();
	private MusicBrainz.ReleaseParser release_groups_parser = new MusicBrainz.ReleaseParser();
	private LastFM.SimilarArtistsParser similar_artists_parser = new LastFM.SimilarArtistsParser();

	private Gtk.ListStore relation_store;
	private Gtk.ListStore release_store;
	private Gtk.ListStore similar_store;
	private Gtk.ListStore side_project_store;

	private Client client;

	private string artist_id;

	private enum Status
	{
		MISSING = 200,
		AVAILABLE = 600
	}

	private enum RelationColumn {
		TYPE,
		NAME,
		SORT_NAME,
		TOOLTIP,
	}

	private enum ReleaseColumn {
		ID,
		TITLE,
		DATE,
		STATUS,
		TOOLTIP,
		RELEASES
	}

	private enum SimilarColumn {
		ID,
		NAME,
		MATCH_STR,
		MATCH_INT,
		STATUS,
		TOOLTIP
	}

	private enum SideProjectColumn {
		ID,
		NAME,
		SORT_NAME,
		STATUS,
		TOOLTIP
	}

	private static Gtk.TreeViewColumn create_text_column (string name, bool ellipsize, int width, ...)
	{
		var renderer = new Gtk.CellRendererText ();
		renderer.set_fixed_height_from_font (1);
		renderer.max_width_chars = width;

		if (ellipsize) {
			renderer.ellipsize = Pango.EllipsizeMode.END;
			renderer.ellipsize_set = true;
		}

		var column = new Gtk.TreeViewColumn ();
		column.pack_start (renderer, true);
		column.title = name;
		if (ellipsize)
			column.expand = true;

		var list = va_list();
		while (true) {
			string? key = list.arg();
			if (key == null)
				break;
			int value = list.arg();
			column.add_attribute(renderer, key, value);
		}

		return column;
	}

	private static Gtk.Widget create_scroll (Gtk.Widget widget)
	{
		var scrolled_window = new Gtk.ScrolledWindow (null, null);
		scrolled_window.add(widget);
		scrolled_window.shadow_type = Gtk.ShadowType.IN;
		return scrolled_window;
	}

	private static Xmms.Collection filter(Gtk.Widget widget, Gee.List<string> entries, string field)
	{
		var union = new Xmms.Collection(Xmms.CollectionType.UNION);
		foreach (var entry in entries) {
			var match = new Xmms.Collection(Xmms.CollectionType.MATCH);
			match.attribute_set("field", field);
			match.attribute_set("value", entry);
			match.add_operand(Xmms.Collection.universe());
			union.add_operand(match);
		}

		return union;
	}

	public ContextWidget (Client client)
	{
		this.client = client;

		row_spacing = 5;
		column_spacing = 5;

		client.playback_current_id.connect(on_playback_current_id);

		relation_store = new Gtk.ListStore(4, typeof(string), typeof(string), typeof(string), typeof(string));
		release_store = new Gtk.ListStore(6, typeof(string), typeof(string), typeof(string), typeof(int), typeof(string), typeof(string));
		similar_store = new Gtk.ListStore(6, typeof(string), typeof(string), typeof(string), typeof(int), typeof(int), typeof(string));
		side_project_store = new Gtk.ListStore(5, typeof(string), typeof(string), typeof(string), typeof(int), typeof(string));

		var relations_view = new Abraca.TreeView();
		var sorted_relation_store = new Gtk.TreeModelSort.with_model(relation_store);
		sorted_relation_store.set_sort_column_id(RelationColumn.SORT_NAME, Gtk.SortType.ASCENDING);
		relations_view.set_model(sorted_relation_store);
		relations_view.append_column(create_text_column("Relation", false, -1, "text", RelationColumn.TYPE));
		relations_view.append_column(create_text_column("Name", true, -1, "text", RelationColumn.NAME));
		relations_view.tooltip_column = RelationColumn.TOOLTIP;
		relations_view.expand = true;
		relations_view.selection.set_mode(Gtk.SelectionMode.MULTIPLE);

		var releases_view = new Abraca.TreeView();
		var sorted_release_store = new Gtk.TreeModelSort.with_model(release_store);
		sorted_release_store.set_default_sort_func(sort_releases);
		releases_view.set_model(sorted_release_store);
		releases_view.append_column(create_text_column("Releases", true, -1, "text", ReleaseColumn.TITLE, "weight", ReleaseColumn.STATUS));
		releases_view.append_column(create_text_column("Date", false, 14, "text", ReleaseColumn.DATE, "weight", ReleaseColumn.STATUS));
		releases_view.tooltip_column = ReleaseColumn.TOOLTIP;
		releases_view.expand = true;
		releases_view.selection.set_mode(Gtk.SelectionMode.MULTIPLE);
		releases_view.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, { Abraca.TargetEntry.Collection }, Gdk.DragAction.MOVE);
		releases_view.drag_data_get.connect((self, ctx, selection_data, info, time) => {
			var entries = new Gee.ArrayList<string>();
			foreach (var releases in releases_view.get_selected_rows<string>(ReleaseColumn.RELEASES))
				foreach (var release in releases.split(":"))
					entries.add(release);
			DragDropUtil.send_collection(selection_data, filter(self, entries, "album_id"));
		});

		var similar_view = new Abraca.TreeView();
		var sorted_similar_store = new Gtk.TreeModelSort.with_model(similar_store);
		sorted_similar_store.set_sort_column_id(SimilarColumn.MATCH_INT, Gtk.SortType.DESCENDING);
		similar_view.set_model(sorted_similar_store);
		similar_view.append_column(create_text_column("Similar Artists", true, -1, "text", SimilarColumn.NAME, "weight", SimilarColumn.STATUS));
		similar_view.append_column(create_text_column("Match", false, 6, "text", SimilarColumn.MATCH_STR, "weight", SimilarColumn.STATUS));
		similar_view.tooltip_column = SimilarColumn.TOOLTIP;
		similar_view.expand = true;
		similar_view.selection.set_mode(Gtk.SelectionMode.MULTIPLE);
		similar_view.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, { Abraca.TargetEntry.Collection }, Gdk.DragAction.MOVE);
		similar_view.drag_data_get.connect((self, ctx, selection_data, info, time) => {
			var entries = similar_view.get_selected_rows<string>(SimilarColumn.ID);
			DragDropUtil.send_collection(selection_data, filter(self, entries, "artist_id"));
		});

		var side_projects_view = new Abraca.TreeView();
		var sorted_side_project_store = new Gtk.TreeModelSort.with_model(side_project_store);
		sorted_side_project_store.set_sort_column_id(SideProjectColumn.NAME, Gtk.SortType.ASCENDING);
		side_projects_view.set_model(sorted_side_project_store);
		side_projects_view.append_column(create_text_column("Side Projects", true, -1, "text", SideProjectColumn.NAME, "weight", SideProjectColumn.STATUS));
		side_projects_view.tooltip_column = SideProjectColumn.TOOLTIP;
		side_projects_view.expand = true;
		side_projects_view.selection.set_mode(Gtk.SelectionMode.MULTIPLE);
		side_projects_view.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, { Abraca.TargetEntry.Collection }, Gdk.DragAction.MOVE);
		side_projects_view.drag_data_get.connect((self, ctx, selection_data, info, time) => {
			var entries = side_projects_view.get_selected_rows<string>(SideProjectColumn.ID);
			DragDropUtil.send_collection(selection_data, filter(self, entries, "artist_id"));
		});

		attach (create_scroll (relations_view), 0, 0, 2, 1);
		attach (create_scroll (releases_view), 0, 1, 2, 1);
		attach (create_scroll (similar_view), 0, 2, 1, 1);
		attach (create_scroll (side_projects_view), 1, 2, 1, 1);
	}

	private int sort_releases(Gtk.TreeModel model, Gtk.TreeIter iter1, Gtk.TreeIter iter2)
	{
		string title1, title2, date1, date2;
		int result;

		model.get(iter1, ReleaseColumn.TITLE, out title1, ReleaseColumn.DATE, out date1);
		model.get(iter2, ReleaseColumn.TITLE, out title2, ReleaseColumn.DATE, out date2);

		result = GLib.strcmp(date2, date1);
		if (result == 0)
			return GLib.strcmp(title1, title2);
		return result;
	}

	private void on_playback_current_id (Client c, int mid)
	{
		c.xmms.medialib_get_info(mid).notifier_set(on_media_info);
	}

	private bool on_media_info (Xmms.Value propdict)
	{
		string? new_artist_id = null;
		var val = propdict.propdict_to_dict();

		if (val.dict_entry_get_string("artist_id", out new_artist_id) && this.artist_id != new_artist_id) {
			this.artist_id = new_artist_id;

			relation_store.clear();
			release_store.clear();
			similar_store.clear();
			side_project_store.clear();

			refresh_artist_relations.begin((obj,res) => {
				try {
					refresh_artist_relations.end(res);
				} catch (GLib.Error e) {
					GLib.warning(e.message);
				}
			});
			refresh_releases.begin((obj,res) => {
				try {
					refresh_releases.end(res);
				} catch (GLib.Error e) {
					GLib.warning(e.message);
				}
			});
			refresh_similar_artists.begin((obj,res) => {
				try {
					refresh_similar_artists.end(res);
				} catch (GLib.Error e) {
					GLib.warning(e.message);
				}
			});
		}

		return true;
	}

	private static Xmms.Collection equals(string field, string value)
	{
		var equals = new Xmms.Collection(Xmms.CollectionType.EQUALS);
		equals.add_operand(Xmms.Collection.universe());
		equals.attribute_set("field", field);
		equals.attribute_set("value", value);
		return equals;
	}

	private async void refresh_artist_relations ()
		throws GLib.Error
	{
		var path = "/ws/2/artist/%s?inc=url-rels+artist-rels".printf(artist_id);
		var data = yield HTTPClient.get_content("musicbrainz.org", path);

		var builder = new ArtistBuilder();

		artist_parser.parse(data, builder);

		var artist = builder.build();

		foreach (var relation in artist.relations) {
			Gtk.TreeIter iter;
			relation_store.append(out iter);
			relation_store.set(iter,
			                   RelationColumn.TYPE, relation.relation_type,
			                   RelationColumn.NAME, relation.name,
			                   RelationColumn.SORT_NAME, relation.sort_name,
			                   RelationColumn.TOOLTIP, GLib.Markup.escape_text(relation.name));
		}

		refresh_side_project.begin(artist.relations);
	}

	private async void refresh_side_project(Gee.List<Relation> artists)
		throws GLib.Error
	{
		var side_projects = new Gee.HashMap<string,Relation>();

		foreach (var relation in artists) {
			var path = "/ws/2/artist/%s?inc=url-rels+artist-rels".printf(relation.id);
			var data = yield HTTPClient.get_content("musicbrainz.org", path);

			var builder = new ArtistBuilder();

			artist_parser.parse(data, builder);

			var artist = builder.build();

			foreach (var side_project in artist.relations) {
				if (side_project.id == artist_id)
					continue;
				if (!side_projects.contains(side_project.id))
					side_projects.set(side_project.id, side_project);
			}
		}

		foreach (var side_project in side_projects.values) {
			Gtk.TreeIter iter;
			side_project_store.append(out iter);
			side_project_store.set(iter,
			                       SideProjectColumn.ID, side_project.id,
			                       SideProjectColumn.NAME, side_project.name,
			                       SideProjectColumn.SORT_NAME, side_project.sort_name,
			                       SideProjectColumn.STATUS, Status.MISSING,
			                       SideProjectColumn.TOOLTIP, GLib.Markup.escape_text(side_project.name));
		}

		scan_medialib(side_projects.keys, "artist_id", (artist_id) => {
			Gtk.TreeIter iter;

			if (!side_project_store.get_iter_first(out iter))
				return;

			do {
				unowned string entry_id;
				side_project_store.get(iter, SideProjectColumn.ID, out entry_id);
				if (artist_id == entry_id) {
					side_project_store.set(iter, SideProjectColumn.STATUS, Status.AVAILABLE);
					break;
				}
			} while (side_project_store.iter_next(ref iter));
		});
	}

	private async void refresh_releases()
		throws GLib.Error
	{
		var release_groups = new Gee.ArrayList<ReleaseGroup>();

		var path = "/ws/2/release?artist=%s&inc=release-groups+labels+media&offset=0&limit=100".printf(artist_id);
		var data = yield HTTPClient.get_content("musicbrainz.org", path);

		release_groups_parser.parse(data, release_groups);

		foreach (var release_group in release_groups) {
			Gtk.TreeIter iter;
			release_store.append(out iter);
			var title = release_group.title;
			if (release_group.release_type != null)
				title = "%s [%s]".printf(title, release_group.release_type.down());

			var releases = new string[release_group.releases.size];
			for (var i = 0; i < releases.length; i++)
				releases[i] = release_group.releases[i].id;

			release_store.set(iter,
			                  ReleaseColumn.TITLE, title,
			                  ReleaseColumn.DATE, release_group.date,
			                  ReleaseColumn.ID, release_group.id,
			                  ReleaseColumn.STATUS, Status.MISSING,
			                  ReleaseColumn.TOOLTIP, GLib.Markup.escape_text(title));
			scan_available_releases(release_group.id, release_group.releases);
		}
	}

	private void scan_available_releases(string release_group_id, Gee.List<Release> releases)
	{
		var union = new Xmms.Collection(Xmms.CollectionType.UNION);

		foreach (var release in releases) {
			union.add_operand(equals("album_id", release.id));
		}

		var order = new Xmms.Value.from_list();
		var fields = new Xmms.Value.from_list();
		fields.list_append_string("album_id");

		client.xmms.coll_query_infos(union, order, 0, 0, fields, fields).notifier_set_full((value) => {
				Gtk.TreeIter iter;
				if (value.list_get_size() == 0)
					return true;
				if (!release_store.get_iter_first(out iter))
					return true;
				do {
					unowned string entry_id;
					release_store.get(iter, ReleaseColumn.ID, out entry_id);
					if (release_group_id == entry_id) {
						string[] album_ids = new string[value.list_get_size()];
						unowned string album_id;
						for (var i = 0; i < value.list_get_size(); i++) {
							unowned Xmms.Value row;
							if (!value.list_get(i, out row))
								continue;
							if (!row.dict_entry_get_string("album_id", out album_id))
								continue;
							album_ids[i] = album_id;
						}

						release_store.set(iter, ReleaseColumn.STATUS, Status.AVAILABLE, ReleaseColumn.RELEASES, string.joinv(":", album_ids));
					}

				} while (release_store.iter_next(ref iter));
				return true;
			});
	}

	private async void refresh_similar_artists()
		throws GLib.Error
	{
		var artists = new Gee.ArrayList<Artist>();
		var artist_ids = new Gee.ArrayList<string>();

		var path = "/2.0/?mbid=%s&api_key=2e752022a435df5a41203eeebfe8920b&limit=10&method=artist.getsimilar".printf(artist_id);
		var data = yield HTTPClient.get_content("ws.audioscrobbler.com", path);

		similar_artists_parser.parse(data, artists);

		foreach (var similar_artist in artists) {
			Gtk.TreeIter iter;
			similar_store.append(out iter);
			similar_store.set(iter,
			                  SimilarColumn.ID, similar_artist.id,
			                  SimilarColumn.NAME, similar_artist.name,
			                  SimilarColumn.MATCH_INT, int.parse(similar_artist.sort_name),
			                  SimilarColumn.MATCH_STR, "%s%%".printf(similar_artist.sort_name),
			                  SimilarColumn.STATUS, Status.MISSING,
			                  SimilarColumn.TOOLTIP, GLib.Markup.escape_text(similar_artist.name));
			artist_ids.add(similar_artist.id);
		}

		scan_medialib(artist_ids, "artist_id", (artist_id) => {
			Gtk.TreeIter iter;

			if (!similar_store.get_iter_first(out iter))
				return;

			do {
				unowned string entry_id;
				similar_store.get(iter, SimilarColumn.ID, out entry_id);
				if (artist_id == entry_id) {
					similar_store.set(iter, SimilarColumn.STATUS, Status.AVAILABLE);
					break;
				}
			} while (similar_store.iter_next(ref iter));
		});
	}

	private void scan_medialib(Gee.Collection<string> entry_ids, string key, MusicbrainzIdFoundFunc func)
	{
		var union = new Xmms.Collection(Xmms.CollectionType.UNION);

		foreach (var entry_id in entry_ids) {
			union.add_operand(equals(key, entry_id));
		}

		var order = new Xmms.Value.from_list();
		var fields = new Xmms.Value.from_list();
		fields.list_append_string(key);

		client.xmms.coll_query_infos(union, order, 0, 0, fields, fields).notifier_set_full((value) => {
			unowned Xmms.Value entry;

			if (value.list_get_size() == 0)
				return true;

			for (var i = 0; value.list_get(i, out entry); i++) {
				string entry_id;

				if (!entry.dict_entry_get_string(key, out entry_id))
					continue;

				func(entry_id);
			}

			return true;
		});
	}
}
