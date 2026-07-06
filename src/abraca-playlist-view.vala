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
	public class PlaylistView : Abraca.SelectableView {
		/** current playlist sort order */
		private Xmms.Value sort;

		private PlaylistModel playlist_model;
		private Client client;
		private Config config;
		private Medialib medialib;
		private Searchable search;

		private GLib.SimpleActionGroup actions;

		public PlaylistView (PlaylistModel mdl, Client c,
		                     Medialib m, Config cfg, Searchable s)
		{
			playlist_model = mdl;
			client = c;
			config = cfg;
			medialib = m;
			search = s;

			column_view.show_row_separators = false;
			column_view.add_css_class ("no-header");

			use_model (mdl.store, true);

			create_columns ();
			create_actions ();
			install_context_menu (build_menu ());
			create_dragndrop ();

			column_view.activate.connect (on_activate);

			var key = new Gtk.EventControllerKey ();
			key.key_pressed.connect (on_key_pressed);
			column_view.add_controller (key);

			sort = new Xmms.Value.from_list();
			sort.list_append (new Xmms.Value.from_string("album"));
			sort.list_append (new Xmms.Value.from_string("tracknr"));
		}


		private void delete_selected()
		{
			var entries = new Gee.LinkedList<uint>();

			foreach_selected ((idx, item) => {
				entries.insert (0, idx);
			});

			foreach (var idx in entries) {
				client.xmms.playlist_remove_entry(Xmms.ACTIVE_PLAYLIST, idx);
			}
		}


		private bool on_key_pressed (uint keyval, uint keycode, Gdk.ModifierType state)
		{
			if (keyval != Gdk.Key.Delete && keyval != Gdk.Key.BackSpace)
				return false;
			delete_selected();
			return true;
		}


		/**
		 * Create the position-indicator and metadata columns.
		 */
		private void create_columns()
		{
			var indicator = new Gtk.SignalListItemFactory ();
			indicator.setup.connect (li => {
				((Gtk.ListItem) li).set_child (new Gtk.Image ());
			});
			indicator.bind.connect (li => {
				var item = (PlaylistItem) ((Gtk.ListItem) li).get_item ();
				var image = (Gtk.Image) ((Gtk.ListItem) li).get_child ();
				bind_prop (li, item.bind_property ("position-indicator", image, "icon-name", GLib.BindingFlags.SYNC_CREATE), 0);
				bind_prop (li, item.bind_property ("available", image, "sensitive", GLib.BindingFlags.SYNC_CREATE), 1);
			});
			indicator.unbind.connect (unbind_props);

			var indicator_column = new Gtk.ColumnViewColumn (null, indicator);
			indicator_column.fixed_width = 36;
			append_column (indicator_column);

			var info = new Gtk.SignalListItemFactory ();
			info.setup.connect (li => {
				var label = new Gtk.Label (null) {
					use_markup = true,
					xalign = 0,
					ellipsize = Pango.EllipsizeMode.END
				};
				((Gtk.ListItem) li).set_child (label);
				attach_drag_source (label);
			});
			info.bind.connect (li => {
				var item = (PlaylistItem) ((Gtk.ListItem) li).get_item ();
				var label = (Gtk.Label) ((Gtk.ListItem) li).get_child ();
				playlist_model.ensure_resolved (item);
				bind_prop (li, item.bind_property ("info", label, "label", GLib.BindingFlags.SYNC_CREATE), 0);
				bind_prop (li, item.bind_property ("available", label, "sensitive", GLib.BindingFlags.SYNC_CREATE), 1);
			});
			info.unbind.connect (unbind_props);

			var info_column = new Gtk.ColumnViewColumn (null, info);
			info_column.expand = true;
			append_column (info_column);
		}


		/* Store/clear property bindings on the list item so they can be undone
		 * when the row is recycled. */
		private void bind_prop (GLib.Object li, GLib.Binding binding, int slot)
		{
			((Gtk.ListItem) li).set_data ("binding-%d".printf (slot), binding);
		}

		private void unbind_props (GLib.Object li)
		{
			for (int slot = 0; slot < 2; slot++) {
				var binding = ((Gtk.ListItem) li).get_data<GLib.Binding> ("binding-%d".printf (slot));
				if (binding != null) {
					binding.unbind ();
					((Gtk.ListItem) li).set_data<GLib.Binding> ("binding-%d".printf (slot), null);
				}
			}
		}


		private void create_actions ()
		{
			actions = new GLib.SimpleActionGroup ();

			add_simple ("jump", () => { jump_to_selected (); });
			add_simple ("info", () => {
				foreach_selected ((pos, item) => {
					medialib.info_dialog_add_id (((PlaylistItem) item).id);
				});
			});
			add_simple ("delete", delete_selected);
			add_simple ("shuffle", () => {
				client.xmms.playlist_shuffle (Xmms.ACTIVE_PLAYLIST);
			});
			add_simple ("clear", () => {
				client.xmms.playlist_clear (Xmms.ACTIVE_PLAYLIST);
			});

			var filter = new GLib.SimpleAction ("filter", GLib.VariantType.STRING);
			filter.activate.connect (p => { on_menu_playlist_filter (p.get_string ()); });
			actions.add_action (filter);

			var sort_action = new GLib.SimpleAction ("sort", GLib.VariantType.STRING);
			sort_action.activate.connect (p => { on_menu_playlist_sort (p.get_string ()); });
			actions.add_action (sort_action);

			insert_action_group ("pl", actions);
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

			var first = new GLib.Menu ();
			first.append (_("Jump"), "pl.jump");
			menu.append_section (null, first);

			var mid = new GLib.Menu ();
			mid.append (_("Info"), "pl.info");

			var find = new GLib.Menu ();
			find.append (_("By Artist"), "pl.filter::artist");
			find.append (_("By Album"), "pl.filter::album");
			find.append (_("By Genre"), "pl.filter::genre");
			mid.append_submenu (_("Find"), find);

			mid.append (_("Delete"), "pl.delete");
			menu.append_section (null, mid);

			var sort_menu = new GLib.Menu ();
			append_sort (sort_menu, _("Artist"), config.sorting_artist);
			append_sort (sort_menu, _("Album"), config.sorting_album);
			append_sort (sort_menu, _("Title"), config.sorting_title);
			append_sort (sort_menu, _("Year"), config.sorting_year);
			append_sort (sort_menu, _("Path"), config.sorting_path);
			append_sort (sort_menu, _("Custom"), config.sorting_custom);

			var last = new GLib.Menu ();
			last.append_submenu (_("Sort"), sort_menu);
			last.append (_("Shuffle"), "pl.shuffle");
			last.append (_("Clear"), "pl.clear");
			menu.append_section (null, last);

			return menu;
		}

		private void append_sort (GLib.Menu menu, string label, string spec)
		{
			var item = new GLib.MenuItem (label, null);
			item.set_action_and_target_value ("pl.sort", new GLib.Variant.string (spec));
			menu.append_item (item);
		}


		protected override void before_context_menu ()
		{
			var n = count_selected ();
			((GLib.SimpleAction) actions.lookup_action ("jump")).set_enabled (n == 1);
			((GLib.SimpleAction) actions.lookup_action ("info")).set_enabled (n > 0);
			((GLib.SimpleAction) actions.lookup_action ("filter")).set_enabled (n > 0);
			((GLib.SimpleAction) actions.lookup_action ("delete")).set_enabled (n > 0);
		}


		private void on_menu_playlist_sort(string type)
		{
			sort = new Xmms.Value.from_list();

			foreach (string s in type.split(","))
				sort.list_append(new Xmms.Value.from_string(s));

			client.xmms.playlist_sort(Xmms.ACTIVE_PLAYLIST, sort);
		}


		private void on_menu_playlist_filter(string key)
		{
			var values = new Gee.HashSet<string>();

			foreach_selected ((pos, obj) => {
				var item = (PlaylistItem) obj;
				string text;
				if (key == "artist")
					text = item.artist;
				else if (key == "album")
					text = item.album;
				else
					text = item.genre;
				if (text != null && text != "Unknown")
					values.add(text.casefold());
			});

			var query = new GLib.StringBuilder();

			foreach (var val in values) {
				if (query.len > 0) {
					query.append(" OR ");
				}
				query.append(key);
				query.append(":\"");
				query.append(val);
				query.append("\"");
			}

			if (query.len > 0) {
				search.search(query.str);
			}
		}


		/**
		 * Setup dragndrop for the playlist.
		 */
		private void create_dragndrop()
		{
			var drop = new Gtk.DropTarget (typeof (GLib.Object),
			                               Gdk.DragAction.MOVE | Gdk.DragAction.COPY);
			drop.set_gtypes ({
				typeof (PlaylistEntriesTransfer),
				typeof (CollectionTransfer),
				typeof (Gdk.FileList)
			});
			drop.drop.connect (on_drop);
			column_view.add_controller (drop);
		}


		private void attach_drag_source (Gtk.Widget widget)
		{
			var source = new Gtk.DragSource ();
			source.set_actions (Gdk.DragAction.MOVE | Gdk.DragAction.COPY);
			source.prepare.connect (on_drag_prepare);
			widget.add_controller (source);
		}


		private Gdk.ContentProvider? on_drag_prepare (double x, double y)
		{
			if (count_selected () == 0)
				return null;

			var positions = new Xmms.Value.from_list ();
			var idlist = new Xmms.Collection (Xmms.CollectionType.IDLIST);

			foreach_selected ((pos, obj) => {
				positions.list_insert_int (0, (int) pos);
				idlist.idlist_append ((int) ((PlaylistItem) obj).id);
			});

			return new Gdk.ContentProvider.union ({
				DragDropUtil.content_for_playlist_entries (positions),
				DragDropUtil.content_for_collection (idlist)
			});
		}


		/**
		 * Take care of the various types of drops. `value` holds one of the
		 * accepted GTypes; the drop lands at the end of the playlist (a more
		 * precise per-row insertion point is a future refinement).
		 */
		private bool on_drop (GLib.Value value, double x, double y)
		{
			int dest = (int) playlist_model.store.get_n_items ();

			if (value.type ().is_a (typeof (PlaylistEntriesTransfer))) {
				var transfer = (PlaylistEntriesTransfer) value.get_object ();
				return move_entries (transfer.positions, dest);
			} else if (value.type ().is_a (typeof (CollectionTransfer))) {
				var transfer = (CollectionTransfer) value.get_object ();
				client.xmms.playlist_add_collection (Xmms.ACTIVE_PLAYLIST, transfer.collection, sort);
				return true;
			} else if (value.type ().is_a (typeof (Gdk.FileList))) {
				var files = (Gdk.FileList) value.get_boxed ();
				foreach (unowned GLib.File file in files.get_files ())
					client.xmms.playlist_add_url (Xmms.ACTIVE_PLAYLIST, file.get_uri ());
				return true;
			}

			return false;
		}


		private bool move_entries (Xmms.Value positions, int dest)
		{
			int downward = 0;
			int upward = 0;

			for (int i = positions.list_get_size () - 1; i >= 0; i--) {
				int position;
				positions.list_get_int (i, out position);
				if (position < dest) {
					client.xmms.playlist_move_entry (Xmms.ACTIVE_PLAYLIST, position - downward, (uint) dest - 1);
					downward++;
				} else {
					client.xmms.playlist_move_entry (Xmms.ACTIVE_PLAYLIST, position, (uint) dest + upward);
					upward++;
				}
			}

			return true;
		}


		/**
		 * Perform a jump to that song and start playback if not already
		 * playing.
		 */
		private void jump_to_pos(uint pos)
		{
			client.xmms.playlist_set_next((int) pos).notifier_set((res) => {
				client.xmms.playback_tickle().notifier_set((res) => {
					client.xmms.playback_status().notifier_set((res) => {
						int status;
						res.get_int(out status);
						if (status != Xmms.PlaybackStatus.PLAY) {
							client.xmms.playback_start();
						}
						return true;
					});
					return true;
				});
				return true;
			});
		}


		private void jump_to_selected ()
		{
			var bitset = selection.get_selection ();
			Gtk.BitsetIter iter = {};
			uint pos;
			if (iter.init_first (bitset, out pos))
				jump_to_pos (pos);
		}


		/**
		 * When activating a row, perform a jump to that song and start
		 * playback if not already playing.
		 */
		private void on_activate (uint position)
		{
			jump_to_pos (position);
		}
	}
}
