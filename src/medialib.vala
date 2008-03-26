/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */

namespace Abraca {
	public class Medialib : GLib.Object {
		public void create_add_url_dialog() {

			Gtk.Dialog dialog = new Gtk.Dialog.with_buttons(
					"Add URL",
					(Gtk.Window) (Abraca.instance().main_window),
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
					Gtk.STOCK_OK, Gtk.ResponseType.OK
					);

			Gtk.Entry entry = new Gtk.Entry();

			dialog.vbox.pack_start_defaults(entry);
			dialog.show_all();

			if (dialog.run() == Gtk.ResponseType.OK) {
				Client c = Client.instance();

				c.xmms.playlist_add_url(Xmms.ACTIVE_PLAYLIST, entry.text);
			}

			dialog.close();
		}

		public void create_add_file_dialog(Gtk.FileChooserAction action) {
			Gtk.FileChooserDialog dialog;

			dialog = new Gtk.FileChooserDialog("Add file",
					(Gtk.Window) (Abraca.instance().main_window), action,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
					Gtk.STOCK_ADD, Gtk.ResponseType.OK
					);
			dialog.select_multiple = true;

			Gtk.CheckButton button = new Gtk.CheckButton.with_label(
					"don't add to active playlist");
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
			}
			dialog.close();
		}
	}
}
