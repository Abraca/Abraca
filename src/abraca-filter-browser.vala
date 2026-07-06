/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2014 Abraca Team
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

public class Abraca.FilterBrowserView : Abraca.SelectableView {
	private FilterBrowserView previous;
	private FilterBrowserModel browser_model;

	public Xmms.Collection filter { get; private set; }

	public string query { get; private set; }

	public FilterBrowserView(FilterBrowserModel model, FilterBrowserView? previous = null) {
		this.previous = previous;
		this.browser_model = model;

		use_model(model.store, true);

		create_column();

		selection.selection_changed.connect((pos, n) => { on_selection_changed(); });

		if (previous != null) {
			previous.notify["filter"].connect((s,p) => {
				GLib.debug("setting model filter for %s", browser_model.field);
				browser_model.filter = previous.filter;
				on_selection_changed();
			});
		}
	}

	private void create_column()
	{
		var factory = new Gtk.SignalListItemFactory();
		factory.setup.connect(li => {
			var label = new Gtk.Label(null) {
				xalign = 0,
				ellipsize = Pango.EllipsizeMode.END
			};
			((Gtk.ListItem) li).set_child(label);

			var source = new Gtk.DragSource();
			source.set_actions(Gdk.DragAction.COPY);
			source.prepare.connect((x, y) => {
				if (filter == null)
					return null;
				return DragDropUtil.content_for_collection(filter);
			});
			label.add_controller(source);
		});
		factory.bind.connect(li => {
			var so = (Gtk.StringObject) ((Gtk.ListItem) li).get_item();
			var label = (Gtk.Label) ((Gtk.ListItem) li).get_child();
			label.label = so.string;
			label.tooltip_text = so.string;
		});

		var column = new Gtk.ColumnViewColumn(browser_model.field, factory);
		column.expand = true;
		append_column(column);
	}

	private void on_selection_changed()
	{
		var intersection = new Xmms.Collection(Xmms.CollectionType.INTERSECTION);
		if (previous != null && previous.filter != null) {
			intersection.add_operand(previous.filter);
		} else {
			intersection.add_operand(Xmms.Collection.universe());
		}

		var entries = new Gee.ArrayList<string>();
		foreach_selected((pos, obj) => {
			entries.add(((Gtk.StringObject) obj).string);
		});

		if (entries.size > 0) {
			var field = browser_model.field;
			var union = new Xmms.Collection(Xmms.CollectionType.UNION);
			foreach (var entry in entries) {
				var match = new Xmms.Collection(Xmms.CollectionType.MATCH);
				match.attribute_set("field", field);
				match.attribute_set("value", entry);
				match.add_operand(Xmms.Collection.universe());
				union.add_operand(match);
			}
			intersection.add_operand(union);
			update_query_string(union);
		} else {
			intersection.add_operand(Xmms.Collection.universe());
			update_query_string(null);
		}

		filter = intersection;
	}

	private void update_query_string(Xmms.Collection? union)
	{
		var sb = new GLib.StringBuilder();

		if (previous != null && previous.query != null)
			sb.append(previous.query);

		if (union != null) {
			unowned Xmms.ListIter it;

			var operands = union.operands_get();
			if (sb.len > 0 && operands.list_get_size() > 0)
				sb.append(" AND ");

			if (operands.list_get_size() > 1)
				sb.append("(");

			operands.get_list_iter(out it);
			for (it.first(); it.valid(); it.next()) {
				unowned Xmms.Collection match;
				unowned string value, field;

				it.entry_coll(out match);
				if (it.tell() > 0)
					sb.append(" OR ");

				match.attribute_get("field", out field);
				match.attribute_get("value", out value);
				sb.append(field);
				sb.append(":\"");
				sb.append(value.replace ("\"", "\\\""));
				sb.append("\"");
			}

			if (operands.list_get_size() > 1)
				sb.append(")");
		}

		query = sb.str.dup();
	}

}

public class Abraca.FilterBrowser : Gtk.Box {
	private static FilterBrowserView add_treeview (FilterBrowserModel model, FilterBrowserView? previous = null)
	{
		return new FilterBrowserView (model, previous);
	}

	private static void add_scroll (Gtk.Box container, Gtk.Widget widget)
	{
		var scrolled = new Gtk.ScrolledWindow();
		scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		scrolled.hexpand = true;
		scrolled.set_child(widget);
		container.append(scrolled);
	}

	public FilterBrowser (Client client, Config config, Searchable searchable)
	{
		Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 2);

		var properties = new string[] { "publisher", "artist", "album" };

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
