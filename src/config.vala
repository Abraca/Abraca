/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2010  Abraca Team
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
			"Artist", "Album", "Title", "Year", "Path", "Custom"
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

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
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

		public void get_configuration(GLib.KeyFile file) {
			file.set_string("sorting", "artist", sorting_artist);
			file.set_string("sorting", "album", sorting_album);
			file.set_string("sorting", "title", sorting_title);
			file.set_string("sorting", "year", sorting_year);
			file.set_string("sorting", "path", sorting_path);
			file.set_string("sorting", "custom", sorting_custom);
		}

		public void show_sorting_dialog (Gtk.Window parent)
		{
			Gtk.Entry[] entrys;
			Gtk.Dialog dialog;
			Gtk.Table table;
			string[] values;
			Gtk.Label label;
			int response_id, i;

			dialog = new Gtk.Dialog.with_buttons(
					"Configure Sorting", parent,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
					Gtk.STOCK_OK, Gtk.ResponseType.OK
			);

			dialog.resize (300, 200);
			dialog.has_separator = false;

			table = new Gtk.Table(6, 2, false);
			table.set_row_spacings(7);
			table.set_col_spacings(5);
			table.border_width = 5;
			entrys = new Gtk.Entry[6];

			values = new string[] {
				sorting_artist, sorting_album,
				sorting_title, sorting_year,
				sorting_path, sorting_custom
			};

			for(i = 0; i < 6; i++) {
				label = new Gtk.Label("<b>" + _sort_keys[i] + "</b>");
				label.xalign = 0;
				label.use_markup = true;
				table.attach_defaults(label, 0, 1, i + 0, i + 1);

				entrys[i] = new Gtk.Entry();
				entrys[i].text = values[i];
				table.attach_defaults(entrys[i], 1, 2, i + 0, i + 1);
			}

			dialog.vbox.pack_start(new PrettyLabel ("Configure Sorting"), false, true, 0);
			dialog.vbox.pack_start(table, true, true, 0);
			dialog.show_all();

			response_id = dialog.run();

			if (response_id == Gtk.ResponseType.OK) {
				i = 0;

				sorting_artist = entrys[i++].text;
				sorting_album = entrys[i++].text;
				sorting_title = entrys[i++].text;
				sorting_year = entrys[i++].text;
				sorting_path = entrys[i++].text;
				sorting_custom = entrys[i++].text;
			}

			dialog.close();
		}
	}
}
