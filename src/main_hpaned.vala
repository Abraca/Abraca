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
	public class MainHPaned : Gtk.HPaned {
		private CollectionsTree _coll_tree;
		private RightHPaned _right_hpaned;

		public CollectionsTree collections_tree {
			get {
				return _coll_tree;
			}
		}

		public RightHPaned right_hpaned {
			get {
				return _right_hpaned;
			}
		}

		construct {
			position = 120;
			position_set = false;

			create_widgets();
		}

		public void eval_config() {
			int pos = Abraca.instance().config.panes_pos1;

			position = pos.clamp(120, 800);

			/* other widgets */
			_right_hpaned.eval_config();
		}

		private void create_widgets() {
			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.NEVER,
			                    Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type(Gtk.ShadowType.IN);

			_coll_tree = new CollectionsTree();
			scrolled.add(_coll_tree);

			pack1(scrolled, false, true);

			_right_hpaned = new RightHPaned();
			pack2(_right_hpaned, true, true);
		}
	}
}
