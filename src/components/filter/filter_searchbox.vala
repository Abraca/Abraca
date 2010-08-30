public class Abraca.FilterSearchBox : Gtk.ComboBoxEntry, Searchable {
	private Gee.Queue<string> _pending_queries;
	private string _unsaved_query;
	private string _current_query;
	private uint _timer;

	/* TODO: this is a hack, remove me */
	private FilterView treeview;


	public FilterSearchBox (Client client, Config config, FilterView tv)
	{
		_timer = 0;
		_pending_queries = new Gee.LinkedList<string>();
		treeview = tv;

		var entry = child as Gtk.Entry;
		entry.changed.connect(on_filter_entry_changed);
		entry.focus_out_event.connect(on_filter_entry_focus_out_event);

		var comp = new Gtk.EntryCompletion();
		comp.model = model;
		comp.set_text_column(0);

		entry.set_completion(comp);

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


	private void _filter_save (string pattern)
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


	private void on_filter_entry_changed (Gtk.Editable widget)
	{
		Gdk.Color? color = null;
		Xmms.Collection coll;

		var entry = widget as Gtk.Entry;
		var text = entry.get_text();

		if (text.length > 0 && Xmms.Collection.parse(text, out coll)) {
			_current_query = text;

			// Throttle collection querying
			if (_timer == 0) {
				_timer = GLib.Timeout.add(450, on_collection_query_timeout);
			}
		} else {
			Gdk.Color.parse("#ff6666", out color);
		}

		entry.modify_base(Gtk.StateType.NORMAL, color);
	}


	private bool on_collection_query_timeout()
	{
		Xmms.Collection coll;

		if (_current_query == null) {
			_timer = 0;
			return false;
		}

		if (!Xmms.Collection.parse(_current_query, out coll)) {
			_current_query = null;
			_timer = 0;
			return false;
		}

		_pending_queries.offer(_current_query);

		treeview.query_collection(coll, (val) => {
			var s = _pending_queries.poll();
			if (s != null && val.list_get_size() > 0) {
				if (child.has_focus) {
					_unsaved_query = s;
				} else if (_pending_queries.is_empty) {
					_filter_save(s);
				}
			}
			return true;
		});

		_current_query = null;

		return true;
	}


	private bool on_filter_entry_focus_out_event (Gtk.Widget w, Gdk.EventFocus e)
	{
		if (_unsaved_query != null && _unsaved_query == (w as Gtk.Entry).text) {
			_filter_save(_unsaved_query);
		}

		_unsaved_query = null;

		return false;
	}


	public void search(string text)
	{
		Gtk.Entry entry = (Gtk.Entry) child;
		entry.text = text;
	}

}