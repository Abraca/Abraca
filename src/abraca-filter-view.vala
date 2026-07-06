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

using GLib;

namespace Abraca {
	public class FilterView : Abraca.SelectableView, IConfigurable {
		/* field and order used for sorting, see sorting property */
		public struct Sorting {
			public unowned string field;
			public Gtk.SortType order;
		}

		private Medialib medialib;
		private Client client;
		private MetadataResolver resolver;

		private FilterModel filter_model;

		private GLib.SimpleActionGroup actions;

		/* properties */
		public Sorting sorting { get; set; }
		public Xmms.Collection collection { get; private set; }

		public FilterView (Client c, MetadataResolver r, Medialib m)
		{
			medialib = m;
			client = c;
			resolver = r;

			create_actions ();
			install_context_menu (build_context_menu ());

			column_view.activate.connect (on_activate);

			var key = new Gtk.EventControllerKey ();
			key.key_pressed.connect (on_key_pressed);
			column_view.add_controller (key);

			notify["sorting"].connect (on_sorting_changed);

			Configurable.register (this);
		}


		public void get_configuration (GLib.KeyFile file)
		{
			var columns = get_columns ();
			var names = new string[columns.get_n_items ()];

			for (uint i = 0; i < columns.get_n_items (); i++)
				names[i] = ((Gtk.ColumnViewColumn) columns.get_item (i)).title;

			file.set_string_list ("filter", "columns", names);
		}


		public void set_configuration (GLib.KeyFile file)
			throws GLib.KeyFileError
		{
			string[] list = new string[0];

			if (file.has_group("filter") && file.has_key("filter", "columns"))
				list = file.get_string_list("filter", "columns");

			if (list.length == 0)
				list = new string[] {"tracknr", "artist", "album", "title", "duration"};

			set_dynamic_columns(list);
		}


		private void on_sorting_changed (GLib.Object source, GLib.ParamSpec pspec)
		{
			if (collection != null)
				query_collection(collection);
		}


		public void query_collection (Xmms.Collection coll, Xmms.NotifierFunc? callback=null)
		{
			Xmms.Value order = new Xmms.Value.from_list();
			Xmms.Result res;

			if (sorting.field == null) {
				order.list_append(new Xmms.Value.from_string("artist"));
				order.list_append(new Xmms.Value.from_string("album"));
				order.list_append(new Xmms.Value.from_string("partofset"));
				order.list_append(new Xmms.Value.from_string("tracknr"));
			} else if (sorting.order == Gtk.SortType.ASCENDING) {
				order.list_append(new Xmms.Value.from_string("-" + sorting.field));
			} else {
				order.list_append(new Xmms.Value.from_string(sorting.field));
			}

			res = client.xmms.coll_query_ids(coll, order);
			res.notifier_set(on_coll_query_ids);
			if (callback != null) {
				res.notifier_set(callback);
			}

			collection = coll;
		}


		public void playlist_replace_with_filter_results ()
		{
			client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
			playlist_add_filter_results ();
		}


		public void playlist_add_filter_results ()
		{
			for (uint i = 0; i < filter_model.store.get_n_items (); i++) {
				var item = (FilterItem) filter_model.store.get_item (i);
				client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, (int) item.id);
			}
		}


		private bool on_coll_query_ids (Xmms.Value val)
		{
			filter_model.replace_content (val);
			return true;
		}


		private bool on_key_pressed (uint keyval, uint keycode, Gdk.ModifierType state)
		{
			if (keyval != Gdk.Key.Return)
				return false;

			if ((state & Gdk.ModifierType.CONTROL_MASK) > 0)
				client.xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);

			foreach_selected ((pos, obj) => {
				client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, (int) ((FilterItem) obj).id);
			});

			return true;
		}


		private void on_activate (uint position)
		{
			var item = (FilterItem) filter_model.store.get_item (position);
			client.xmms.playlist_add_id(Xmms.ACTIVE_PLAYLIST, (int) item.id);
		}


		private void add_selected ()
		{
			foreach_selected ((pos, obj) => {
				client.xmms.playlist_add_id (Xmms.ACTIVE_PLAYLIST, (int) ((FilterItem) obj).id);
			});
		}


		private static bool should_expand (string property)
		{
			switch (property) {
				case "id":
				case "added":
				case "bitrate":
				case "date":
				case "duration":
				case "genre":
				case "laststarted":
				case "lmod":
				case "mime":
				case "size":
				case "status":
				case "timesplayed":
				case "tracknr":
					return false;
				default:
					return true;
			}
		}


		private void set_dynamic_columns (string[] props)
		{
			var columns = get_columns ();
			while (columns.get_n_items () > 0)
				remove_column ((Gtk.ColumnViewColumn) columns.get_item (0));

			filter_model = new FilterModel(client, resolver, props);
			use_model (filter_model.store, true);

			int index = 0;
			foreach (var key in props)
				add_column (index++, key);

			if (collection != null)
				query_collection(collection);
		}


		private void add_column (int index, string key)
		{
			var factory = new Gtk.SignalListItemFactory ();
			factory.setup.connect (li => {
				var label = new Gtk.Label (null) {
					xalign = 0,
					ellipsize = Pango.EllipsizeMode.END
				};
				((Gtk.ListItem) li).set_child (label);
				attach_drag_source (label);
			});
			factory.bind.connect (li => {
				var item = (FilterItem) ((Gtk.ListItem) li).get_item ();
				var label = (Gtk.Label) ((Gtk.ListItem) li).get_child ();
				filter_model.ensure_resolved (item);
				label.label = item.get_column (index);
				var handler = item.updated.connect (() => {
					label.label = item.get_column (index);
				});
				((Gtk.ListItem) li).set_data<ulong> ("handler", handler);
			});
			factory.unbind.connect (li => {
				var item = (FilterItem) ((Gtk.ListItem) li).get_item ();
				var handler = ((Gtk.ListItem) li).get_data<ulong> ("handler");
				if (handler != 0)
					item.disconnect (handler);
			});

			var column = new Gtk.ColumnViewColumn (key, factory);
			column.resizable = true;
			column.expand = should_expand (key);
			column.set_header_menu (build_header_menu (key));
			append_column (column);
		}


		private void attach_drag_source (Gtk.Widget widget)
		{
			var source = new Gtk.DragSource ();
			source.set_actions (Gdk.DragAction.MOVE);
			source.prepare.connect ((x, y) => {
				if (count_selected () == 0)
					return null;
				var list = new Xmms.Collection (Xmms.CollectionType.IDLIST);
				foreach_selected ((pos, obj) => {
					list.idlist_append ((int) ((FilterItem) obj).id);
				});
				return DragDropUtil.content_for_collection (list);
			});
			widget.add_controller (source);
		}


		private void create_actions ()
		{
			actions = new GLib.SimpleActionGroup ();

			add_simple ("select-all", () => { select_all_rows (); });
			add_simple ("info", () => {
				foreach_selected ((pos, obj) => {
					medialib.info_dialog_add_id (((FilterItem) obj).id);
				});
			});
			add_simple ("add", add_selected);
			add_simple ("replace", () => {
				client.xmms.playlist_clear (Xmms.ACTIVE_PLAYLIST);
				add_selected ();
			});
			add_simple ("edit", on_header_edit);
			add_simple ("reset-sort", () => { sorting = Sorting (); });

			add_target ("sort-asc", f => { sorting = { f, Gtk.SortType.ASCENDING }; });
			add_target ("sort-desc", f => { sorting = { f, Gtk.SortType.DESCENDING }; });
			add_target ("remove", on_header_remove);

			insert_action_group ("fv", actions);
		}

		private void add_simple (string name, owned VoidFunc func)
		{
			var action = new GLib.SimpleAction (name, null);
			action.activate.connect (p => { func (); });
			actions.add_action (action);
		}

		private delegate void TargetFunc (string target);

		private void add_target (string name, owned TargetFunc func)
		{
			var action = new GLib.SimpleAction (name, GLib.VariantType.STRING);
			action.activate.connect (p => { func (p.get_string ()); });
			actions.add_action (action);
		}


		private GLib.MenuModel build_context_menu ()
		{
			var menu = new GLib.Menu ();
			menu.append (_("Select All"), "fv.select-all");

			var info = new GLib.Menu ();
			info.append (_("Info"), "fv.info");
			menu.append_section (null, info);

			var add = new GLib.Menu ();
			add.append (_("Add"), "fv.add");
			add.append (_("Replace"), "fv.replace");
			menu.append_section (null, add);

			return menu;
		}


		private GLib.MenuModel build_header_menu (string field)
		{
			var menu = new GLib.Menu ();

			var sort = new GLib.Menu ();
			append_target (sort, _("Sort Ascending"), "fv.sort-asc", field);
			append_target (sort, _("Sort Descending"), "fv.sort-desc", field);
			sort.append (_("Reset Sorting"), "fv.reset-sort");
			menu.append_section (null, sort);

			var cols = new GLib.Menu ();
			cols.append (_("Edit"), "fv.edit");
			append_target (cols, _("Remove"), "fv.remove", field);
			menu.append_section (null, cols);

			return menu;
		}

		private void append_target (GLib.Menu menu, string label, string action, string target)
		{
			var item = new GLib.MenuItem (label, null);
			item.set_action_and_target_value (action, new GLib.Variant.string (target));
			menu.append_item (item);
		}


		private void on_header_edit ()
		{
			var edit = new FilterEditor();

			edit.transient_for = get_ancestor (typeof(Gtk.Window)) as Gtk.Window;

			edit.column_changed.connect((editor, prop, enabled) => {
				var columns = filter_model.dynamic_columns;
				var i = 0;

				var modified = new string[columns.length + (enabled ? 1 : -1)];
				foreach (unowned string s in columns) {
					if (!enabled && s == prop)
						continue;
					modified[i++] = s;
				}

				if (enabled)
					modified[i] = prop;

				set_dynamic_columns(modified);
			});

			edit.set_active(filter_model.dynamic_columns);
			edit.present();
		}


		private void on_header_remove (string field)
		{
			var columns = get_columns ();
			if (columns.get_n_items () <= 1)
				return;

			var modified = new string[columns.get_n_items () - 1];
			var i = 0;

			for (uint c = 0; c < columns.get_n_items (); c++) {
				var title = ((Gtk.ColumnViewColumn) columns.get_item (c)).title;
				if (title != field)
					modified[i++] = title;
			}

			set_dynamic_columns(modified);
		}
	}
}
