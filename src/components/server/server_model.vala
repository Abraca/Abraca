/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2011  Abraca Team
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
	public class ServerModel: Gtk.ListStore, Gtk.Buildable
	{
		private DMAP.MdnsBrowser _browser;

		public enum Column {
			ICON,
			NAME,
			URI,
			FAVORITE
		}

		public void parser_finished(Gtk.Builder builder)
		{
			_browser = new DMAP.MdnsBrowser (DMAP.MdnsBrowserServiceType.XMMS2);
			try {
				_browser.start ();
			} catch (GLib.Error e) {
				GLib.debug (e.message);
			}

			_browser.service_added.connect ((service) => {
				GLib.debug ("%s", service.host);
			});


			/*
			foreach (var service in _browser.get_services ()) {
				GLib.debug ("%s", service.host);
			}
			*/


//			var name = GLib.Environment.get_host_name();
//			var path = Xmms.fallback_ipcpath_get();

//			if (path != null) {
//				add_server(name, path);
//			}
		}

		public void add_server(string? name, string uri, bool favorite=false)
		{
			if (name == null) {
				name = GLib.Environment.get_host_name();
			}

			if (!has_name(name)) {
				Gtk.TreeIter iter;

				append(out iter);
				set(iter,
					Column.ICON, uri.has_prefix("unix://") ? Gtk.Stock.HOME
														   : Gtk.Stock.NETWORK,
					Column.NAME, name,
					Column.URI, uri,
					Column.FAVORITE, favorite);
			}
		}


		public void add_server_from_address (string host, uint16 port=9667, bool favorite=false)
		{
			var resolver = GLib.Resolver.get_default();
			var address = new GLib.InetAddress.from_string(host);
			string name = host;

			if (address.is_loopback) {
				name = GLib.Environment.get_host_name();
			} else if (address.is_site_local) {
				try {
					name = resolver.lookup_by_address(address, null);
				} catch (GLib.Error e) {
					name = host;
				}
			}

			GLib.debug ("Found host: %s", name);

			add_server(name, "tcp://%s:%u".printf(host, port), favorite);
		}


		private bool has_name(string name)
		{
			Gtk.TreeIter iter;

			if (!get_iter_first(out iter)) {
				return false;
			}

			do {
				string c_name;

				get(iter, Column.NAME, out c_name);
				if (c_name == name) {
					return true;
				}
			} while (iter_next(ref iter));

			return false;
		}

		public string? get_host_at_path(Gtk.TreePath path)
		{
			Gtk.TreeIter iter;
			string result = null;

			if (get_iter(out iter, path)) {
				get(iter, Column.URI, out result);
			}

			return result;
		}
	}
}
