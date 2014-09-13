public class Abraca.FilterSearchBox : Gtk.ComboBox, Searchable {
	private Gee.Queue<string> pending_queries = new Gee.LinkedList<string>();
	private string unsaved_query;
	private string current_query;
	private uint timer = 0;

	/* TODO: this is a hack, remove me */
	private FilterView treeview;

	public FilterSearchBox (Client client, Config config, FilterView tv)
	{
		Object (has_entry: true, entry_text_column: 0);

		treeview = tv;

		model = new Gtk.ListStore.newv({ typeof(string) });

		var entry = get_child() as Gtk.Entry;
		entry.primary_icon_name = "edit-find";
		entry.secondary_icon_name = "edit-clear";
		entry.secondary_icon_activatable = true;

		entry.changed.connect(on_filter_entry_changed);
		entry.icon_release.connect(on_filter_entry_clear);
		entry.focus_out_event.connect(on_filter_entry_focus_out_event);

		var completion = new Gtk.EntryCompletion();
		completion.set_text_column(0);
		completion.model = model;

		entry.set_completion(completion);
	}


	public void set_configuration (GLib.KeyFile file)
		throws GLib.KeyFileError
	{
		if (!file.has_group("filter") || !file.has_key("filter", "patterns"))
			return;

		var store = model as Gtk.ListStore;
		Gtk.TreeIter iter;

		var list = file.get_string_list("filter", "patterns");

		for (int i = 0; i < list.length; i++)
			store.insert_with_values(out iter, i, 0, list[i]);
	}


	public void get_configuration (GLib.KeyFile file)
	{
		Gtk.TreeIter iter;
		string current;
		int i = 0;

		var store = model as Gtk.ListStore;
		var list = new string[25];

		if (store.iter_children(out iter, null)) {
			do {
				store.get(iter, 0, out current);
				list[i++] = current;
			} while (store.iter_next(ref iter) && i < 25);
		}

		file.set_string_list("filter", "patterns", list);
	}


	private void filter_save (string pattern)
	{
		Gtk.ListStore store = (Gtk.ListStore) model;
		Gtk.TreeIter iter;
		string current;

		if (store.iter_children(out iter, null)) {
			do {
				store.get(iter, 0, out current);
				if (current == pattern) {
					store.remove(iter);
					break;
				}
			} while (store.iter_next(ref iter));
		}

		store.insert_with_values(out iter, 0, 0, pattern);
	}


	private void on_filter_entry_clear (Gtk.Entry entry, Gtk.EntryIconPosition pos, Gdk.Event ev)
	{
		if (pos == Gtk.EntryIconPosition.PRIMARY)
			return;

		entry.text = "";
	}


	private void on_filter_entry_changed (Gtk.Editable widget)
	{
		Gdk.RGBA? color = null;
		Xmms.Collection coll;

		var entry = widget as Gtk.Entry;
		var text = entry.get_text();

		if (text.length > 0) {
			if (Xmms.Collection.parse(text, out coll)) {
				current_query = text;

				// Throttle collection querying
				if (timer == 0) {
					timer = GLib.Timeout.add(450, on_collection_query_timeout);
				}
			} else {
				color = Gdk.RGBA();
				color.parse("#ff6666");
			}
		}

		entry.override_background_color(Gtk.StateFlags.NORMAL, color);
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

		pending_queries.offer(current_query);

		treeview.query_collection(coll, (val) => {
			var s = pending_queries.poll();
			if (s != null && val.list_get_size() > 0) {
				if (get_child().has_focus) {
					unsaved_query = s;
				} else if (pending_queries.is_empty) {
					filter_save(s);
				}
			}
			return true;
		});

		current_query = null;

		return true;
	}


	private bool on_filter_entry_focus_out_event (Gtk.Widget w, Gdk.EventFocus e)
	{
		if (unsaved_query != null && unsaved_query == (w as Gtk.Entry).text) {
			filter_save(unsaved_query);
		}

		unsaved_query = null;

		return false;
	}


	public void search(string text)
	{
		var entry = get_child() as Gtk.Entry;
		entry.text = text;
	}

}
