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

public class Abraca.ServerDiscoverUnix : ServerDiscover
{
	private const GLib.FileQueryInfoFlags FLAGS = GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS;

	private const string ATTRIBUTES =
		GLib.FileAttribute.STANDARD_NAME + ":" +
		GLib.FileAttribute.STANDARD_TYPE;

	private const uint INTERVAL = 5;

	private string directory_name;
	private bool discover_running = false;
	private uint timeout_id;


	/* [14:37:20][vdust]: I put my xmms2d socket in ~/.cache/xmms2/, as it should be imho.
	 * ...so should take a list of paths as argument
	 */
	public ServerDiscoverUnix (string directory_name)
	{
		this.directory_name = directory_name;
	}

	public override void do_start()
	{
		do_discover();
		timeout_id = GLib.Timeout.add_seconds(INTERVAL, do_discover);
	}

	public override void do_stop()
	{
		GLib.Source.remove(timeout_id);
	}

	private bool do_discover()
	{
		if (discover_running)
			return true;

		discover_running = true;

		discover_async.begin();

		return true;
	}

	private async void discover_async()
		throws GLib.Error
	{
		var directory = GLib.File.new_for_path(directory_name);
		var enumerator = yield directory.enumerate_children_async(ATTRIBUTES, FLAGS);

		while (true) {
			var files = yield enumerator.next_files_async(10, Priority.DEFAULT);
			if (files == null)
				break;

			foreach (var info in files)
				yield triage_path(info);
		}

		discover_running = false;
	}

	private async void triage_path (GLib.FileInfo info)
		throws GLib.Error
	{
		var type = info.get_attribute_uint32(GLib.FileAttribute.STANDARD_TYPE);
		if (type == GLib.FileType.SPECIAL) {
			var name = info.get_attribute_byte_string(GLib.FileAttribute.STANDARD_NAME);
			var path = GLib.Path.build_filename(directory_name, name);
			yield add_service(path, "unix://%s".printf(path), new GLib.UnixSocketAddress(path));
		}
	}
}
