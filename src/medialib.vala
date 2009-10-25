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
	public class MedialibInfoDialog : Gtk.Dialog, Gtk.Buildable {
		private GLib.List<uint> ids;
		private unowned GLib.List<uint> current;

		private string artist;
		private string album;
		private string song;
		private string genre;
		private string tracknr;
		private string date;
		private string rating;

		private Gtk.TreeStore store;

		private Gtk.Button prev_button;
		private Gtk.Button next_button;

		private Gtk.Entry artist_entry;
		private Gtk.Entry album_entry;
		private Gtk.Entry song_entry;
		private Gtk.Entry date_entry;

		private RatingEntry rating_entry;
		private Gtk.SpinButton tracknr_button;
		private Gtk.ComboBoxEntry genre_combo_box_entry;

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

		public static MedialibInfoDialog build() {
			var builder = new Gtk.Builder ();

			try {
				builder.add_from_string(
					Resources.XML.mediainfo, Resources.XML.mediainfo.length
				);
			} catch (GLib.Error e) {
				GLib.error(e.message);
			}

			var instance = builder.get_object("mediainfo_dialog") as MedialibInfoDialog;
			instance.transient_for = Abraca.instance().main_window;

			return instance;
		}

		construct {
			ids = new GLib.List<uint>();
		}

		public void parser_finished (Gtk.Builder builder) {
			genre_combo_box_entry = builder.get_object("ent_genre") as Gtk.ComboBoxEntry;

			foreach (var genre in genres) {
				genre_combo_box_entry.append_text(genre);
			}

			// TODO: text-column property is not loaded by Gtk.Builder
			//       due to a bug in GTK, remove this when bug has
			//       been resolved and released.
			genre_combo_box_entry.text_column = 0;

			store = builder.get_object("details_model") as Gtk.TreeStore;

			tracknr_button = builder.get_object("ent_tracknr") as Gtk.SpinButton;
			date_entry = builder.get_object("ent_year") as Gtk.Entry;
			song_entry = builder.get_object("ent_title") as Gtk.Entry;
			album_entry = builder.get_object("ent_album") as Gtk.Entry;
			artist_entry = builder.get_object("ent_artist") as Gtk.Entry;
			rating_entry = builder.get_object("ent_rating") as RatingEntry;

			next_button = builder.get_object("button_forward") as Gtk.Button;
			prev_button = builder.get_object("button_prev") as Gtk.Button;

			builder.connect_signals(this);
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

		[CCode (instance_pos = -1)]
		public void on_song_entry_changed (Gtk.Entry entry) {
			change_color(entry, song);
		}

		[CCode (instance_pos = -1)]
		public void on_artist_entry_changed (Gtk.Entry entry) {
			change_color(entry, artist);
		}

		[CCode (instance_pos = -1)]
		public void on_album_entry_changed (Gtk.Entry entry) {
			change_color(entry, album);
		}

		[CCode (instance_pos = -1)]
		public void on_tracknr_button_changed (Gtk.SpinButton entry) {
			change_color(entry, tracknr);
		}

		[CCode (instance_pos = -1)]
		public void on_date_entry_changed (Gtk.Entry entry) {
			change_color(entry, date);
		}

		[CCode (instance_pos = -1)]
		public void on_genre_combo_box_entry_changed (Gtk.ComboBox editable) {
			var widget = genre_combo_box_entry.get_child() as Gtk.Entry;
			change_color(widget, genre);
		}

		private void set_str(Gtk.Editable editable, string key) {
			Client c = Client.instance();
			unowned string val = editable.get_chars(0, -1);

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

		[CCode (instance_pos = -1)]
		public void on_song_entry_activated (Gtk.Entry entry) {
			set_str(entry, "title");
		}

		[CCode (instance_pos = -1)]
		public void on_artist_entry_activated (Gtk.Entry entry) {
			set_str(entry, "artist");
		}

		[CCode (instance_pos = -1)]
		public void on_album_entry_activated (Gtk.Entry entry) {
			set_str(entry, "album");
		}

		[CCode (instance_pos = -1)]
		public void on_tracknr_button_activated (Gtk.SpinButton entry) {
			set_int(entry, "tracknr");
		}

		[CCode (instance_pos = -1)]
		public void on_date_entry_activated(Gtk.Entry entry) {
			set_str(entry, "date");
		}

		[CCode (instance_pos = -1)]
		public void on_genre_box_button_activated (Gtk.Entry entry) {
			set_str(entry, "genre");
		}

		[CCode (instance_pos = -1)]
		public void on_rating_entry_changed (RatingEntry entry) {
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

		[CCode (instance_pos = -1)]
		public void on_prev_button_clicked (Gtk.Button btn) {
			if (current.prev != null) {
				current = current.prev;
				refresh();
			}
		}

		[CCode (instance_pos = -1)]
		public  void on_next_button_clicked (Gtk.Button btn) {
			if (current.next != null) {
				current = current.next;
				refresh();
			}
		}

		[CCode (instance_pos = -1)]
		public void on_close_all_button_clicked (Gtk.Button btn) {
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

		public void add_mid(uint id) {
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
			song = tmp;
			song_entry.text = tmp;
			song_entry.modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_int("tracknr", out itmp)) {
				itmp = 0;
			}
			tracknr = itmp.to_string("%i");
			tracknr_button.set_value(itmp);
			tracknr_button.modify_base(Gtk.StateType.NORMAL, null);

			if (!val.dict_entry_get_string("date", out tmp)) {
				tmp = "";
			}
			date = tmp;
			date_entry.text = tmp;
			date_entry.modify_base(Gtk.StateType.NORMAL, null);

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

			unowned Xmms.DictIter dict_iter;
			val.get_dict_iter(out dict_iter);

			for (dict_iter.first(); dict_iter.valid(); dict_iter.next()) {
				Xmms.Value entry;
				unowned string source;

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

				Transform.normalize_value (entry, key, out val_str);

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
			vbox.pack_start(combo, true, true, 0);

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
				info_dialog = MedialibInfoDialog.build();
				info_dialog.delete_event += (ev) => {
					info_dialog = null;
					return false;
				};
				info_dialog.show_all();
			}
			info_dialog.add_mid(mid);
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
				GLib.SList<string> filenames;
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
