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
		public string add_dialog_file {
			get; set; default("");
		}

		public string add_dialog_url {
			get; set; default("");
		}

		construct {
			Config conf = Config.instance();
			conf.register(this);
		}

		public void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError {
			if (file.has_group("add_dialog")) {
				if (file.has_key("add_dialog", "file")) {
					add_dialog_file = file.get_string("add_dialog", "file");
				}
				if (file.has_key("add_dialog", "url")) {
					add_dialog_url = file.get_string("add_dialog", "url");
				}
			}
		}

		public void get_configuration(GLib.KeyFile file) {
			file.set_string("add_dialog", "file", add_dialog_file);
			file.set_string("add_dialog", "url", add_dialog_url);
		}

		public void create_add_url_dialog() {

			Gtk.Dialog dialog = new Gtk.Dialog.with_buttons(
					_("Add URL"),
					(Gtk.Window) (Abraca.instance().main_window),
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
					Gtk.STOCK_OK, Gtk.ResponseType.OK
					);

			Gtk.Entry entry = new Gtk.Entry();
			entry.text = add_dialog_url;

			((Gtk.VBox)dialog.vbox).pack_start_defaults(entry);
			dialog.show_all();

			if (dialog.run() == Gtk.ResponseType.OK) {
				Client c = Client.instance();

				c.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, entry.text);
				add_dialog_url = entry.text;
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

			if (add_dialog_file != "") {
				dialog.set_current_folder(add_dialog_file);
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
				add_dialog_file = dialog.get_current_folder();
			}
			dialog.close();
		}
	}
}
