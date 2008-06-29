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
	namespace Widget {
		public class CheckMenuItem : Gtk.CheckMenuItem {
			public string config_key { get; construct; }
			public string label_text { get; construct; }
			public string label_mnemonic { get; construct; }

			public CheckMenuItem (string key) {
				config_key = key;
			}

			public CheckMenuItem.with_label(string key, string text) {
				config_key = key;
				label_text = text;
			}

			public CheckMenuItem.with_mnemonic(string key, string text) {
				config_key = key;
				label_mnemonic = text;
			}

			construct {
				Client c = Client.instance();

				if(label_text != null || label_mnemonic != null) {
					Gtk.AccelLabel label;

					if(label_mnemonic != null) {
						label = new Gtk.AccelLabel(label_mnemonic);
						label.set_text_with_mnemonic(label_mnemonic);
					} else {
						label = new Gtk.AccelLabel(label_text);
					}

					label.set_accel_widget(this);
					label.set_alignment(0.0f, 0.5f);

					add(label);
				}

				c.connected += on_connected;
				c.configval_changed += on_value_changed;
				toggled += on_toggle;
			}

			private void on_connected(Client c) {
				c.xmms.configval_get(config_key).notifier_set(on_value_get);
			}

			private void on_value_get(Xmms.Result #res) {
				weak string val;

				res.get_string(out val);
				set_active((bool) val.to_int());
			}

			private void on_value_changed(Client c, string key, string val) {
				if(key == config_key) {
					set_active((bool) val.to_int());
				}
			}

			private void on_toggle(CheckMenuItem item) {
				string active = ((int)item.active).to_string();

				Client.instance().xmms.configval_set(config_key, active);
			}
		}
	}
}
