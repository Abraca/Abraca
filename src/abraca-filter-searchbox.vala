public class Abraca.FilterSearchBox : Gtk.Entry, Searchable {
	private string current_query;
	private uint timer = 0;

	/* TODO: this is a hack, remove me */
	private FilterView treeview;

	public FilterSearchBox (Client client, Config config, FilterView tv)
	{
		treeview = tv;

		primary_icon_name = "edit-find";
		secondary_icon_name = "edit-clear";
		secondary_icon_activatable = true;

		changed.connect(on_filter_entry_changed);
		icon_release.connect(on_filter_entry_clear);
	}


	private void on_filter_entry_clear (Gtk.EntryIconPosition pos)
	{
		if (pos == Gtk.EntryIconPosition.PRIMARY)
			return;

		text = "";
	}


	private void on_filter_entry_changed ()
	{
		bool invalid = false;
		Xmms.Collection coll;

		var query = get_text();

		if (query.length > 0) {
			if (Xmms.Collection.parse(query, out coll)) {
				current_query = query;

				// Throttle collection querying
				if (timer == 0) {
					timer = GLib.Timeout.add(450, on_collection_query_timeout);
				}
			} else {
				invalid = true;
			}
		}

		if (invalid)
			add_css_class("error");
		else
			remove_css_class("error");
	}


	private bool on_collection_query_timeout()
	{
		Xmms.Collection coll;

		if (current_query == null) {
			timer = 0;
			return false;
		}

		if (!Xmms.Collection.parse(current_query, out coll)) {
			current_query = null;
			timer = 0;
			return false;
		}

		treeview.query_collection(coll);

		current_query = null;

		return true;
	}


	public void search(string text)
	{
		this.text = text;
	}
}
