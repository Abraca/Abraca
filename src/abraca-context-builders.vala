public class Abraca.Artist : Object
{
	public string id { get; private set; }
	public string name { get; private set; }
	public string sort_name { get; private set; }
	public Gee.List<ReleaseGroup> release_groups { get; private set; }
	public Gee.List<Relation> relations { get; private set; }
	public Gee.List<URL> urls { get; private set; }
	public Gee.List<Artist> similar_artists { get; private set; }

	public Artist(string id, string name, string sort_name, Gee.List<ReleaseGroup> release_groups, Gee.List<Relation> relations, Gee.List<URL> urls, Gee.List<Artist> similar_artists)
	{
		this.id = id;
		this.name = name;
		this.sort_name = sort_name;
		this.release_groups = release_groups;
		this.relations = relations;
		this.urls = urls;
		this.similar_artists = similar_artists;
	}
}

public class Abraca.ReleaseGroup : Object
{
	public string id { get; private set; }
	public string title { get; private set; }
	public string? date { get; private set; }
	public string? release_type { get; private set; }
	public Gee.List<Release> releases { get; private set; }

	public ReleaseGroup(string id, string title, string? date, string? release_type, Gee.List<Release> releases)
	{
		this.id = id;
		this.title = title;
		this.date = date;
		this.release_type = release_type;
		this.releases = releases;
	}
}

public class Abraca.Release : Object
{
	public string id { get; private set; }
	public string title { get; private set; }
	public string? date { get; private set; }
	public string? status { get; private set; }
	public string? country { get; private set; }
	public string? label { get; private set; }
	public string? label_id { get; private set; }
	public string? catalog_number { get; private set; }
	public string? asin { get; private set; }
	public string? barcode { get; private set; }

	public Release(string id, string title, string? date, string? status, string? country, string? label, string? label_id, string? catalog_number, string? asin, string? barcode)
	{
		this.id = id;
		this.title = title;
		this.date = date;
		this.status = status;
		this.country = country;
		this.label = label;
		this.label_id = label_id;
		this.catalog_number = catalog_number;
		this.asin = asin;
		this.barcode = barcode;
	}
}

public class Abraca.Relation
{
	public string id { get; private set; }
	public string relation_type { get; private set; }
	public string name { get; private set; }
	public string sort_name { get; private set; }
	public string? start_date { get; private set; }
	public string? end_date { get; private set; }

	public Relation(string id, string relation_type, string name, string sort_name, string? start_date, string? end_date)
	{
		this.id = id;
		this.relation_type = relation_type;
		this.name = name;
		this.sort_name = sort_name;
		this.start_date = start_date;
		this.end_date = end_date;
	}
}


public class Abraca.URL
{
	public string url { get; private set; }
	public string category { get; private set; }

	public URL (string url, string category)
	{
		this.url = url;
		this.category = category;
	}
}

public class Abraca.RelationBuilder
{
	private string id;
	private string relation_type;
	private string name;
	private string sort_name;
	private string start_date;
	private string end_date;

	public RelationBuilder set_id (string id)
	{
		this.id = id;
		return this;
	}

	public RelationBuilder set_type (string relation_type)
	{
		this.relation_type = relation_type;
		return this;
	}

	public RelationBuilder set_name (string name)
	{
		this.name = name;
		return this;
	}

	public RelationBuilder set_sort_name (string sort_name)
	{
		this.sort_name = sort_name;
		return this;
	}

	public RelationBuilder set_start_date (string start_date)
	{
		this.start_date = start_date;
		return this;
	}

	public RelationBuilder set_end_date (string end_date)
	{
		this.end_date = end_date;
		return this;
	}

	public Relation build ()
	{
		var relation = new Relation (id, relation_type, name, sort_name, start_date, end_date);
		this.id = null;
		this.relation_type = null;
		this.name = null;
		this.sort_name = null;
		this.start_date = null;
		this.end_date = null;
		return relation;
	}
}

public class Abraca.URLBuilder
{
	private string url;
	private string category;

	public URLBuilder set_url (string url)
	{
		this.url = url;
		return this;
	}

	public URLBuilder set_category (string category)
	{
		this.category = category;
		return this;
	}

	public URL build ()
	{
		var url = new URL (url, category);
		this.url = null;
		this.category = null;
		return url;
	}
}

public class Abraca.ReleaseGroupBuilder
{
	private string id;
	private string title;
	private string? date;
	private string? release_type;
	private Gee.List<Release> releases;

	public ReleaseGroupBuilder set_id(string id)
	{
		this.id = id;
		return this;
	}

	public ReleaseGroupBuilder set_title(string title)
	{
		this.title = title;
		return this;
	}

	public ReleaseGroupBuilder set_date(string? date)
	{
		this.date = date;
		return this;
	}

	public ReleaseGroupBuilder set_release_type(string? release_type)
	{
		this.release_type = release_type;
		return this;
	}

	public ReleaseGroupBuilder add_release(Release release)
	{
		if (this.releases == null)
			this.releases = new Gee.ArrayList<Release>();
		this.releases.add(release);
		return this;
	}

	public ReleaseGroup build()
	{
		var releases = this.releases != null ? this.releases.read_only_view : Gee.List.empty<Release>();
		var release_group = new ReleaseGroup(id, title, date, release_type, releases);
		id = null;
		title = null;
		date = null;
		release_type = null;
		releases = null;
		return release_group;
	}
}

public class Abraca.ReleaseBuilder
{
	private string id;
	private string title;
	private string? date;
	private string? status;
	private string? country;
	private string? label;
	private string? label_id;
	private string? catalog_number;
	private string? asin;
	private string? barcode;

	public ReleaseBuilder set_id(string id)
	{
		this.id = id;
		return this;
	}

	public ReleaseBuilder set_title(string title)
	{
		this.title = title;
		return this;
	}

	public ReleaseBuilder set_date(string? date)
	{
		this.date = date;
		return this;
	}

	public ReleaseBuilder set_status(string? status)
	{
		this.status = status;
		return this;
	}

	public ReleaseBuilder set_country(string? country)
	{
		this.country = country;
		return this;
	}

	public ReleaseBuilder set_label(string? label)
	{
		this.label = label;
		return this;
	}

	public ReleaseBuilder set_label_id(string? label_id)
	{
		this.label_id = label_id;
		return this;
	}

	public ReleaseBuilder set_catalog_number(string? catalog_number)
	{
		this.catalog_number = catalog_number;
		return this;
	}

	public ReleaseBuilder set_asin(string? asin)
	{
		this.asin = asin;
		return this;
	}

	public ReleaseBuilder set_barcode(string? barcode)
	{
		this.barcode = barcode;
		return this;
	}

	public Release? build()
	{
		var release = new Release(id, title, date, status, country, label, label_id, catalog_number, asin, barcode);
		id = null;
		title = null;
		date = null;
		status = null;
		country = null;
		label = null;
		label_id = null;
		catalog_number = null;
		asin = null;
		barcode = null;
		return release;
	}
}

public class Abraca.ArtistBuilder
{
	private string id;
	private string name;
	private string sort_name;
	private string? country;
	private Gee.List<URL> urls = null;
	private Gee.List<ReleaseGroup> release_groups = null;
	private Gee.List<Relation> relations = null;
	private Gee.List<Artist> similar_artists = null;

	public ArtistBuilder set_id(string id)
	{
		this.id = id;
		return this;
	}

	public ArtistBuilder set_name(string name)
	{
		this.name = name;
		return this;
	}

	public ArtistBuilder set_sort_name(string sort_name)
	{
		this.sort_name = sort_name;
		return this;
	}

	public ArtistBuilder set_country(string country)
	{
		this.country = country;
		return this;
	}

	public ArtistBuilder add_release_group(ReleaseGroup release)
	{
		if (this.release_groups == null)
			this.release_groups = new Gee.ArrayList<ReleaseGroup>();
		this.release_groups.add(release);
		return this;
	}

	public ArtistBuilder add_relation(Relation release)
	{
		if (this.relations == null)
			this.relations = new Gee.ArrayList<Relation>();
		this.relations.add(release);
		return this;
	}

	public ArtistBuilder add_url (URL url)
	{
		if (this.urls == null)
			this.urls = new Gee.ArrayList<URL>();
		this.urls.add(url);
		return this;
	}

	public ArtistBuilder add_similar_artist (Artist artist)
	{
		if (this.similar_artists == null)
			this.similar_artists = new Gee.ArrayList<Artist>();
		this.similar_artists.add(artist);
		return this;
	}

	public Artist build()
	{
		var urls = this.urls != null ? this.urls.read_only_view : Gee.List.empty<URL>();
		var relations = this.relations != null ? this.relations.read_only_view : Gee.List.empty<Relation>();
		var release_groups = this.release_groups != null ? this.release_groups.read_only_view : Gee.List.empty<ReleaseGroup>();
		var similar_artists = this.similar_artists != null ? this.similar_artists.read_only_view : Gee.List.empty<Artist>();

		var artist = new Artist(id, name, sort_name, release_groups, relations, urls, similar_artists);

		this.id = null;
		this.name = null;
		this.sort_name = null;
		this.release_groups = null;
		this.relations = null;
		this.urls = null;
		this.similar_artists = null;

		return artist;
	}
}
