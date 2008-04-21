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
	public class Medialib : GLib.Object, IConfigurable {
		private string _add_file = "";

		private Gtk.ListStore _add_urls;

		construct {
			Config conf = Config.instance();
			conf.register(this);

			_add_urls = new Gtk.ListStore(1, typeof(string));
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			if (file.has_group("add_dialog")) {
				if (file.has_key("add_dialog", "file")) {
					_add_file = file.get_string("add_dialog", "file");
				}
				if (file.has_key("add_dialog", "urls")) {
					string[] list = file.get_string_list("add_dialog", "urls");
					Gtk.TreeIter iter;

					for (int i = 0; i < list.length; i++) {
						_add_urls.insert_with_values(out iter, i, 0, list[i]);
					}
				}
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			Gtk.TreeIter iter;
			string current;
			string[] list = new string[25];
			int i;

			if (_add_urls.iter_children(out iter, null)) {
				do {
					_add_urls.get(iter, 0, out current);
					list[i++] = current;
				} while (_add_urls.iter_next(ref iter) && i < 25);
			}

			file.set_string("add_dialog", "file", _add_file);
			file.set_string_list("add_dialog", "urls", list);
		}

		private void _add_urls_save(weak string url) {
			Gtk.TreeIter iter;
			string current;

			if (_add_urls.iter_children(out iter, null)) {
				do {
					_add_urls.get(iter, 0, out current);
					if (current == url) {
						_add_urls.remove(iter);
						break;
					}
				} while (_add_urls.iter_next(ref iter));
			}

			_add_urls.insert_with_values(out iter, 0, 0, url);
		}

		public void create_add_url_dialog() {
			Gtk.Dialog dialog = new Gtk.Dialog.with_buttons(
					_("Add URL"),
					(Gtk.Window) (Abraca.instance().main_window),
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
					Gtk.STOCK_OK, Gtk.ResponseType.OK
					);
			Gtk.ComboBoxEntry combo = new Gtk.ComboBoxEntry.with_model(_add_urls, 0);
			Gtk.EntryCompletion comp = new Gtk.EntryCompletion();
			Gtk.Entry entry = (Gtk.Entry) combo.child;

			comp.model = _add_urls;
			comp.set_text_column(0);
			entry.set_completion(comp);
			entry.activates_default = true;

			((Gtk.VBox)dialog.vbox).pack_start_defaults(combo);
			dialog.set_default_response(Gtk.ResponseType.OK);
			dialog.set_default_size(300, 74);
			dialog.show_all();

			if (dialog.run() == Gtk.ResponseType.OK) {
				Client c = Client.instance();

				c.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, entry.get_text());
				_add_urls_save(entry.get_text());
			}

			dialog.close();
		}

		public void create_add_file_dialog(Gtk.FileChooserAction action) {
			Gtk.FileChooserDialog dialog;

			dialog = new Gtk.FileChooserDialog(_("Add file"),
					(Gtk.Window) (Abraca.instance().main_window), action,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
					Gtk.STOCK_ADD, Gtk.ResponseType.OK
					);

			dialog.select_multiple = true;

			if (_add_file != "") {
				dialog.set_current_folder(_add_file);
			}

			Gtk.CheckButton button = new Gtk.CheckButton.with_label(
					_("don't add to active playlist"));
			dialog.extra_widget = button;

			dialog.show_all();

			if (dialog.run() == Gtk.ResponseType.OK) {
				Client c = Client.instance();
				weak GLib.SList<string> filenames;
				string url;

				filenames = dialog.get_filenames();

				foreach(string filename in filenames) {
					url = "file://" + filename;

					if (action == Gtk.FileChooserAction.OPEN) {
						if (button.get_active()) {
							c.xmms.medialib_add_entry(url);
						} else {
							c.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, url);
						}
					} else {
						if (button.get_active()) {
							c.xmms.medialib_path_import(url);
						} else {
							c.xmms.playlist_radd(Xmms.ACTIVE_PLAYLIST, url);
						}
					}
				}
				_add_file = dialog.get_current_folder();
			}
			dialog.close();
		}
	}
}
