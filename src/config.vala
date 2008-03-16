/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */

namespace Abraca {
	public class Config {
		const string[] _sort_keys = {"Artist", "Album", "Title", "Year", "Path", "Custom"};
		public int main_window_gravity {
			get; set;
		}

		public int main_window_x {
			get; set;
		}

		public int main_window_y {
			get; set;
		}

		public int main_window_width {
			get; set;
		}

		public int main_window_height {
			get; set;
		}

		public bool main_window_maximized {
			get; set;
		}

		public int panes_pos1 {
			get; set;
		}

		public int panes_pos2 {
			get; set;
		}

		public bool playlist_expanded {
			get; set;
		}

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

		public Config () {
			/* TODO: To be removed once default strings
			 *       work in Vala again.
			 */
			sorting_artist = "artist,title";
			sorting_album = "album,tracknr";
			sorting_title = "title,url";
			sorting_year = "date,artist,album,title,tracknr";
			sorting_path = "url";
			sorting_custom = "artist,date,album,tracknr,title,url";
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
			GLib.KeyFile f = new GLib.KeyFile();
			string filename = build_filename();
			string tmp;

			try {
				f.load_from_file(filename, GLib.KeyFileFlags.NONE);
			} catch (GLib.Error ex) {
				/* First time abraca is launched, no config exists. */
				return;
			}

			main_window_gravity = f.get_integer("main_win", "gravity");
			main_window_x = f.get_integer("main_win", "x");
			main_window_y = f.get_integer("main_win", "y");
			main_window_width =  f.get_integer("main_win", "width");
			main_window_height = f.get_integer("main_win", "height");
			main_window_maximized = f.get_boolean("main_win", "maximized");

			panes_pos1 = f.get_integer("panes", "pos1");
			panes_pos2 = f.get_integer("panes", "pos2");

			playlist_expanded = f.get_boolean("playlist", "expanded");

			tmp = f.get_string("sorting", "artist");
			if (tmp != null && tmp != "")
				sorting_artist = tmp;

			tmp = f.get_string("sorting", "album");
			if (tmp != null && tmp != "")
				sorting_album = tmp;

			tmp = f.get_string("sorting", "title");
			if (tmp != null && tmp != "")
				sorting_title = tmp;

			tmp = f.get_string("sorting", "year");
			if (tmp != null && tmp != "")
				sorting_year = tmp;

			tmp = f.get_string("sorting", "path");
			if (tmp != null && tmp != "")
				sorting_path = tmp;

			tmp = f.get_string("sorting", "custom");
			if (tmp != null || tmp != "")
				sorting_custom = tmp;
		}

		public void save() {
			GLib.KeyFile f = new GLib.KeyFile();

			f.set_integer("main_win", "gravity", main_window_gravity);
			f.set_integer("main_win", "x", main_window_x);
			f.set_integer("main_win", "y", main_window_y);
			f.set_integer("main_win", "width", main_window_width);
			f.set_integer("main_win", "height", main_window_height);
			f.set_boolean("main_win", "maximized", main_window_maximized);
			f.set_integer("panes", "pos1", panes_pos1);
			f.set_integer("panes", "pos2", panes_pos2);
			f.set_boolean("playlist", "expanded", playlist_expanded);
			f.set_string("sorting", "artist", sorting_artist);
			f.set_string("sorting", "album", sorting_album);
			f.set_string("sorting", "title", sorting_title);
			f.set_string("sorting", "year", sorting_year);
			f.set_string("sorting", "path", sorting_path);
			f.set_string("sorting", "custom", sorting_custom);

			GLib.FileStream stream = GLib.FileStream.open(build_filename(), "w");

			uint length;
			stream.puts(f.to_data(out length));
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

			dialog.vbox.pack_start_defaults(table);
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
