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

namespace Abraca {
	public class Config : GLib.Object, IConfigurable {
		private static Config _instance;

		private GLib.SList<IConfigurable> configurables;

		const string[] _sort_keys = {
			"Artist", "Album", "Title", "Year", "Path", "Custom"
		};

		public string sorting_artist {
			get; set; default("artist,title");
		}

		public string sorting_album {
			get; set; default("album,tracknr");
		}

		public string sorting_title {
			get; set; default("title,url");
		}

		public string sorting_year {
			get; set; default("date,artist,album,title,tracknr");
		}

		public string sorting_path {
			get; set; default("url");
		}

		public string sorting_custom {
			get; set; default("artist,date,album,tracknr,title,url");
		}

		public static Config instance() {
			if (_instance == null)
				_instance = new Config();

			return _instance;
		}

		construct {
			configurables = new GLib.SList<IConfigurable>();
			register(this);
		}

		public void register(IConfigurable obj) {
			configurables.prepend(obj);
		}

		private string build_filename() {
			char[] buf = new char[255];

			Xmms.Client.userconfdir_get(buf);

			string ret = GLib.Path.build_filename(
				(string) buf, "clients", "abraca.conf", null
			);

			return ret;
		}

		public void load() {
			GLib.KeyFile file;

			file = new GLib.KeyFile();

			try {
				string filename = build_filename();
				file.load_from_file(filename, GLib.KeyFileFlags.NONE);
			} catch (GLib.Error ex) {
				/* First time abraca is launched, no config exists. */
				return;
			}

			foreach (weak IConfigurable conf in configurables) {
				try {
					conf.set_configuration(file);
				} catch (GLib.KeyFileError e) {
				}
			}
		}

		public void save() {
			GLib.FileStream stream;
			GLib.KeyFile file;
			/* TODO: Should be gsize */
			uint length;

			file = new GLib.KeyFile();

			foreach (weak IConfigurable conf in configurables) {
					conf.get_configuration(file);
			}

			stream = GLib.FileStream.open(build_filename(), "w");
			stream.puts(file.to_data(out length));
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			string tmp;

			tmp = file.get_string("sorting", "artist");
			if (tmp != null && tmp != "")
				sorting_artist = tmp;

			tmp = file.get_string("sorting", "album");
			if (tmp != null && tmp != "")
				sorting_album = tmp;

			tmp = file.get_string("sorting", "title");
			if (tmp != null && tmp != "")
				sorting_title = tmp;

			tmp = file.get_string("sorting", "year");
			if (tmp != null && tmp != "")
				sorting_year = tmp;

			tmp = file.get_string("sorting", "path");
			if (tmp != null && tmp != "")
				sorting_path = tmp;

			tmp = file.get_string("sorting", "custom");
			if (tmp != null || tmp != "")
				sorting_custom = tmp;


		}

		public void get_configuration(GLib.KeyFile file) {
			file.set_string("sorting", "artist", sorting_artist);
			file.set_string("sorting", "album", sorting_album);
			file.set_string("sorting", "title", sorting_title);
			file.set_string("sorting", "year", sorting_year);
			file.set_string("sorting", "path", sorting_path);
			file.set_string("sorting", "custom", sorting_custom);
		}

		public void show_sorting_dialog() {
			Gtk.Entry[] entrys;
			Gtk.Dialog dialog;
			Gtk.Table table;
			string[] values;
			Gtk.Label label;
			int response_id, i;

			dialog = new Gtk.Dialog.with_buttons(
					"Configure Sorting",
					(Gtk.Window) (Abraca.instance().main_window),
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.STOCK_OK, Gtk.ResponseType.OK,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL
			);

			table = new Gtk.Table(6, 2, true);
			table.homogeneous = false;
			entrys = new Gtk.Entry[6];

			values = new string[] {
				sorting_artist, sorting_album,
				sorting_title, sorting_year,
				sorting_path, sorting_custom
			};

			for(i = 0; i < 6; i++) {
				if (i == 5) {
					label = new Gtk.Label("<b>"+_sort_keys[i]+"</b>");
					label.use_markup = true;
				} else {
					label = new Gtk.Label(_sort_keys[i]);
				}

				table.attach(label, 0, 1, i + 0, i + 1, 0, 0, 10, 5);

				entrys[i] = new Gtk.Entry();
				entrys[i].text = values[i];

				table.attach_defaults(entrys[i], 1, 2, i + 0, i + 1);
			}

			((Gtk.VBox)dialog.vbox).pack_start_defaults(table);
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
