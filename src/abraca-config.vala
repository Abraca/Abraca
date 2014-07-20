/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2013 Abraca Team
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

namespace Abraca {
	public class Config : GLib.Object, IConfigurable {
		const string[] _sort_keys = {
			N_("Artist"), N_("Album"), N_("Title"), N_("Year"), N_("Path"), N_("Custom")
		};

		public string sorting_artist {
			get; set; default = "artist,title";
		}

		public string sorting_album {
			get; set; default = "album,tracknr";
		}

		public string sorting_title {
			get; set; default = "title,url";
		}

		public string sorting_year {
			get; set; default = "date,artist,album,title,tracknr";
		}

		public string sorting_path {
			get; set; default = "url";
		}

		public string sorting_custom {
			get; set; default = "artist,date,album,tracknr,title,url";
		}

		public Config ()
		{
			Configurable.register(this);
		}

		public void set_configuration (GLib.KeyFile file)
			throws GLib.KeyFileError
		{
			if (file.has_group("sorting")) {
				if (file.has_key("sorting", "artist")) {
					sorting_artist = file.get_string("sorting", "artist");
				}
				if (file.has_key("sorting", "album")) {
					sorting_album = file.get_string("sorting", "album");
				}
				if (file.has_key("sorting", "title")) {
					sorting_title = file.get_string("sorting", "title");
				}
				if (file.has_key("sorting", "year")) {
					sorting_year = file.get_string("sorting", "year");
				}
				if (file.has_key("sorting", "path")) {
					sorting_path = file.get_string("sorting", "path");
				}
				if (file.has_key("sorting", "custom")) {
					sorting_custom = file.get_string("sorting", "custom");
				}
			}
		}

		public void get_configuration (GLib.KeyFile file)
		{
			file.set_string("sorting", "artist", sorting_artist);
			file.set_string("sorting", "album", sorting_album);
			file.set_string("sorting", "title", sorting_title);
			file.set_string("sorting", "year", sorting_year);
			file.set_string("sorting", "path", sorting_path);
			file.set_string("sorting", "custom", sorting_custom);
		}

		public void show_sorting_dialog (Gtk.Window parent)
		{
			var dialog = new Gtk.Dialog.with_buttons(
				_("Configure Sorting"), parent,
				Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
				Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
				Gtk.Stock.OK, Gtk.ResponseType.OK
			);

			dialog.resize (300, 200);

			var table = new Gtk.Grid();
			table.row_spacing = 7;
			table.column_spacing = 5;
			table.border_width = 5;

			var entries = new Gtk.Entry[6];

			var values = new string[] {
				sorting_artist, sorting_album,
				sorting_title, sorting_year,
				sorting_path, sorting_custom
			};

			for (var i = 0; i < 6; i++) {
				var label = new Gtk.Label("<b>" + _(_sort_keys[i]) + "</b>");
				label.xalign = 0;
				label.use_markup = true;
				table.attach(label, 0, i, 1, 1);

				entries[i] = new Gtk.Entry();
				entries[i].text = values[i];
				table.attach(entries[i], 1, i, 1, 1);
			}

			var box = dialog.get_content_area () as Gtk.Box;
			box.pack_start(new PrettyLabel (_("Configure Sorting")), false, true, 0);
			box.pack_start(table, true, true, 0);

			dialog.show_all();

			var response_id = dialog.run();

			if (response_id == Gtk.ResponseType.OK) {
				var i = 0;

				sorting_artist = entries[i++].text;
				sorting_album = entries[i++].text;
				sorting_title = entries[i++].text;
				sorting_year = entries[i++].text;
				sorting_path = entries[i++].text;
				sorting_custom = entries[i++].text;
			}

			dialog.close();
		}
	}
}
