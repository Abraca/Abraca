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


		/**
		 * Register a configurable object.
		 * If the object was registered after the initial read
		 * of the config file, then the config file will be re-read.
		 */
		public static void register (IConfigurable obj)
		{
			GLib.KeyFile file;

			if (config_loaded) {
				/* Late register. Reload config and call object */
				file = read_config();

				try {
					obj.set_configuration(file);
				} catch (GLib.KeyFileError e) {
					GLib.error(e.message);
				}
			}

			configurables.remove(obj);
			configurables.prepend(obj);
		}

		/**
		 * Unregister a configurable object.
		 * As this happens before a "global shutdown" the
		 * settings from this object needs to be merged with
		 * the config file from disk.
		 */
		public static void unregister (IConfigurable obj)
		{
			GLib.KeyFile file = read_config();

			obj.get_configuration(file);
			configurables.remove(obj);

			write_config(file);
		}

		/**
		 * Construct the filename based on the standard XMMS2 path.
		 */
		private static string build_filename () throws GLib.FileError
		{
			char[] buf = new char[255];

			Xmms.Client.userconfdir_get(buf);

			string path = GLib.Path.build_filename(
				(string) buf, "clients", null
			);

			if (GLib.FileUtils.test(path, GLib.FileTest.EXISTS)) {
				if (!GLib.FileUtils.test(path, GLib.FileTest.IS_DIR)) {
					throw new GLib.FileError.NOTDIR(path + " is not a directory");
				}
			} else {
				if (GLib.DirUtils.create_with_parents(path, 0755) < 0) {
					throw new GLib.FileError.FAILED("Failed to create " + path);
				}
			}

			return GLib.Path.build_filename(path, "abraca.conf", null);
		}

		/**
		 * Read the config file.
		 */
		private static GLib.KeyFile read_config ()
		{
			GLib.KeyFile file = new GLib.KeyFile();

			try {
				string filename = build_filename();
				file.load_from_file(filename, GLib.KeyFileFlags.NONE);
			} catch (GLib.FileError e) {
				/* GLib.FileError.NOENT == 4, which is true the first time */
				if (e.code != 4) {
					GLib.stderr.printf("ERROR: %s\n", e.message);
				}
			} catch (GLib.KeyFileError e) {
				GLib.stderr.printf("Something went wrong");
			}

			return file;
		}

		/**
		 * Write the config file.
		 */
		private static void write_config (GLib.KeyFile file)
		{
			GLib.FileStream stream;
			size_t length;

			try {
				string filename = build_filename();
				stream = GLib.FileStream.open(filename, "w");
				stream.puts(file.to_data(out length));
			} catch (GLib.FileError e) {
				GLib.error(e.message);
			}
		}

		/**
		 * Load the config file and pass it to all registered listeners.
		 */
		public static void load ()
		{
			GLib.KeyFile file = read_config();

			foreach (weak IConfigurable obj in configurables) {
				try {
					obj.set_configuration(file);
				} catch (GLib.KeyFileError e) {
					GLib.error(e.message);
				}
			}

			config_loaded = true;
		}

		/**
		 * Ask all registered listeners for settings and save to file.
		 */
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
