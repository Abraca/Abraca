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
	public interface IConfigurable : GLib.Object {
		public abstract void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError;
		public abstract void get_configuration(GLib.KeyFile file);
	}

	public class Configurable : GLib.Object {
		private static GLib.SList<IConfigurable> configurables = new GLib.SList<IConfigurable>();
		private static bool config_loaded = false;


		public static void register (IConfigurable obj)
		{
			GLib.KeyFile file;

			if (config_loaded) {
				/* Late register. Reload config and call object */
				file = read_config();

				try {
					obj.set_configuration(file);
				} catch (GLib.KeyFileError e) {
				}
			}

			configurables.remove(obj);
			configurables.prepend(obj);
		}

		public static void unregister (IConfigurable obj)
		{
			GLib.KeyFile file = read_config();

			obj.get_configuration(file);
			configurables.remove(obj);

			write_config(file);
		}

		private static string build_filename ()
		{
			char[] buf = new char[255];

			Xmms.Client.userconfdir_get(buf);

			string ret = GLib.Path.build_filename(
				(string) buf, "clients", "abraca.conf", null
			);

			return ret;
		}

		private static GLib.KeyFile read_config ()
		{
			GLib.KeyFile file = new GLib.KeyFile();

			try {
				string filename = build_filename();
				file.load_from_file(filename, GLib.KeyFileFlags.NONE);
			} catch (GLib.Error ex) {
				/* First time abraca is launched, no config exists. */
			}

			return file;
		}

		private static void write_config (GLib.KeyFile file)
		{
			GLib.FileStream stream;
			size_t length;

			stream = GLib.FileStream.open(build_filename(), "w");
			stream.puts(file.to_data(out length));
		}

		public static void load ()
		{
			GLib.KeyFile file = read_config();

			foreach (weak IConfigurable obj in configurables) {
				try {
					obj.set_configuration(file);
				} catch (GLib.KeyFileError e) {
				}
			}

			config_loaded = true;
		}

		public static void save ()
		{
			GLib.KeyFile file = read_config();

			foreach (weak IConfigurable obj in configurables) {
					obj.get_configuration(file);
			}

			write_config(file);
		}
	}
}
