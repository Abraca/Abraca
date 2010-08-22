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

using GLib;

namespace Abraca {
	public class RightHPaned : Gtk.HPaned, IConfigurable {
		private Searchable search;

		public RightHPaned(Gtk.AccelGroup group) {

			position = 430;
			position_set = true;

			var filter = new FilterWidget(Client.instance(), Config.instance(), group);
			pack1(filter, true, true);

			search = filter.get_searchable ();

			var playlist = new PlaylistWidget(Client.instance(), Config.instance(), search);
			pack2(playlist, false, true);

			Configurable.register(this);
		}


		/* TODO: This is a hack, remove me. */
		public Searchable get_searchable ()
		{
			return search;
		}


		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			if (!file.has_group("panes") || !file.has_key("panes", "pos2"))
				return;

			var pos = file.get_integer("panes", "pos2");
			if (pos >= 0) {
				position = pos;
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			file.set_integer("panes", "pos2", position);
		}
	}
}
