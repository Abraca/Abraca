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

	public class CollectionsView : Abraca.SelectableView {
		private CollectionsModel store;
		private Client client;
		private Searchable search;

		private GLib.SimpleActionGroup actions;

		public CollectionsView (Client c, Searchable s)
		{
			client = c;
			search = s;

			column_view.add_css_class ("no-header");

			store = new CollectionsModel (client);
			use_model (store.tree_model, false);

			create_column ();
			create_actions ();
			install_context_menu (build_menu ());

			column_view.activate.connect (on_activate);

			var key = new Gtk.EventControllerKey ();
			key.key_pressed.connect (on_key_pressed);
			column_view.add_controller (key);
		}


		private CollectionNode? selected_node ()
		{
			var row = first_selected () as Gtk.TreeListRow;
			return (row != null) ? row.get_item () as CollectionNode : null;
		}


		private static string node_markup (CollectionNode node)
		{
			var name = GLib.Markup.escape_text (node.name);
			if (node.is_root)
				return "<b>%s</b>".printf (name);
			if (node.is_current)
				return "<i><b>%s</b></i>".printf (name);
			return name;
		}


		private void create_column ()
		{
			var factory = new Gtk.SignalListItemFactory ();

			factory.setup.connect (li => {
				var expander = new Gtk.TreeExpander ();
				var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
				var image = new Gtk.Image ();
				var label = new Gtk.Label (null) { xalign = 0, use_markup = true };
				box.append (image);
				box.append (label);
				expander.set_child (box);
				((Gtk.ListItem) li).set_child (expander);

				attach_drag_source (expander);
				attach_drop_target (expander);
			});

			factory.bind.connect (li => {
				var row = (Gtk.TreeListRow) ((Gtk.ListItem) li).get_item ();
				var node = (CollectionNode) row.get_item ();
				var expander = (Gtk.TreeExpander) ((Gtk.ListItem) li).get_child ();
				var box = (Gtk.Box) expander.get_child ();
				var image = (Gtk.Image) box.get_first_child ();
				var label = (Gtk.Label) image.get_next_sibling ();

				expander.set_list_row (row);
				expander.set_data<CollectionNode> ("node", node);

				if (node.is_root) {
					image.visible = false;
				} else {
					image.visible = true;
					image.set_from_paintable (Icons.texture_by_name (
						node.node_type == CollectionsModel.CollectionType.Playlist
							? "abraca-playlist" : "abraca-collection"));
				}

				label.set_markup (node_markup (node));

				var handler = node.notify.connect (() => {
					label.set_markup (node_markup (node));
				});
				((Gtk.ListItem) li).set_data<ulong> ("handler", handler);
				((Gtk.ListItem) li).set_data<CollectionNode> ("node", node);
			});

			factory.unbind.connect (li => {
				var node = ((Gtk.ListItem) li).get_data<CollectionNode> ("node");
				var handler = ((Gtk.ListItem) li).get_data<ulong> ("handler");
				if (node != null && handler != 0)
					node.disconnect (handler);
			});

			var column = new Gtk.ColumnViewColumn (null, factory);
			column.expand = true;
			append_column (column);
		}


		private void attach_drag_source (Gtk.Widget widget)
		{
			var source = new Gtk.DragSource ();
			source.set_actions (Gdk.DragAction.COPY);
			source.prepare.connect ((x, y) => {
				var node = widget.get_data<CollectionNode> ("node");
				if (node == null || node.is_root)
					return null;

				unowned string ns = (node.node_type == CollectionsModel.CollectionType.Playlist)
					? Xmms.COLLECTION_NS_PLAYLISTS : Xmms.COLLECTION_NS_COLLECTIONS;

				var reference = new Xmms.Collection (Xmms.CollectionType.REFERENCE);
				reference.attribute_set ("reference", node.name);
				reference.attribute_set ("namespace", ns);

				return DragDropUtil.content_for_collection (reference);
			});
			widget.add_controller (source);
		}


		private void attach_drop_target (Gtk.Widget widget)
		{
			var drop = new Gtk.DropTarget (typeof (CollectionTransfer), Gdk.DragAction.COPY);
			drop.drop.connect ((value, x, y) => {
				var node = widget.get_data<CollectionNode> ("node");
				var transfer = value.get_object () as CollectionTransfer;
				if (node == null || transfer == null)
					return false;

				string name;
				if (node.node_type != CollectionsModel.CollectionType.Playlist)
					return false;

				if (node.is_root)
					name = store.realize_temporary_playlist ();
				else
					name = node.name;

				var sort = new Xmms.Value.from_list ();
				sort.list_append (new Xmms.Value.from_string ("album"));
				sort.list_append (new Xmms.Value.from_string ("tracknr"));

				client.xmms.playlist_add_collection (name, transfer.collection, sort);
				return true;
			});
			widget.add_controller (drop);
		}


		private bool on_key_pressed (uint keyval, uint keycode, Gdk.ModifierType state)
		{
			if (keyval == Gdk.Key.F2) {
				var node = selected_node ();
				if (node != null && !node.is_root)
					rename_node (node);
				return true;
			}

			if (keyval == Gdk.Key.Delete) {
				delete_selected ();
				return true;
			}

			return false;
		}


		private void on_activate (uint position)
		{
			var row = selection.get_item (position) as Gtk.TreeListRow;
			if (row == null)
				return;

			var node = (CollectionNode) row.get_item ();
			if (node.is_root)
				return;

			if (node.node_type == CollectionsModel.CollectionType.Collection) {
				var name = node.name;
				if (Client.collection_needs_quoting (name))
					name = "\"" + name + "\"";
				search.search ("in:" + name);
			} else {
				client.xmms.playlist_load (node.name);
			}
		}


		private void rename_node (CollectionNode node)
		{
			var dialog = new Adw.AlertDialog (_("Rename"), null);

			var entry = new Gtk.Entry () { text = node.name };
			dialog.set_extra_child (entry);

			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("rename", _("Rename"));
			dialog.set_response_appearance ("rename", Adw.ResponseAppearance.SUGGESTED);
			dialog.set_default_response ("rename");

			dialog.response.connect ((resp) => {
				if (resp == "rename" && entry.text != node.name) {
					unowned string ns = (node.node_type == CollectionsModel.CollectionType.Playlist)
						? Xmms.COLLECTION_NS_PLAYLISTS : Xmms.COLLECTION_NS_COLLECTIONS;
					client.xmms.coll_rename (node.name, entry.text, ns);
				}
			});

			dialog.present (this);
		}


		private void delete_selected ()
		{
			var node = selected_node ();
			if (node == null || node.is_root)
				return;

			unowned string ns = (node.node_type == CollectionsModel.CollectionType.Playlist)
				? Xmms.COLLECTION_NS_PLAYLISTS : Xmms.COLLECTION_NS_COLLECTIONS;

			client.xmms.coll_remove (node.name, ns);
		}


		private void show_selected ()
		{
			var node = selected_node ();
			if (node == null || node.is_root)
				return;

			unowned string ns = (node.node_type == CollectionsModel.CollectionType.Collection)
				? Xmms.COLLECTION_NS_COLLECTIONS : Xmms.COLLECTION_NS_PLAYLISTS;

			var full_name = ns + "/" + node.name;
			if (Client.collection_needs_quoting (full_name))
				full_name = "\"" + full_name + "\"";

			search.search ("in:" + full_name);
		}


		private void create_actions ()
		{
			actions = new GLib.SimpleActionGroup ();

			add_simple ("show", show_selected);
			add_simple ("rename", () => {
				var node = selected_node ();
				if (node != null && !node.is_root)
					rename_node (node);
			});
			add_simple ("delete", delete_selected);

			insert_action_group ("cv", actions);
		}

		private void add_simple (string name, owned VoidFunc func)
		{
			var action = new GLib.SimpleAction (name, null);
			action.activate.connect (p => { func (); });
			actions.add_action (action);
		}


		private GLib.MenuModel build_menu ()
		{
			var menu = new GLib.Menu ();
			menu.append (_("Show"), "cv.show");
			menu.append (_("Rename"), "cv.rename");
			menu.append (_("Delete"), "cv.delete");
			return menu;
		}


		protected override void before_context_menu ()
		{
			var node = selected_node ();
			var enabled = node != null && !node.is_root;
			((GLib.SimpleAction) actions.lookup_action ("show")).set_enabled (enabled);
			((GLib.SimpleAction) actions.lookup_action ("rename")).set_enabled (enabled);
			((GLib.SimpleAction) actions.lookup_action ("delete")).set_enabled (enabled);
		}
	}
}
