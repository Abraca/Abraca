/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2011  Abraca Team
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

public class Abraca.FilterBrowserView : Gtk.TreeView, SelectedRowsMixin {
	private FilterBrowserView previous;

	public Xmms.Collection filter { get; private set; }

	private static void query_from_match (GLib.StringBuilder sb, Xmms.Collection match) {
		unowned string value, field;

		match.attribute_get ("field", out field);
		match.attribute_get ("value", out value);
		sb.append (field);
		sb.append (":\"");
		sb.append (value.replace ("\"", "\\\""));
		sb.append ("\"");
	}

	public string query { get; private set; }

	public FilterBrowserView (FilterBrowserModel model, FilterBrowserView? previous = null) {
		this.previous = previous;
		set_model(model);

		var selection = get_selection();
		selection.set_mode(Gtk.SelectionMode.MULTIPLE);
		selection.changed.connect(on_selection_changed);

		if (previous != null) {
			previous.notify["filter"].connect ((s,p) => {
				GLib.debug ("setting model filter for %s", ((FilterBrowserModel) model).field);

				((FilterBrowserModel) model).filter = previous.filter;
				on_selection_changed (selection);
			});
		}
	}

	private void on_selection_changed (Gtk.TreeSelection selection)
	{
		var intersection = new Xmms.Collection (Xmms.CollectionType.INTERSECTION);
		if (previous != null) {
			intersection.add_operand (previous.filter);
		} else {
			intersection.add_operand (Xmms.Collection.universe());
		}

		var entries = get_selected_rows<string>(0);
		if (entries.size > 0) {
			var field = ((FilterBrowserModel) model).field;
			var union = new Xmms.Collection (Xmms.CollectionType.UNION);
			foreach (var entry in entries) {
				var match = new Xmms.Collection (Xmms.CollectionType.MATCH);
				match.attribute_set ("field", field);
				match.attribute_set ("value", entry);
				match.add_operand (Xmms.Collection.universe());
				union.add_operand (match);
			}
			intersection.add_operand (union);
			update_query_string (union);
		} else {
			intersection.add_operand (Xmms.Collection.universe());
			update_query_string (null);
		}

		filter = intersection;
	}

	private void update_query_string (Xmms.Collection? union)
	{
		var sb = new GLib.StringBuilder();

		if (previous != null && previous.query.length > 0)
			sb.append (previous.query);

		if (union != null) {
			unowned Xmms.ListIter it;

			var operands = union.operands_get();
			if (sb.len > 0 && operands.list_get_size() > 0)
				sb.append (" AND ");

			if (operands.list_get_size() > 1)
				sb.append("(");

			operands.get_list_iter(out it);
			for (it.first(); it.valid(); it.next()) {
				unowned Xmms.Collection match;
				it.entry_coll(out match);
				if (it.tell() > 0)
					sb.append(" OR ");
				query_from_match(sb, match);
			}

			if (operands.list_get_size() > 1)
				sb.append(")");
		}

		query = sb.str.dup ();
	}

}

public class Abraca.FilterBrowser : Gtk.HBox {
	private static FilterBrowserView add_treeview (FilterBrowserModel model, FilterBrowserView? previous = null)
	{
		var view = new FilterBrowserView (model, previous);
		view.set_model (model);


		var renderer = new Gtk.CellRendererText();
		renderer.ellipsize = Pango.EllipsizeMode.END;

		var column = new Gtk.TreeViewColumn.with_attributes (
			model.field, renderer, "markup", 0, null
		);
		column.sizing = Gtk.TreeViewColumnSizing.FIXED;
		view.append_column (column);
		view.tooltip_column = 0;
		view.fixed_height_mode = true;

		return view;
	}

	private static void add_scroll (Gtk.Box container, Gtk.Widget widget)
	{
		var scrolled = new Gtk.ScrolledWindow(null, null);
		scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		scrolled.set_shadow_type(Gtk.ShadowType.IN);
		scrolled.add(widget);
		container.pack_start(scrolled, true, true, 2);
	}

	public FilterBrowser (Client client, Config config, Searchable searchable)
	{
		var properties = new string[] { "publisher", "catalognumber", "artist", "album" };

		FilterBrowserView previous = null;

		foreach (var property in properties) {
			var model = new FilterBrowserModel (client, property);
			var view = add_treeview (model, previous);
			add_scroll(this, view);
			previous = view;
		}

		previous.notify["query"].connect ((s,p) => {
			searchable.search (previous.query);
		});
	}
}