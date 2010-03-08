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

namespace Abraca {
	public class MainHPaned : Gtk.HPaned, IConfigurable {
		private RightHPaned _right_hpaned;

		public RightHPaned right_hpaned {
			get {
				return _right_hpaned;
			}
		}

		public MainHPaned (Gtk.AccelGroup group) {
			position = 135;
			position_set = true;

			create_widgets(group);

			Configurable.register(this);
		}


		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			if (!file.has_group("panes")) {
				return;
			}

			if (file.has_key("panes", "pos1")) {
				int pos = file.get_integer("panes", "pos1");
				if (pos >= 0) {
					position = pos;
				}
			}
		}


		public void get_configuration(GLib.KeyFile file) {
			file.set_integer("panes", "pos1", position);
		}


		private void create_widgets(Gtk.AccelGroup group) {
			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.NEVER,
			                    Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type(Gtk.ShadowType.IN);

			scrolled.add(new CollectionsView());

			pack1(scrolled, false, true);

			_right_hpaned = new RightHPaned(group);
			pack2(_right_hpaned, true, true);
		}
	}
}
