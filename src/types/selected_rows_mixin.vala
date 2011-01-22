namespace Abraca {
	public interface SelectedRowsMixin : Gtk.TreeView {
		public delegate void RowIteratorFunc<T> (int pos, T ret);

		public Gee.List<T> get_selected_rows<T> (int column)
		{
			var result = new Gee.LinkedList<T>();

			var list = get_selection().get_selected_rows(null);
			foreach (unowned Gtk.TreePath path in list) {
				Gtk.TreeIter iter;
				T val;
				model.get_iter(out iter, path);
				model.get(iter, column, out val);
				result.add(val);
			}
			return result;
		}

		public void foreach_selected_row<T> (int column, RowIteratorFunc<T> func)
		{
			var list = get_selection().get_selected_rows(null);
			foreach (unowned Gtk.TreePath path in list) {
				Gtk.TreeIter iter;
				T val;

				var pos = path.get_indices ()[0];

				model.get_iter(out iter, path);
				model.get(iter, column, out val);

				func (pos, val);
			}
		}
	}
}