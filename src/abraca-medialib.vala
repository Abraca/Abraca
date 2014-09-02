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
	public class MedialibInfoDialog : Gtk.Dialog, Gtk.Buildable {
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

		private Gtk.TreeStore store;

		private Gtk.Button prev_button;
		private Gtk.Button next_button;

		private Gtk.Entry artist_entry;
		private Gtk.Entry album_entry;
		private Gtk.Entry song_entry;
		private Gtk.Entry date_entry;

		private RatingEntry rating_entry;
		private Gtk.SpinButton tracknr_button;
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


		public static MedialibInfoDialog build ()
		{
			var builder = new Gtk.Builder ();

			try {
				builder.add_from_resource("/org/xmms2/Abraca/ui/abraca-mediainfo.ui");
			} catch (GLib.Error e) {
				GLib.error(_("Could not load UI: %s"), e.message);
			}

			var instance = builder.get_object("mediainfo_dialog") as MedialibInfoDialog;

			return instance;
		}


		public MedialibInfoDialog ()
		{
			ids = new GLib.List<uint>();
		}


		public void set_client (Client c)
		{
			client = c;
		}


		public void parser_finished (Gtk.Builder builder)
		{
			genre_combo_box_entry = builder.get_object("ent_genre") as Gtk.ComboBox;

			var genre_model = builder.get_object ("genre_model") as Gtk.ListStore;

			foreach (var genre in genres) {
				Gtk.TreeIter iter;
				genre_model.append (out iter);
				genre_model.set(iter, 0, genre);
			}

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


		private void change_color (Gtk.Entry editable, string origin)
		{
			Gdk.RGBA? color = null;

			if (origin != editable.get_text()) {
				color = Gdk.RGBA();
				color.parse("#ffff66");
			}

			editable.override_background_color(Gtk.StateFlags.NORMAL, color);
			editable.set_tooltip_text(editable.get_text());
		}


		[CCode (instance_pos = -1)]
		public void on_song_entry_changed (Gtk.Entry entry)
		{
			change_color(entry, song);
		}


		[CCode (instance_pos = -1)]
		public void on_artist_entry_changed (Gtk.Entry entry)
		{
			change_color(entry, artist);
		}


		[CCode (instance_pos = -1)]
		public void on_album_entry_changed (Gtk.Entry entry)
		{
			change_color(entry, album);
		}


		[CCode (instance_pos = -1)]
		public void on_tracknr_button_changed (Gtk.SpinButton entry)
		{
			change_color(entry, tracknr);
		}


		[CCode (instance_pos = -1)]
		public void on_date_entry_changed (Gtk.Entry entry)
		{
			change_color(entry, date);
		}


		[CCode (instance_pos = -1)]
		public void on_genre_combo_box_entry_changed (Gtk.ComboBox editable)
		{
			var widget = genre_combo_box_entry.get_child() as Gtk.Entry;
			change_color(widget, genre);
		}


		private void set_str(Gtk.Editable editable, string key)
		{
			unowned string val = editable.get_chars(0, -1);

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


		[CCode (instance_pos = -1)]
		public void on_song_entry_activated (Gtk.Entry entry)
		{
			set_str(entry, "title");
		}


		[CCode (instance_pos = -1)]
		public void on_artist_entry_activated (Gtk.Entry entry)
		{
			set_str(entry, "artist");
		}


		[CCode (instance_pos = -1)]
		public void on_album_entry_activated (Gtk.Entry entry)
		{
			set_str(entry, "album");
		}


		[CCode (instance_pos = -1)]
		public void on_tracknr_button_activated (Gtk.SpinButton entry)
		{
			set_int(entry, "tracknr");
		}


		[CCode (instance_pos = -1)]
		public void on_date_entry_activated(Gtk.Entry entry)
		{
			set_str(entry, "date");
		}


		[CCode (instance_pos = -1)]
		public void on_genre_box_button_activated (Gtk.Entry entry)
		{
			set_str(entry, "genre");
		}


		[CCode (instance_pos = -1)]
		public void on_rating_entry_changed (RatingEntry entry)
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


		[CCode (instance_pos = -1)]
		public void on_prev_button_clicked (Gtk.Button btn)
		{
			if (current.prev != null) {
				current = current.prev;
				refresh();
			}
		}


		[CCode (instance_pos = -1)]
		public  void on_next_button_clicked (Gtk.Button btn)
		{
			if (current.next != null) {
				current = current.next;
				refresh();
			}
		}


		[CCode (instance_pos = -1)]
		public void on_close_all_button_clicked (Gtk.Button btn)
		{
			close();
		}


		private bool on_medialib_get_info (Xmms.Value val)
		{
			show_overview(val);
			store.clear();
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
				artist_entry.override_background_color(Gtk.StateFlags.NORMAL, null);
			}

			if (!val.dict_entry_get_string("album", out tmp)) {
				tmp = "";
			}
			if (!updated || album_entry.get_text() == tmp) {
				album = tmp;
				album_entry.text = tmp;
				album_entry.override_background_color(Gtk.StateFlags.NORMAL, null);
			}

			if (!val.dict_entry_get_string("title", out tmp)) {
				tmp = "";
			}
			if (!updated || song_entry.get_text() == tmp) {
				song = tmp;
				song_entry.text = tmp;
				song_entry.override_background_color(Gtk.StateFlags.NORMAL, null);
			}

			if (!val.dict_entry_get_int("tracknr", out itmp)) {
				itmp = 0;
			}

			tmp = itmp.to_string("%i");

			if (!updated || tracknr_button.get_text() == tmp) {
				tracknr = tmp;
				tracknr_button.set_value(itmp);
				tracknr_button.override_background_color(Gtk.StateFlags.NORMAL, null);
			}

			if (!val.dict_entry_get_string("date", out tmp)) {
				tmp = "";
			}
			if (!updated || date_entry.get_text() == tmp) {
				date = tmp;
				date_entry.text = tmp;
				date_entry.override_background_color(Gtk.StateFlags.NORMAL, null);
			}

			if (!val.dict_entry_get_string("genre", out tmp)) {
				tmp = "";
			}

			var entry = (Gtk.Entry) genre_combo_box_entry.get_child();
			if (!updated || entry.text == tmp) {
				genre = tmp;
				entry.text = tmp;
				entry.override_background_color(Gtk.StateFlags.NORMAL, null);
			}

			if (!val.dict_entry_get_int("rating", out itmp)) {
				itmp = 0;
			}

			if (!updated || rating_entry.rating == itmp) {
				rating = itmp.to_string("%i");
				rating_entry.rating = itmp;
			}
		}


		/* TODO: refactor me */
		private void dict_foreach (string key, Xmms.Value val)
		{
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

		public MedialibAddUrlDialog ()
		{
			set_default_response(Gtk.ResponseType.OK);
			set_default_size(300, 74);

			destroy_with_parent = true;
			modal = true;
			title = _("Add URL");

			add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
			add_button(_("Ok"), Gtk.ResponseType.OK);

			var combo = new Gtk.ComboBoxText.with_entry();
			var comp = new Gtk.EntryCompletion();

			comp.model = urls;
			comp.set_text_column(0);
			entry = (Gtk.Entry) combo.get_child ();
			entry.set_completion(comp);
			entry.activates_default = true;

			var vbox = get_content_area () as Gtk.Box;
			vbox.pack_start(combo, true, true, 0);

			close.connect(on_close);
			response.connect(on_response);

			Configurable.register(this);
			show_all();
		}


		private void save_url (string url)
		{
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


		private void on_close (Gtk.Dialog dialog)
		{
			Configurable.unregister(this);
		}


		private void on_response (Gtk.Dialog w, int response) {
			if(response == Gtk.ResponseType.OK && entry.get_text() != "") {
				save_url(entry.get_text());
			}
		}


		public void set_configuration (GLib.KeyFile file)
			throws GLib.KeyFileError
		{
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


		public void get_configuration (GLib.KeyFile file)
		{
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

		public MedialibFileChooserDialog ()
		{
			Gtk.CheckButton button = new Gtk.CheckButton.with_label(
					_("don't add to active playlist"));

			extra_widget = button;
			modal = true;
			select_multiple = true;
			title = _("Add File");

			add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
			add_button(_("Ok"), Gtk.ResponseType.OK);

			close.connect(on_close);
			response.connect(on_response);

			Configurable.register(this);
			show_all();
		}


		private void on_close (Gtk.Dialog dialog)
		{
			Configurable.unregister(this);
		}


		private void on_response (Gtk.Dialog dialog, int response)
		{
			if(response == Gtk.ResponseType.OK) {
				current_folder = get_current_folder();
			}
		}


		public void set_configuration (GLib.KeyFile file)
			throws GLib.KeyFileError
		{
			if (file.has_group("add_dialog")) {
				if (file.has_key("add_dialog", "file")) {
					current_folder = file.get_string("add_dialog", "file");
					set_current_folder(current_folder);
				}
			}
		}


		public void get_configuration (GLib.KeyFile file)
		{
			if(current_folder != null) {
				file.set_string("add_dialog", "file", current_folder);
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
				info_dialog = MedialibInfoDialog.build();
				info_dialog.transient_for = parent;
				info_dialog.set_client (client);
				info_dialog.delete_event.connect((ev) => {
					info_dialog = null;
					return false;
				});
				info_dialog.show_all();
			}
			info_dialog.add_mid(mid);
		}


		public static void create_add_url_dialog (Gtk.Window parent, Client client)
		{
			var dialog = new MedialibAddUrlDialog();
			dialog.transient_for = parent;

			if (dialog.run() == Gtk.ResponseType.OK) {
				client.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, dialog.entry.get_text());
			}
			dialog.close();
		}


		public static void create_add_file_dialog (Gtk.Window parent, Client client, Gtk.FileChooserAction action)
		{
			var dialog = new MedialibFileChooserDialog();
			dialog.set_action(action);
			dialog.transient_for = parent;

			if (dialog.run() == Gtk.ResponseType.OK) {
				GLib.SList<string> filenames;
				string url;
				Gtk.CheckButton button = (Gtk.CheckButton) dialog.extra_widget;

				filenames = dialog.get_filenames();

				foreach(string filename in filenames) {
					url = "file://" + filename;

					if (action == Gtk.FileChooserAction.OPEN) {
						if (button.get_active()) {
							client.xmms.medialib_add_entry(url);
						} else {
							client.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, url);
						}
					} else {
						if (button.get_active()) {
							client.xmms.medialib_import_path(url);
						} else {
							client.xmms.playlist_radd(Xmms.ACTIVE_PLAYLIST, url);
						}
					}
				}
			}
			dialog.close();
		}
	}
}
