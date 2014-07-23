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

public abstract class Abraca.ServerDiscover : GLib.Object
{
	public signal void service_added(string display_name, string directory_name);
	public signal void service_removed(string display_name, string directory_name);

	private Gee.Set<string> services = new Gee.HashSet<string>();

	public bool running {
		get; private set; default = false;
	}

	protected async void add_service(string name, string path, GLib.SocketConnectable connectable)
	{
		var success = yield ServerProber.check_version(connectable);
		if (success) {
			if (services.add(name))
				service_added(name, path);
		} else {
			if (services.remove(name))
				service_removed(name, path);
		}
	}

	protected void remove_service (string name, string path)
	{
		if (services.remove(name))
			service_removed(name, path);
	}

	public void start()
	{
		if (!running) {
			do_start();
			running = true;
		}
	}

	public void stop()
	{
		if (running) {
			do_stop();
			running = false;
			services.clear();
		}
	}

	protected abstract void do_start();
	protected abstract void do_stop();
}
