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

using GLib;

namespace Abraca {
	public class RightHPaned : Gtk.HPaned, IConfigurable {
		private Gtk.ComboBoxEntry _filter_combo;
		private Gtk.Entry _filter_entry;
		private Gtk.ListStore _filter_patterns;
		private FilterTree _filter_tree;
		private PlaylistTree _playlist_tree;

		public FilterTree filter_tree {
			get {
				return _filter_tree;
			}
		}

		construct {
			position = 430;
			position_set = true;

			create_widgets();

			_filter_entry.changed += on_filter_entry_changed;
			_filter_entry.activate += on_filter_entry_activate;

			Config conf = Config.instance();
			conf.register(this);
		}


		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			int pos = file.get_integer("panes", "pos2");
			if (pos > 0) {
				position = pos;
			}

			if (file.has_key("filter", "patterns")) {
				string[] list = file.get_string_list("filter", "patterns");
				Gtk.TreeIter iter;

				for (int i = 0; i < list.length; i++) {
					_filter_patterns.insert_with_values(out iter, i, 0, list[i]);
				}
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			Gtk.TreeIter iter;
			string current;
			string[] list = new string[25];
			int i;

			file.set_integer("panes", "pos2", position);

			if (_filter_patterns.iter_children(out iter, null)) {
				do {
					_filter_patterns.get(iter, 0, out current);
					list[i++] = current;
				} while (_filter_patterns.iter_next(ref iter) && i < 25);
			}

			file.set_string_list("filter", "patterns", list);
		}

		private void on_filter_entry_changed(Gtk.Entry editable) {
			Xmms.Collection coll;
			Gdk.Color color;
			weak string text;
			bool is_error = false;

			text = _filter_entry.get_text();

			if (text.size() > 0) {
				if (!Xmms.Collection.parse(text, out coll)) {
					is_error = true;

					/* set color to a bright red */
					color.red = (ushort) 0xffff;
					color.green = (ushort) 0x6666;
					color.blue = (ushort) 0x6666;
				}
			}

			if (is_error)
				_filter_entry.modify_base(Gtk.StateType.NORMAL, color);
			else
				_filter_entry.modify_base(Gtk.StateType.NORMAL, null);
		}

		private void _filter_save (string pattern) {
			Gtk.TreeIter iter;
			string current;

			if (_filter_patterns.iter_children(out iter, null)) {
				do {
					_filter_patterns.get(iter, 0, out current);
					if (current == pattern) {
						_filter_patterns.remove(iter);
						break;
					}
				} while (_filter_patterns.iter_next(ref iter));
			}

			_filter_patterns.insert_with_values(out iter, 0, 0, pattern);
		}

		private void on_filter_entry_activate(Gtk.Entry entry) {
			Xmms.Collection coll;
			weak string pattern;

			pattern = _filter_entry.get_text();

			if (Xmms.Collection.parse(pattern, out coll)) {
				_filter_tree.query_collection(coll);
				_filter_save(pattern);
			}
		}

		public void filter_entry_set_text(string text) {
			_filter_entry.text = text;
		}

		private void create_widgets() {
			pack1(create_left_box(), true, true);
			pack2(create_right_box(), false, true);
		}

		private Gtk.Box create_left_box() {
			Gtk.VBox box = new Gtk.VBox(false, 0);

			Gtk.HBox hbox = new Gtk.HBox(false, 6);

			Gtk.Label label = new Gtk.Label(_("Filter:"));
			hbox.pack_start(label, false, false, 0);

			_filter_patterns = new Gtk.ListStore(1, typeof(string));
			_filter_combo = new Gtk.ComboBoxEntry.with_model(_filter_patterns, 0);
			_filter_entry = (Gtk.Entry) _filter_combo.child;

			Gtk.EntryCompletion comp = new Gtk.EntryCompletion();
			comp.model = _filter_patterns;
			comp.set_text_column(0);

			_filter_entry.set_completion(comp);

			hbox.pack_start(_filter_combo, true, true, 0);

			box.pack_start(hbox, false, false, 2);

			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.NEVER,
			                    Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type(Gtk.ShadowType.IN);

			_filter_tree = new FilterTree();
			scrolled.add(_filter_tree);
			box.pack_start(scrolled, true, true, 0);

			return box;
		}

		private Gtk.Box create_right_box() {
			Gtk.VBox box = new Gtk.VBox(false, 0);

			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
			                    Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type(Gtk.ShadowType.IN);

			_playlist_tree = new PlaylistTree();
			scrolled.add(_playlist_tree);
			box.pack_start(scrolled, true, true, 0);

			return box;
		}
	}
}
