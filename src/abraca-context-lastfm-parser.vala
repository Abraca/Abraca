public class Abraca.LastFM.SimilarArtistsParser: Abraca.AbstractParser<Gee.List<Abraca.Artist>>
{
	const GLib.MarkupParser artist_parser = { on_artist_start, on_artist_end, on_text, null, null };

	private ArtistBuilder artist_builder = new ArtistBuilder();

	public SimilarArtistsParser()
	{
		this.context = new GLib.MarkupParseContext(artist_parser, 0, this, null);
	}

	private void on_artist_start (GLib.MarkupParseContext context, string name, string[] keys, string[] values)
		throws MarkupError
	{
		switch (name) {
		case "name":
			set_text_handler((text) => artist_builder.set_name (text));
			break;
		case "mbid":
			set_text_handler((text) => artist_builder.set_id(text));
			break;
		case "match":
			set_text_handler ((text) => artist_builder.set_sort_name("%d".printf ((int)(100.0 * double.parse (text)))));
			break;
		}
	}

	private void on_artist_end (GLib.MarkupParseContext context, string name)
		throws MarkupError
	{
		if (name == "artist")
			builder.add(artist_builder.build());
	}
}
