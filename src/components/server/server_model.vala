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
	public class ServerModel: Gtk.ListStore, Gtk.Buildable
	{
		public enum Column {
			ICON,
			NAME,
			URI,
			FAVORITE
		}

#if HAVE_AVAHI_GOBJECT
		private Avahi.Client _avahi_client;
		private Avahi.ServiceBrowser _avahi_service_browser;
		private Gee.LinkedList<Avahi.ServiceResolver> _avahi_service_resolvers;
#endif

		public void parser_finished(Gtk.Builder builder)
		{
#if HAVE_AVAHI_GOBJECT
			_avahi_client            = new Avahi.Client(Avahi.ClientFlags.NO_FAIL);
			_avahi_service_browser   = new Avahi.ServiceBrowser("_xmms2._tcp");
			_avahi_service_resolvers = new Gee.LinkedList<Avahi.ServiceResolver>();

			try {
				_avahi_client.start();

				_avahi_service_browser.new_service.connect(on_new_service);
				_avahi_service_browser.removed_service.connect(on_removed_service);
				_avahi_service_browser.attach(_avahi_client);
			} catch (Avahi.Error e) {
				GLib.warning ("Unable to connect to Avahi Daemon (%s).", e.message);
			}
#endif

//			var name = GLib.Environment.get_host_name();
//			var path = Xmms.fallback_ipcpath_get();

//			if (path != null) {
//				add_server(name, path);
//			}
		}

#if HAVE_AVAHI_GOBJECT
		private void on_new_service(Avahi.Interface i, Avahi.Protocol p, string n, string t, string d, Avahi.LookupResultFlags f) {
			var resolver = new Avahi.ServiceResolver(i, p, n, t, d, Avahi.Protocol.UNSPEC);

			resolver.found.connect((i, p, n, t, d, h, a, port, txt, f) => {
				add_server_from_address(n, a.to_string(), port);
				_avahi_service_resolvers.remove(resolver);
			});
			resolver.failure.connect((e) => {
				GLib.warning(e.message);
				_avahi_service_resolvers.remove(resolver);
			});

			try {
				resolver.attach(_avahi_client);
			} catch (Avahi.Error e) {
				GLib.error(e.message);
				return;
			}

			_avahi_service_resolvers.add(resolver);
		}

		private void on_removed_service(Avahi.Interface i, Avahi.Protocol p, string n, string t, string d, Avahi.LookupResultFlags f) {
			// Never remove the local xmms2d from the model.
			if (n == GLib.Environment.get_host_name()) {
				return;
			}

			Gtk.TreeIter iter;

			if (!get_iter_first(out iter)) {
				return;
			}

			do {
				string name;

				get(iter, Column.NAME, out name);

				if (name == n) {
					remove(iter);
					break;
				}
			} while (iter_next(ref iter));
		}
#endif

		public void add_server(string? name, string uri, bool favorite=false)
		{
			if (name == null) {
				name = GLib.Environment.get_host_name();
			}

			if (!has_name(name)) {
				Gtk.TreeIter iter;

				append(out iter);
				set(iter,
					Column.ICON, uri.has_prefix("unix://") ? Gtk.STOCK_HOME
														   : Gtk.STOCK_NETWORK,
					Column.NAME, name,
					Column.URI, uri,
					Column.FAVORITE, favorite);
			}
		}


		public void add_server_from_address (string? name, string host, uint16 port, bool favorite=false)
		{
			var resolver = GLib.Resolver.get_default();
			var address = new GLib.InetAddress.from_string(host);

			if (name == null) {
				if (address.is_loopback) {
					name = GLib.Environment.get_host_name();
				} else if (address.is_site_local) {
					try {
						name = resolver.lookup_by_address(address, null);
					} catch (GLib.Error e) {
						name = host;
					}
				}
			}

			if (name == null)
				name = host;

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
