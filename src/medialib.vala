/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008  Abraca Team
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
	public class MedialibInfoDialog : Gtk.Dialog {
		private GLib.List<uint> ids;
		private weak GLib.List<uint> current;

		private string artist;
		private string album;
		private string title;
		private string genre;
		private string tracknr;
		private string date;
		private string rating;

		private Gtk.TreeView view;
		private Gtk.TreeStore store;

		private Gtk.Button prev_button;
		private Gtk.Button next_button;

		private Gtk.Entry artist_entry;
		private Gtk.Entry album_entry;
		private Gtk.Entry title_entry;

		private Gtk.SpinButton date_button;
		private Gtk.SpinButton tracknr_button;
		private RatingEntry rating_entry;
		private Gtk.ComboBox genre_combo_box_entry;

		private const string[] genres = { "Acid Jazz", "Acid Punk", "Acid",
			"Alternative Rock", "Alternative", "Ambient", "Bass", "Blues",
			"Cabaret", "Christian Rap", "Classic Rock", "Classical",
			"Comedy", "Country", "Cult", "Dance", "Darkwave", "Death Metal",
			"Disco", "Dream", "Electronic", "Ethnic", "Euro-Techno",
			"Eurodance", "Folk", "Funk", "Fusion", "Game", "Gangsta", "Gospel",
			"Gothic", "Grunge", "Hard Rock", "Hip-Hop", "House", "Industrial",
			"Instrumental Pop", "Instrumental Rock", "Instrumental", "Jazz",
			"Jazz&Funk", "Jungle", "Lo-Fi", "Meditative", "Metal", "Musical",
			"Native US", "New Age", "New Wave", "Noise", "Oldies", "Other",
			"Polka", "Pop", "Pop-Folk", "Pop/Funk", "Pranks", "Psychedelic",
			"Punk", "R&B", "Rap", "Rave", "Reggae", "Retro", "Rock & Roll",
			"Rock", "Showtunes", "Ska", "Soul", "Sound Clip", "Soundtrack",
			"Southern Rock", "Space", "Techno", "Techno-Industrial", "Top 40",
			"Trailer", "Trance", "Tribal", "Trip-Hop", "Vocal"};

		construct {
			Gtk.Widget overview, details;
			Gtk.Notebook notebook;

			set_title ("Info");
			ids = new GLib.List<uint>();
			delete_event += on_delete_event;

			set_default_size(310, 310);

			border_width = 5;
			transient_for = Abraca.instance().main_window;
			has_separator = false;
			resizable = false;

			create_buttons();

			overview = create_page_overview();
			details = create_page_details();

			notebook = new Gtk.Notebook();
			notebook.append_page(overview, new Gtk.Label("Overview"));
			notebook.append_page(details, new Gtk.Label("Details"));
			notebook.border_width = 6;

			vbox.pack_start(notebook, true, true, 0);

			show_all();
		}

		private void create_buttons() {
			Gtk.Button button;

			vbox.border_width = 0;
			action_area.border_width = 0;
			action_area.spacing = 0;

			vbox.set_child_packing(action_area, false, false, 0, Gtk.PackType.END);

			prev_button = new Gtk.Button.from_stock(Gtk.STOCK_GO_BACK);
			prev_button.clicked += on_prev_button_clicked;
			action_area.add(prev_button);
			action_area.set_child_secondary(prev_button, true);

			next_button = new Gtk.Button.from_stock(Gtk.STOCK_GO_FORWARD);
			next_button.clicked += on_next_button_clicked;
			action_area.add(next_button);
			action_area.set_child_secondary(next_button, true);

			button = new Gtk.Button.from_stock(Gtk.STOCK_OK);
			button.clicked += on_close_all_button_clicked;
			action_area.add(button);
		}

		private Gtk.Widget create_page_overview() {
			Gtk.Alignment align;
			Gtk.Table table;
			int row = 0;

			table = new Gtk.Table(7, 2, false);
			table.set_row_spacings(7);
			table.border_width = 10;

			Gtk.Label label;
			label = new Gtk.Label("Title:");
			label.xalign = 0;
			table.attach_defaults(label, 0, 1, row, row + 1);
			title_entry = new Gtk.Entry();
			title_entry.changed += on_title_entry_changed;
			title_entry.activate += on_title_entry_activated;
			table.attach_defaults(title_entry, 1, 2, row, row + 1);
			row++;

			label = new Gtk.Label("Artist:");
			label.xalign = 0;
			table.attach_defaults(label, 0, 1, row, row + 1);
			artist_entry = new Gtk.Entry();
			artist_entry.changed += on_artist_entry_changed;
			artist_entry.activate += on_artist_entry_activated;
			table.attach_defaults(artist_entry, 1, 2, row, row + 1);
			row++;

			label = new Gtk.Label("Album:");
			label.xalign = 0;
			table.attach_defaults(label, 0, 1, row, row + 1);
			album_entry = new Gtk.Entry();
			album_entry.changed += on_album_entry_changed;
			album_entry.activate += on_album_entry_activated;
			table.attach_defaults(album_entry, 1, 2, row, row + 1);
			row++;

			label = new Gtk.Label("Track number:");
			label.xalign = 0;
			table.attach_defaults(label, 0, 1, row, row + 1);
			tracknr_button = new Gtk.SpinButton.with_range(0, 9999, 1);
			tracknr_button.changed += on_tracknr_button_changed;
			tracknr_button.activate += on_tracknr_button_activated;
			table.attach_defaults(tracknr_button, 1, 2, row, row + 1);
			row++;

			label = new Gtk.Label("Year:");
			label.xalign = 0;
			table.attach_defaults(label, 0, 1, row, row + 1);
			date_button = new Gtk.SpinButton.with_range(0, 9999, 1);
			date_button.changed += on_date_button_changed;
			date_button.activate += on_date_button_activated;
			table.attach_defaults(date_button, 1, 2, row, row + 1);
			row++;

			label = new Gtk.Label("Genre:");
			label.xalign = 0;
			table.attach_defaults(label, 0, 1, row, row + 1);
			genre_combo_box_entry = new Gtk.ComboBoxEntry.text();
			genre_combo_box_entry.changed += on_genre_combo_box_entry_changed;
			Gtk.Entry entry = (Gtk.Entry) genre_combo_box_entry.get_child();
			entry.activate += on_genre_box_button_activated;
			foreach(weak string genre in genres) {
				genre_combo_box_entry.append_text(genre);
			}
			align = new Gtk.Alignment(0, (float) 0.5, (float) 1.0, 0);
			align.add(genre_combo_box_entry);
			table.attach_defaults(align, 1, 2, row, row + 1);
			row++;

			label = new Gtk.Label("Rating:");
			label.xalign = 0;
			table.attach_defaults(label, 0, 1, row, row + 1);
			rating_entry = new RatingEntry();
			rating_entry.changed += on_rating_entry_changed;
			table.attach_defaults(rating_entry, 1, 2, row, row + 1);
			row++;

			return table;
		}


		private Gtk.Widget create_page_details() {
			Gtk.ScrolledWindow scrolled;
			Gtk.CellRendererText renderer;
			
			scrolled = new Gtk.ScrolledWindow(null, null);
			scrolled.set_policy(Gtk.PolicyType.NEVER,
			                    Gtk.PolicyType.AUTOMATIC);

			store = new Gtk.TreeStore(2, typeof(string), typeof(string));
			view = new Gtk.TreeView.with_model(store);
			view.headers_visible = false;
			view.tooltip_column = 1;


			view.insert_column_with_attributes(
				-1, null, new Gtk.CellRendererText(),
				"text", 0
			);

			renderer = new Gtk.CellRendererText();
			renderer.ellipsize = Pango.EllipsizeMode.END;
			renderer.ellipsize_set = true;

			view.insert_column_with_attributes(
				-1, null, renderer,
				"text", 1
			);

			scrolled.add_with_viewport(view);
			scrolled.border_width = 10;

			return scrolled;
		}


		bool on_delete_event(MedialibInfoDialog dialog) {
			Abraca abraca = Abraca.instance();
			abraca.medialib.info_dialog = null;

			return false;
		}

		void change_color(Gtk.Entry editable, string origin) {
			Gdk.Color? color = null;

			if (origin != editable.get_text()) {
				if (!Gdk.Color.parse("#ffff66", out color)) {
					color = null;
				}
			}

			editable.modify_base(Gtk.StateType.NORMAL, color);
			editable.set_tooltip_text(editable.get_text());
		}

		void on_title_entry_changed(Gtk.Entry entry) {
			change_color(entry, title);
		}

		void on_artist_entry_changed(Gtk.Entry entry) {
			change_color(entry, artist);
		}

		void on_album_entry_changed(Gtk.Entry entry) {
			change_color(entry, album);
		}

		void on_tracknr_button_changed(Gtk.SpinButton entry) {
			change_color(entry, tracknr);
		}

		void on_date_button_changed(Gtk.SpinButton entry) {
			change_color(entry, date);
		}

		void on_genre_combo_box_entry_changed(Gtk.ComboBox editable) {
			Gtk.Widget widget = genre_combo_box_entry.get_child();
			change_color((Gtk.Entry) widget, genre);
		}

		private void set_str(Gtk.Editable editable, string key) {
			Client c = Client.instance();
			weak string val = editable.get_chars(0, -1);

			c.xmms.medialib_entry_property_set_str(
				current.data, key, val
			).notifier_set(on_value_wrote);
		}

		private void set_int(Gtk.SpinButton editable, string key) {
			Client c = Client.instance();
			int val = editable.get_value_as_int();

			c.xmms.medialib_entry_property_set_int(
				current.data, key, val
			).notifier_set( on_value_wrote);
		}

		void on_title_entry_activated(Gtk.Entry entry) {
			set_str(entry, "title");
		}

		void on_artist_entry_activated(Gtk.Entry entry) {
			set_str(entry, "artist");
		}

		void on_album_entry_activated(Gtk.Entry entry) {
			set_str(entry, "album");
		}

		void on_tracknr_button_activated(Gtk.SpinButton entry) {
			set_int(entry, "tracknr");
		}

		void on_date_button_activated(Gtk.SpinButton entry) {
			set_str(entry, "date");
		}

		void on_genre_box_button_activated(Gtk.Entry entry) {
			set_str(entry, "genre");
		}

		void on_rating_entry_changed(RatingEntry entry) {
			Client c = Client.instance();
			if (entry.rating <= 0) {
				c.xmms.medialib_entry_property_remove_with_source(
					current.data, "client/generic", "rating"
				).notifier_set(on_value_wrote);
			} else {
				c.xmms.medialib_entry_property_set_int_with_source(
					current.data, "client/generic", "rating", entry.rating
				).notifier_set(on_value_wrote);
			}
		}

		private bool on_value_wrote(Xmms.Value val) {
			refresh_content();
			return true;
		}

		private void on_prev_button_clicked(Gtk.Button btn) {
			if (current.prev != null) {
				current = current.prev;
				refresh();
			}
		}

		private void on_next_button_clicked(Gtk.Button btn) {
			if (current.next != null) {
				current = current.next;
				refresh();
			}
		}

		private void on_close_all_button_clicked(Gtk.Button btn) {
			close();
		}

		private bool on_medialib_get_info(Xmms.Value val) {
			show_overview(val);
			store.clear();
			val.dict_foreach(dict_foreach);
			return true;
		}

		private void refresh_border() {
			string info = "Metadata for song %d of %d".printf(
				ids.position(current) + 1, (int) ids.length()
			);

			set_title (info);

			next_button.sensitive = (current.next != null);
			prev_button.sensitive = (current.prev != null);
		}

		private void refresh_content() {
			Client c = Client.instance();

			c.xmms.medialib_get_info(
				current.data
			).notifier_set(on_medialib_get_info);
		}

		private void refresh() {
			refresh_content();
			refresh_border();
		}

		public void add(uint id) {
			ids.append(id);
			if (current == null) {
				current = ids;
				refresh_content();
			}
			refresh_border();
		}

		private void show_overview(Xmms.Value propdict) {
			Xmms.Value val = propdict.propdict_to_dict();
			string tmp;
			int itmp;
			if (!val.dict_entry_get_string("artist", out tmp)) {
				tmp = "";
			}
			artist = tmp;
			artist_entry.text = tmp;
			artist_entry.modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_string("album", out tmp)) {
				tmp = "";
			}
			album = tmp;
			album_entry.text = tmp;
			album_entry.modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_string("title", out tmp)) {
				tmp = "";
			}
			title = tmp;
			title_entry.text = tmp;
			title_entry.modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_int("tracknr", out itmp)) {
				itmp = 0;
			}
			tracknr = itmp.to_string("%i");
			tracknr_button.set_value(itmp);
			tracknr_button.modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_string("date", out tmp)) {
				itmp = 0;
			} else {
				itmp = tmp.to_int();
			}
			date = tmp;
			date_button.set_value(itmp);
			date_button.modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_string("genre", out tmp)) {
				tmp = "";
			}
			genre = tmp;
			((Gtk.Entry) (genre_combo_box_entry.get_child())).text = tmp;
			((Gtk.Entry) (genre_combo_box_entry.get_child())).modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_int("rating", out itmp)) {
				itmp = 0;
			}
			rating = itmp.to_string("%i");
			rating_entry.rating = itmp;
		}

		/* TODO: refactor me */
		private void dict_foreach(string key, Xmms.Value val) {
			string? val_str, parent_source = null;
			Gtk.TreeIter parent, iter;

			weak Xmms.DictIter dict_iter;
			val.get_dict_iter(out dict_iter);

			for (dict_iter.first(); dict_iter.valid(); dict_iter.next()) {
				Xmms.Value entry;
				weak string source;

				if (!dict_iter.pair(out source, out entry)) {
					continue;
				}

				/* looking for parent iter */
				if (store.iter_children(out parent, null)) {
					do {
						store.get(parent, 0, out parent_source);
						if (source == parent_source)
							break;
					} while (store.iter_next(ref parent)) ;
				}

				if (source != parent_source) {
					store.append(out parent, null);
					store.set(parent, 0, source);
				}

				val_str = "%s".printf("Unknown");

				switch (entry.get_type()) {
				    case Xmms.ValueType.INT32: {
						int tmp;
						if (entry.get_int(out tmp)) {
							val_str= "%d".printf(tmp);
						}
						break;
					}
				    case Xmms.ValueType.STRING: {
						string tmp;
						if (entry.get_string(out tmp)) {
							val_str  = "%s".printf(tmp);
						}
						break;
					}
				    default: {
						return;
					}
				}

				store.append(out iter, parent);
				store.set(iter, 0, (string) key, 1, val_str);
			}
		}
	}


	public class MedialibAddUrlDialog : Gtk.Dialog, IConfigurable {
		public Gtk.Entry entry;
		private Gtk.ListStore urls;

		construct {
			set_default_response(Gtk.ResponseType.OK);
			set_default_size(300, 74);

			destroy_with_parent = true;
			modal = true;
			title = _("Add URL");
			transient_for = (Abraca.instance().main_window);
			urls = new Gtk.ListStore(1, typeof(string));

			add_button(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL);
			add_button(Gtk.STOCK_OK, Gtk.ResponseType.OK);

			Gtk.ComboBoxEntry combo = new Gtk.ComboBoxEntry.with_model(urls, 0);
			Gtk.EntryCompletion comp = new Gtk.EntryCompletion();

			comp.model = urls;
			comp.set_text_column(0);
			entry = (Gtk.Entry) combo.child;
			entry.set_completion(comp);
			entry.activates_default = true;
			vbox.pack_start_defaults(combo);

			close += on_close;
			response += on_response;

			Configurable.register(this);
			show_all();
		}

		private void save_url(string url) {
			Gtk.TreeIter iter;
			string current;

			if (urls.iter_children(out iter, null)) {
				do {
					urls.get(iter, 0, out current);
					if (current == url) {
						urls.remove(iter);
						break;
					}
				} while (urls.iter_next(ref iter));
			}
			urls.insert_with_values(out iter, 0, 0, url);
		}

		private void on_close(MedialibAddUrlDialog dialog) {
			Configurable.unregister(this);
		}

		private void on_response(MedialibAddUrlDialog dialog, int response) {
			if(response == Gtk.ResponseType.OK && entry.get_text() != "") {
				save_url(entry.get_text());
			}
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			if (file.has_group("add_dialog")) {
				if (file.has_key("add_dialog", "urls")) {
					string[] list = file.get_string_list("add_dialog", "urls");
					Gtk.TreeIter iter;

					urls.clear();
					for (int i = 0; i < list.length; i++) {
						urls.insert_with_values(out iter, i, 0, list[i]);
					}
				}
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			Gtk.TreeIter iter;
			string current;
			string[] list = new string[25];
			int i = 0;

			if (urls.iter_children(out iter, null)) {
				do {
					urls.get(iter, 0, out current);
					list[i++] = current;
				} while (urls.iter_next(ref iter) && i < 25);
			}

			file.set_string_list("add_dialog", "urls", list);
		}
	}

	public class MedialibFileChooserDialog : Gtk.FileChooserDialog, IConfigurable {
		private string current_folder;

		construct {
			Gtk.CheckButton button = new Gtk.CheckButton.with_label(
					_("don't add to active playlist"));

			extra_widget = button;
			modal = true;
			select_multiple = true;
			title = _("Add File");
			transient_for = Abraca.instance().main_window;

			add_button(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL);
			add_button(Gtk.STOCK_OPEN, Gtk.ResponseType.OK);

			close += on_close;
			response += on_response;

			Configurable.register(this);
			show_all();
		}

		private void on_close(MedialibFileChooserDialog dialog) {
			Configurable.unregister(this);
		}

		private void on_response(MedialibFileChooserDialog dialog, int response) {
			if(response == Gtk.ResponseType.OK) {
				current_folder = get_current_folder();
			}
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			if (file.has_group("add_dialog")) {
				if (file.has_key("add_dialog", "file")) {
					current_folder = file.get_string("add_dialog", "file");
					set_current_folder(current_folder);
				}
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			if(current_folder != null) {
				file.set_string("add_dialog", "file", current_folder);
			}
		}
	}

	public class Medialib : GLib.Object {
		public MedialibInfoDialog info_dialog;

		public void info_dialog_add_id(uint mid) {
			if (info_dialog == null) {
				info_dialog = new MedialibInfoDialog();
			}
			info_dialog.add(mid);
		}

		public void create_add_url_dialog() {
			MedialibAddUrlDialog dialog = new MedialibAddUrlDialog();

			if (dialog.run() == Gtk.ResponseType.OK) {
				Client c = Client.instance();

				c.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, dialog.entry.get_text());
			}
			dialog.close();
		}

		public void create_add_file_dialog(Gtk.FileChooserAction action) {
			MedialibFileChooserDialog dialog = new MedialibFileChooserDialog();
			dialog.set_action(action);

			if (dialog.run() == Gtk.ResponseType.OK) {
				Client c = Client.instance();
				weak GLib.SList<string> filenames;
				string url;
				Gtk.CheckButton button = (Gtk.CheckButton) dialog.extra_widget;

				filenames = dialog.get_filenames();

				foreach(string filename in filenames) {
					url = "file://" + filename;

					if (action == Gtk.FileChooserAction.OPEN) {
						if (button.get_active()) {
							c.xmms.medialib_add_entry(url);
						} else {
							c.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, url);
						}
					} else {
						if (button.get_active()) {
							c.xmms.medialib_path_import(url);
						} else {
							c.xmms.playlist_radd(Xmms.ACTIVE_PLAYLIST, url);
						}
					}
				}
			}
			dialog.close();
		}
	}
}
