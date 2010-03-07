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
		private Gtk.ComboBoxEntry _filter_cbox;
		private FilterView _filter_tree;
		private Gee.Queue<string> _pending_queries;
		private string _unsaved_query;

		public FilterView filter_tree {
			get {
				return _filter_tree;
			}
		}

		construct {
			position = 430;
			position_set = true;

			pack1(create_left_box(), true, true);
			pack2(create_right_box(), false, true);

			_pending_queries = new Gee.LinkedList<string>();

			Configurable.register(this);
		}


		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			if (file.has_group("panes") && file.has_key("panes", "pos2")) {
				int pos = file.get_integer("panes", "pos2");
				if (pos >= 0) {
					position = pos;
				}
			}

			if (file.has_group("filter") && file.has_key("filter", "patterns")) {
				Gtk.ListStore store = (Gtk.ListStore) _filter_cbox.model;
				Gtk.TreeIter iter;
				string[] list = file.get_string_list("filter", "patterns");

				for (int i = 0; i < list.length; i++) {
					store.insert_with_values(out iter, i, 0, list[i]);
				}
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			Gtk.ListStore store = (Gtk.ListStore) _filter_cbox.model;
			Gtk.TreeIter iter;
			string[] list = new string[25];
			string current;
			int i = 0;

			file.set_integer("panes", "pos2", position);

			if (store.iter_children(out iter, null)) {
				do {
					store.get(iter, 0, out current);
					list[i++] = current;
				} while (store.iter_next(ref iter) && i < 25);
			}

			file.set_string_list("filter", "patterns", list);
		}

		private void _filter_save (string pattern) {
			Gtk.ListStore store = (Gtk.ListStore) _filter_cbox.model;
			Gtk.TreeIter iter;
			string current;

			if (store.iter_children(out iter, null)) {
				do {
					store.get(iter, 0, out current);
					if (current == pattern) {
						store.remove(iter);
						break;
					}
				} while (store.iter_next(ref iter));
			}

			store.insert_with_values(out iter, 0, 0, pattern);
		}

		private void on_filter_entry_changed(Gtk.Editable widget) {
			Gdk.Color? color = null;
			Xmms.Collection coll;

			var entry = widget as Gtk.Entry;
			var text = entry.get_text();

			if (text.size() > 0) {
				if (Xmms.Collection.parse(text, out coll)) {
					_pending_queries.offer(text);
					_filter_tree.query_collection(coll, (val) => {
						var s = _pending_queries.poll();
						if (s != null && val.list_get_size() > 0) {
							if (_filter_cbox.child.has_focus) {
								_unsaved_query = s;
							} else if (_pending_queries.is_empty) {
								_filter_save(s);
							}
						}
						return true;
					});
				} else if (!Gdk.Color.parse("#ff6666", out color)) {
					color = null;
				}
			}

			entry.modify_base(Gtk.StateType.NORMAL, color);
		}

		private bool on_filter_entry_focus_out_event(Gtk.Widget w, Gdk.EventFocus e) {
			if (_unsaved_query != null && _unsaved_query == (w as Gtk.Entry).text) {
				_filter_save(_unsaved_query);
			}

			_unsaved_query = null;

			return false;
		}

		public void filter_entry_set_text(string text) {
			Gtk.Entry entry = (Gtk.Entry) _filter_cbox.child;
			entry.text = text;
		}

		private Gtk.Box create_left_box() {
			Gtk.VBox box = new Gtk.VBox(false, 0);

			Gtk.HBox hbox = new Gtk.HBox(false, 6);

			Gtk.Label label = new Gtk.Label(_("Filter:"));
			hbox.pack_start(label, false, false, 0);

			_filter_cbox = new Gtk.ComboBoxEntry.with_model(
				new Gtk.ListStore(1, typeof(string)), 0
			);

			Gtk.Entry entry = (Gtk.Entry) _filter_cbox.child;

			entry.changed.connect(on_filter_entry_changed);
			entry.focus_out_event.connect(on_filter_entry_focus_out_event);

			Gtk.EntryCompletion comp = new Gtk.EntryCompletion();
			comp.model = _filter_cbox.model;
			comp.set_text_column(0);

			entry.set_completion(comp);

			hbox.pack_start(_filter_cbox, true, true, 0);

			box.pack_start(hbox, false, false, 2);

			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
			                    Gtk.PolicyType.AUTOMATIC);
			scrolled.set_shadow_type(Gtk.ShadowType.IN);

			_filter_tree = new FilterView();
			scrolled.add(_filter_tree);

			box.pack_start(scrolled, true, true, 0);

			return box;
		}

		private Gtk.Box create_right_box() {
			Gtk.VBox box = new Gtk.VBox(false, 0);

			var playlist = new PlaylistWidget(Client.instance(), Config.instance());

			box.pack_start(playlist, true, true, 0);

			return box;
		}
	}
}
