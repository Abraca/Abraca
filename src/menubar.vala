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
	public class MenuBar : Gtk.MenuBar {

		private const string[] _authors = {
				"Christopher Rosell <chrippa@tanuki.se>",
				"Martin Salzer <stoky@gmx.net>",
				"Sebastian Sareyko <smoon@nooms.de>",
				"Tilman Sauerbeck <tilman@xmms.org>",
				"Daniel Svensson <dsvensson@gmail.com>",
				null
		};

		private const string[] _artists = {
				"Johan Slikkie van der Slikke <johan@slikkie.nl>",
				"Jakub Steiner <jimmac@ximian.com>",
				null
		};

		private const string _license = "Abraca, an XMMS2 client.\nCopyright (C) 2008  Abraca Team\n\nThis program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.";

		construct {
			append(create_music_menu());
			append(create_playlist_menu());
			append(create_help_menu());
		}

		private Gtk.MenuItem create_music_menu() {
			Gtk.MenuItem ret = new Gtk.MenuItem.with_mnemonic(
				_("_Music")
			);
			Gtk.ImageMenuItem img_item;
			Gtk.MenuItem item;
			Gtk.Image img;
			Gtk.Menu sub = new Gtk.Menu();
			Gtk.Menu subsub = new Gtk.Menu();

			img = new Gtk.Image.from_stock(Gtk.STOCK_FILE, Gtk.IconSize.MENU);
			img_item = new Gtk.ImageMenuItem.with_mnemonic(
				_("_Files")
			);
			img_item.set_image(img);
			img_item.activate += on_music_add_file;
			subsub.append(img_item);

			img = new Gtk.Image.from_stock(Gtk.STOCK_DIRECTORY, Gtk.IconSize.MENU);
			img_item = new Gtk.ImageMenuItem.with_mnemonic(
				_("_Dirs")
			);
			img_item.set_image(img);
			img_item.activate += on_music_add_dir;
			subsub.append(img_item);

			img = new Gtk.Image.from_stock(Gtk.STOCK_NETWORK, Gtk.IconSize.MENU);
			img_item = new Gtk.ImageMenuItem.with_mnemonic(
				_("_URL")
			);
			img_item.set_image(img);
			img_item.activate += on_music_add_url;
			subsub.append(img_item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ADD, null);
			item.set_submenu(subsub);
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_SAVE, null);
			item.activate += on_music_save;
			item.sensitive = false;
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_QUIT, null);
			item.activate += on_music_quit;
			sub.append(item);

			ret.set_submenu(sub);

			return ret;
		}

		private Gtk.MenuItem create_playlist_menu() {
			Gtk.MenuItem ret = new Gtk.MenuItem.with_mnemonic(
				_("_Playlist")
			);
			Gtk.MenuItem item;
			Gtk.ImageMenuItem img_item;
			Gtk.Image img;
			Gtk.Menu sub = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_NEW, null);
			//item.activate += on_playlist_new();
			item.sensitive = false;
			sub.append(item);

			item = new Gtk.MenuItem.with_mnemonic(
				_("_New from filter")
			);
			//item.activate += on_playlist_new_from_filter();
			item.sensitive = false;
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			img = new Gtk.Image.from_stock(
				Gtk.STOCK_ADD, Gtk.IconSize.MENU
			);

			img_item = new Gtk.ImageMenuItem.with_mnemonic(
				_("_Add filter results")
			);
			img_item.set_image(img);
			img_item.activate += on_playlist_add_filter_results;
			sub.append(img_item);

			item = new Gtk.ImageMenuItem.with_mnemonic(
				_("_Replace with filter results")
			);
			item.activate += on_playlist_replace_with_filter_results;
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			item = new Gtk.ImageMenuItem.with_mnemonic(
				_("Configure Sorting")
			);
			item.activate += on_configure_sorting;
			sub.append(item);

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_CLEAR, null);
			item.activate += on_playlist_clear;
			sub.append(item);

			item = new Gtk.ImageMenuItem.with_mnemonic(
				_("_Shuffle")
			);
			item.activate += on_playlist_shuffle;
			sub.append(item);

			ret.set_submenu(sub);

			return ret;
		}

		private Gtk.MenuItem create_help_menu() {
			Gtk.MenuItem ret = new Gtk.MenuItem.with_mnemonic(
				_("_Help")
			);
			Gtk.MenuItem item;
			Gtk.Menu sub = new Gtk.Menu();

			item = new Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ABOUT, null);
			item.activate += on_help_about;
			sub.append(item);

			ret.set_submenu(sub);

			return ret;
		}

		/* callbacks */
		private void on_music_add_file(Gtk.MenuItem item) {
			Abraca.instance().medialib.
				create_add_file_dialog(Gtk.FileChooserAction.OPEN);
		}

		private void on_music_add_dir(Gtk.MenuItem item) {
			Abraca.instance().medialib.
				create_add_file_dialog(Gtk.FileChooserAction.SELECT_FOLDER);
		}

		private void on_music_add_url(Gtk.MenuItem item) {
			Abraca.instance().medialib.create_add_url_dialog();
		}

		private void on_music_save(Gtk.MenuItem item) {
		}

		private void on_music_quit(Gtk.MenuItem item) {
			Abraca.instance().quit();
		}
		private void on_playlist_replace_with_filter_results(Gtk.MenuItem item) {
			Abraca.instance().main_window.main_hpaned.
				right_hpaned.filter_tree.playlist_replace_with_filter_results();
		}
		private void on_playlist_add_filter_results(Gtk.MenuItem item) {
			Abraca.instance().main_window.main_hpaned.
				right_hpaned.filter_tree.playlist_add_filter_results();
		}
		private void on_configure_sorting(Gtk.MenuItem item) {
			Config.instance().show_sorting_dialog();
		}
		private void on_playlist_clear(Gtk.MenuItem item) {
			Client.instance().xmms.playlist_clear(Xmms.ACTIVE_PLAYLIST);
		}
		private void on_playlist_shuffle(Gtk.MenuItem item) {
			Client.instance().xmms.playlist_shuffle(Xmms.ACTIVE_PLAYLIST);
		}

		private void on_help_about(Gtk.MenuItem item) {
			string filename;
			Gtk.AboutDialog d;
			Gdk.Pixbuf buf;

			filename = Build.Config.DATADIR + "/pixmaps/abraca.svg";
			buf = new Gdk.Pixbuf.from_file_at_scale(filename, 180, 180, true);

			d = new Gtk.AboutDialog();
			d.set_logo(buf);

			d.name = GLib.Environment.get_application_name();
			d.comments = _("A client for the XMMS2 music player");

			d.authors = _authors;
			d.artists = _artists;

			d.copyright = _("Copyright © 2007-2008 Abraca Developers");

			d.license = _license;
			d.wrap_license = true;

			d.website = "http://abraca.xmms.se/";

			d.run();
			d.hide();
		}
	}
}
