/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */

namespace Abraca {
	public class Config {
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

			try {
				f.load_from_file(filename, GLib.KeyFileFlags.NONE);
			} catch (GLib.Error ex) {
				GLib.stderr.printf("cannot read config file at %s\n",
				              filename);
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

			GLib.FileStream stream = GLib.FileStream.open(build_filename(), "w");

			uint length;
			stream.puts(f.to_data(out length));
		}
	}
}
