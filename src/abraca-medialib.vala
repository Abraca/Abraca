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
	public class MedialibInfoDialog : Gtk.Window {
		/* A node in the raw-metadata details tree: a source header (with
		 * children) or a key/value leaf. */
		private class DetailNode : GLib.Object {
			public string key { get; construct; }
			public string val { get; construct; }
			public GLib.ListStore? children { get; construct; }
			public DetailNode (string key, string val, GLib.ListStore? children) {
				Object (key: key, val: val, children: children);
			}
		}

		private Client client;

		private GLib.List<uint> ids;
		private unowned GLib.List<uint> current;

		private int mid;
		private string artist;
		private string album;
		private string song;
		private string genre;
		private string tracknr;
		private string date;
		private string rating;

		private GLib.ListStore detail_roots;
		private Gtk.ColumnView details_view;

		private Gtk.Button prev_button;
		private Gtk.Button next_button;

		private Gtk.Entry artist_entry;
		private Gtk.Entry album_entry;
		private Gtk.Entry song_entry;
		private Gtk.Entry date_entry;
		private Gtk.Entry genre_entry;

		private RatingEntry rating_entry;
		private Gtk.SpinButton tracknr_button;
		private Gtk.Picture cover_picture;


		public MedialibInfoDialog (Client c)
		{
			client = c;
			ids = new GLib.List<uint>();

			title = _("Info");
			set_default_size (420, 420);

			var header = new Gtk.HeaderBar ();
			prev_button = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
				tooltip_text = _("Previous")
			};
			next_button = new Gtk.Button.from_icon_name ("go-next-symbolic") {
				tooltip_text = _("Next")
			};
			header.pack_start (prev_button);
			header.pack_start (next_button);
			set_titlebar (header);

			var notebook = new Gtk.Notebook ();

			var grid = new Gtk.Grid () {
				row_spacing = 7, column_spacing = 8
			};

			song_entry = new Gtk.Entry () { hexpand = true };
			artist_entry = new Gtk.Entry () { hexpand = true };
			album_entry = new Gtk.Entry () { hexpand = true };
			tracknr_button = new Gtk.SpinButton.with_range (0, 100, 1);
			date_entry = new Gtk.Entry () { hexpand = true };
			genre_entry = new Gtk.Entry () { hexpand = true };
			rating_entry = new RatingEntry ();

			add_row (grid, 0, _("Title:"), song_entry);
			add_row (grid, 1, _("Artist:"), artist_entry);
			add_row (grid, 2, _("Album:"), album_entry);
			add_row (grid, 3, _("Track:"), tracknr_button);
			add_row (grid, 4, _("Year:"), date_entry);
			add_row (grid, 5, _("Genre:"), genre_entry);
			add_row (grid, 6, _("Rating:"), rating_entry);
			grid.hexpand = true;

			cover_picture = new Gtk.Picture () {
				content_fit = Gtk.ContentFit.CONTAIN,
				can_shrink = true,
				width_request = 160,
				height_request = 160,
				valign = Gtk.Align.START
			};
			cover_picture.set_paintable (client.default_coverart_texture);

			var overview = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
				margin_top = 10, margin_bottom = 10, margin_start = 10, margin_end = 10
			};
			overview.append (cover_picture);
			overview.append (grid);

			notebook.append_page (overview, new Gtk.Label (_("Overview")));

			details_view = new Gtk.ColumnView (null);
			setup_details_view ();
			var scrolled = new Gtk.ScrolledWindow () {
				child = details_view,
				hscrollbar_policy = Gtk.PolicyType.NEVER,
				vexpand = true
			};
			notebook.append_page (scrolled, new Gtk.Label (_("Details")));

			set_child (notebook);

			connect_widgets ();
		}


		private void add_row (Gtk.Grid grid, int row, string label, Gtk.Widget widget)
		{
			grid.attach (new Gtk.Label (label) { xalign = 0 }, 0, row, 1, 1);
			grid.attach (widget, 1, row, 1, 1);
		}


		private void setup_details_view ()
		{
			detail_roots = new GLib.ListStore (typeof (DetailNode));

			var tree = new Gtk.TreeListModel (detail_roots, false, false, (item) => {
				return ((DetailNode) item).children;
			});
			details_view.set_model (new Gtk.NoSelection (tree));

			var key_factory = new Gtk.SignalListItemFactory ();
			key_factory.setup.connect (li => {
				var expander = new Gtk.TreeExpander ();
				expander.set_child (new Gtk.Label (null) { xalign = 0 });
				((Gtk.ListItem) li).set_child (expander);
			});
			key_factory.bind.connect (li => {
				var row = (Gtk.TreeListRow) ((Gtk.ListItem) li).get_item ();
				var node = (DetailNode) row.get_item ();
				var expander = (Gtk.TreeExpander) ((Gtk.ListItem) li).get_child ();
				expander.set_list_row (row);
				((Gtk.Label) expander.get_child ()).label = node.key;
			});
			details_view.append_column (new Gtk.ColumnViewColumn (_("Key"), key_factory) { expand = true });

			var val_factory = new Gtk.SignalListItemFactory ();
			val_factory.setup.connect (li => {
				((Gtk.ListItem) li).set_child (new Gtk.Label (null) { xalign = 0 });
			});
			val_factory.bind.connect (li => {
				var row = (Gtk.TreeListRow) ((Gtk.ListItem) li).get_item ();
				var node = (DetailNode) row.get_item ();
				((Gtk.Label) ((Gtk.ListItem) li).get_child ()).label = node.val;
			});
			details_view.append_column (new Gtk.ColumnViewColumn (_("Value"), val_factory) { expand = true });
		}


		/* GTK4 dropped GtkBuilder.connect_signals, so wire the widgets up here. */
		private void connect_widgets ()
		{
			song_entry.changed.connect (() => change_color (song_entry, song));
			song_entry.activate.connect (() => set_str (song_entry, "title"));

			artist_entry.changed.connect (() => change_color (artist_entry, artist));
			artist_entry.activate.connect (() => set_str (artist_entry, "artist"));

			album_entry.changed.connect (() => change_color (album_entry, album));
			album_entry.activate.connect (() => set_str (album_entry, "album"));

			date_entry.changed.connect (() => change_color (date_entry, date));
			date_entry.activate.connect (() => set_str (date_entry, "date"));

			tracknr_button.value_changed.connect (() => change_color (tracknr_button, tracknr));
			tracknr_button.activate.connect (() => set_int (tracknr_button, "tracknr"));

			genre_entry.changed.connect (() => change_color (genre_entry, genre));
			genre_entry.activate.connect (() => set_str (genre_entry, "genre"));

			rating_entry.changed.connect (on_rating_changed);

			prev_button.clicked.connect (() => {
				if (current.prev != null) {
					current = current.prev;
					refresh ();
				}
			});
			next_button.clicked.connect (() => {
				if (current.next != null) {
					current = current.next;
					refresh ();
				}
			});
		}


		private void change_color (Gtk.Editable editable, string origin)
		{
			var widget = editable as Gtk.Widget;

			if (origin != editable.get_text())
				widget.add_css_class ("modified");
			else
				widget.remove_css_class ("modified");

			widget.set_tooltip_text (editable.get_text());
		}


		private void set_str(Gtk.Editable editable, string key)
		{
			var val = editable.get_chars(0, -1);

			client.xmms.medialib_entry_property_set_str(
				current.data, key, val
			).notifier_set(on_value_wrote);
		}


		private void set_int(Gtk.SpinButton editable, string key)
		{
			int val = editable.get_value_as_int();

			client.xmms.medialib_entry_property_set_int(
				current.data, key, val
			).notifier_set( on_value_wrote);
		}


		private void on_rating_changed (RatingEntry entry)
		{
			if (entry.rating <= 0) {
				client.xmms.medialib_entry_property_remove_with_source(
					current.data, "client/generic", "rating"
				).notifier_set(on_value_wrote);
			} else {
				client.xmms.medialib_entry_property_set_int_with_source(
					current.data, "client/generic", "rating", entry.rating
				).notifier_set(on_value_wrote);
			}
		}


		private bool on_value_wrote (Xmms.Value val)
		{
			refresh_content();
			return true;
		}


		private bool on_medialib_get_info (Xmms.Value val)
		{
			if (val.is_error())
				return true;

			show_overview(val);
			detail_roots.remove_all();
			val.dict_foreach(dict_foreach);
			return true;
		}


		private void refresh_border ()
		{
			string info = _("Metadata for song %d of %d").printf(
				ids.position(current) + 1, (int) ids.length()
			);

			set_title (info);

			next_button.sensitive = (current.next != null);
			prev_button.sensitive = (current.prev != null);
		}


		private void refresh_content ()
		{
			client.xmms.medialib_get_info(
				current.data
			).notifier_set(on_medialib_get_info);
		}


		private void refresh ()
		{
			refresh_content();
			refresh_border();
		}


		public void add_mid (uint id)
		{
			ids.append(id);
			if (current == null) {
				current = ids;
				refresh_content();
			}
			refresh_border();
		}


		private void show_overview (Xmms.Value propdict)
		{
			Xmms.Value val = propdict.propdict_to_dict();
			string tmp;
			int itmp;
			int new_mid;

			val.dict_entry_get_int("id", out new_mid);
			var updated = (mid == new_mid);

			mid = new_mid;

			if (!val.dict_entry_get_string("artist", out tmp)) {
				tmp = "";
			}
			if (!updated || artist_entry.get_text() == tmp) {
				artist = tmp;
				artist_entry.text = tmp;
				artist_entry.remove_css_class("modified");
			}

			if (!val.dict_entry_get_string("album", out tmp)) {
				tmp = "";
			}
			if (!updated || album_entry.get_text() == tmp) {
				album = tmp;
				album_entry.text = tmp;
				album_entry.remove_css_class("modified");
			}

			if (!val.dict_entry_get_string("title", out tmp)) {
				tmp = "";
			}
			if (!updated || song_entry.get_text() == tmp) {
				song = tmp;
				song_entry.text = tmp;
				song_entry.remove_css_class("modified");
			}

			if (!val.dict_entry_get_int("tracknr", out itmp)) {
				itmp = 0;
			}

			tmp = itmp.to_string("%i");

			if (!updated || tracknr_button.get_text() == tmp) {
				tracknr = tmp;
				tracknr_button.set_value(itmp);
				tracknr_button.remove_css_class("modified");
			}

			if (!val.dict_entry_get_string("date", out tmp)) {
				tmp = "";
			}
			if (!updated || date_entry.get_text() == tmp) {
				date = tmp;
				date_entry.text = tmp;
				date_entry.remove_css_class("modified");
			}

			if (!val.dict_entry_get_string("genre", out tmp)) {
				tmp = "";
			}

			if (!updated || genre_entry.text == tmp) {
				genre = tmp;
				genre_entry.text = tmp;
				genre_entry.remove_css_class("modified");
			}

			if (!val.dict_entry_get_int("rating", out itmp)) {
				itmp = 0;
			}

			if (!updated || rating_entry.rating == itmp) {
				rating = itmp.to_string("%i");
				rating_entry.rating = itmp;
			}

			string picture_front;
			if (val.dict_entry_get_string("picture_front", out picture_front)) {
				client.fetch_coverart(picture_front, (paintable) => {
					cover_picture.set_paintable(paintable);
				});
			} else {
				cover_picture.set_paintable(client.default_coverart_texture);
			}
		}


		private DetailNode source_node (string source)
		{
			for (uint i = 0; i < detail_roots.get_n_items (); i++) {
				var node = (DetailNode) detail_roots.get_item (i);
				if (node.key == source)
					return node;
			}
			var node = new DetailNode (source, "", new GLib.ListStore (typeof (DetailNode)));
			detail_roots.append (node);
			return node;
		}

		private void dict_foreach (string key, Xmms.Value val)
		{
			string val_str;

			unowned Xmms.DictIter dict_iter;
			val.get_dict_iter(out dict_iter);

			for (dict_iter.first(); dict_iter.valid(); dict_iter.next()) {
				Xmms.Value entry;
				unowned string source;

				if (!dict_iter.pair(out source, out entry))
					continue;

				Transform.normalize_value (entry, key, out val_str);
				source_node (source).children.append (new DetailNode (key, val_str, null));
			}
		}
	}


	public class Medialib : GLib.Object {
		public MedialibInfoDialog info_dialog;

		private Client client;
		private Gtk.Window parent;


		public Medialib (Gtk.Window window, Client c)
		{
			client = c;
			parent = window;
		}


		public void info_dialog_add_id (uint mid)
		{
			if (info_dialog == null) {
				info_dialog = new MedialibInfoDialog(client);
				info_dialog.transient_for = parent;
				info_dialog.close_request.connect(() => {
					info_dialog = null;
					return false;
				});
				info_dialog.present();
			}
			info_dialog.add_mid(mid);
		}


		public static void create_add_url_dialog (Gtk.Window parent, Client client)
		{
			var dialog = new Adw.AlertDialog(_("Add URL"), null);

			var entry = new Gtk.Entry() { hexpand = true };
			dialog.set_extra_child(entry);

			dialog.add_response("cancel", _("Cancel"));
			dialog.add_response("add", _("Ok"));
			dialog.set_response_appearance("add", Adw.ResponseAppearance.SUGGESTED);
			dialog.set_default_response("add");

			dialog.response.connect((resp) => {
				if (resp == "add" && entry.text != "")
					client.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, entry.text);
			});

			dialog.present(parent);
		}


		public static void create_add_file_dialog (Gtk.Window parent, Client client, Gtk.FileChooserAction action)
		{
			var dialog = new Gtk.FileDialog();
			dialog.title = _("Add File");

			if (action == Gtk.FileChooserAction.SELECT_FOLDER) {
				dialog.select_folder.begin(parent, null, (obj, res) => {
					try {
						var folder = dialog.select_folder.end(res);
						client.xmms.playlist_radd(Xmms.ACTIVE_PLAYLIST, folder.get_uri());
					} catch (GLib.Error e) {
						/* cancelled */
					}
				});
			} else {
				dialog.open_multiple.begin(parent, null, (obj, res) => {
					try {
						var files = dialog.open_multiple.end(res);
						for (uint i = 0; i < files.get_n_items(); i++) {
							var file = files.get_item(i) as GLib.File;
							client.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, file.get_uri());
						}
					} catch (GLib.Error e) {
						/* cancelled */
					}
				});
			}
		}
	}
}
