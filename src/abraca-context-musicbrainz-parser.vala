public class Abraca.MusicBrainz.ReleaseParser : Abraca.AbstractParser<Gee.List<ReleaseGroup>>
{
	private const GLib.MarkupParser release_parser = { on_release_start, on_release_end, on_text, null, null };
	private const GLib.MarkupParser label_parser = { on_label_start, null, on_text, null, null };
	private const GLib.MarkupParser release_group_parser = { on_release_group_start, null, on_text, null, null };

	private Gee.Map<string, ReleaseGroupBuilder> release_group_builders = new Gee.HashMap<string, ReleaseGroupBuilder>();

	private ReleaseBuilder release_builder = new ReleaseBuilder();

	private ReleaseGroupBuilder release_group_builder;

	public ReleaseParser()
	{
		this.context = new GLib.MarkupParseContext(release_parser, 0, this, null);
	}

	private void set_release_group_builder(string release_group_id)
	{
		release_group_builder = release_group_builders.get(release_group_id);
		if (release_group_builder == null) {
			release_group_builder = new ReleaseGroupBuilder();
			release_group_builder.set_id(release_group_id);
			release_group_builders.set(release_group_id, release_group_builder);
		}
	}

	private void on_release_start (GLib.MarkupParseContext context, string name, string[] keys, string[] values)
		throws GLib.MarkupError
	{
		switch (name) {
		case "release":
			var release_id = find_attribute(keys, values, "id");
			release_builder.set_id(release_id);
			break;
		case "title":
			set_text_handler((text) => release_builder.set_title(text));
			break;
		case "status":
			set_text_handler((text) => release_builder.set_status(text));
			break;
		case "date":
			set_text_handler((text) => release_builder.set_status(text));
			break;
		case "asin":
			set_text_handler((text) => release_builder.set_asin(text));
			break;
		case "barcode":
			set_text_handler((text) => release_builder.set_barcode(text));
			break;
		case "label-info":
			context.push (label_parser, this);
			break;
		case "release-group":
			var release_group_id = find_attribute(keys, values, "id");
			set_release_group_builder(release_group_id);
			var release_type = find_attribute(keys, values, "type");
			release_group_builder.set_release_type(release_type);
			context.push (release_group_parser, this);
			break;
		}
	}

	private void on_release_end (GLib.MarkupParseContext context, string name)
		throws GLib.MarkupError
	{
		switch (name) {
		case "label-info":
			context.pop();
			break;
		case "release-group":
			context.pop();
			break;
		case "release":
			release_group_builder.add_release(release_builder.build());
			release_group_builder = null;
			break;
		case "release-list":
			foreach (var release_group_builder in release_group_builders.values)
				builder.add(release_group_builder.build());
			release_group_builders.clear();
			break;
		}
	}

	private void on_label_start (GLib.MarkupParseContext context, string name, string[] keys, string[] values)
		throws GLib.MarkupError
	{
		switch (name) {
		case "label":
			var label_id = find_attribute(keys, values, "id");
			release_builder.set_label_id(label_id);
			break;
		case "catalog-number":
			set_text_handler((text) => release_builder.set_catalog_number(text));
			break;
		case "name":
			set_text_handler((text) => release_builder.set_label(text));
			break;
		}
	}


	private void on_release_group_start (GLib.MarkupParseContext context, string name, string[] keys, string[] values)
		throws GLib.MarkupError
	{
		switch (name) {
		case "title":
			set_text_handler((text) => release_group_builder.set_title(text));
			break;
		case "first-release-date":
			set_text_handler((text) => release_group_builder.set_date(text));
			break;
		}
	}
}

public class Abraca.MusicBrainz.ArtistParser: Abraca.AbstractParser<ArtistBuilder>
{
	const GLib.MarkupParser url_parser = { on_url_start, on_url_end, on_text, null, null };
	const GLib.MarkupParser artist_parser = { on_artist_start, on_artist_end, on_text, null, null };
	const GLib.MarkupParser relation_parser = { on_relation_start, on_relation_end, on_text, null, null };

	private URLBuilder url_builder = new URLBuilder();
	private RelationBuilder relation_builder = new RelationBuilder();

	public ArtistParser()
	{
		this.context = new GLib.MarkupParseContext(artist_parser, 0, this, null);
	}

	private void on_artist_start (GLib.MarkupParseContext context, string name, string[] keys, string[] values)
		throws GLib.MarkupError
	{
		switch (name) {
		case "artist":
			var artist_id = find_attribute(keys, values, "id");
			builder.set_id(artist_id);
			break;
		case "name":
			set_text_handler((text) => builder.set_name(text));
			break;
		case "sort-name":
			set_text_handler((text) => builder.set_sort_name(text));
			break;
		case "relation-list":
			var target_type = find_attribute (keys, values, "target-type");
			switch (target_type) {
			case "artist":
				context.push (relation_parser, this);
				break;
			case "url":
				context.push (url_parser, this);
				break;
			}
			break;
		}
	}

	private void on_artist_end (GLib.MarkupParseContext context, string name)
		throws MarkupError
	{
		switch (name) {
		case "relation-list":
			context.pop();
			break;
		}
	}

	private void on_relation_start (GLib.MarkupParseContext context, string name, string[] keys, string[] values)
		throws GLib.MarkupError
	{
		switch (name) {
		case "relation":
			var relation_type = find_attribute(keys, values, "type");
			relation_builder.set_type(relation_type);
			break;
		case "target":
			set_text_handler((text) => relation_builder.set_id(text));
			break;
		case "begin":
			set_text_handler((text) => relation_builder.set_start_date(text));
			break;
		case "end":
			set_text_handler((text) => relation_builder.set_end_date(text));
			break;
		case "name":
			set_text_handler((text) => relation_builder.set_name(text));
			break;
		case "sort-name":
			set_text_handler((text) => relation_builder.set_sort_name(text));
			break;
		default:
			break;
		}
	}

	private void on_relation_end (GLib.MarkupParseContext context, string name)
		throws GLib.MarkupError
	{
		switch (name) {
		case "relation":
			var relation = relation_builder.build();
			builder.add_relation(relation);
			break;
		default:
			break;
		}
	}

	private void on_url_start (GLib.MarkupParseContext context, string name, string[] keys, string[] values)
		throws GLib.MarkupError
	{
		switch (name) {
		case "relation":
			var category = find_attribute(keys, values, "type");
			url_builder.set_category(category);
			break;
		case "target":
			set_text_handler((text) => url_builder.set_url(text));
			break;
		default:
			break;
		}
	}

	private void on_url_end (GLib.MarkupParseContext context, string name)
		throws GLib.MarkupError
	{
		switch (name) {
		case "relation":
			var url = url_builder.build();
			builder.add_url(url);
			break;
		default:
			break;
		}
	}
}
