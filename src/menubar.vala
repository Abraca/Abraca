/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class MenuBar : Gtk.MenuBar {
		construct {
			append(create_music_menu());
			append(create_playlist_menu());
			append(create_help_menu());
		}

		private Gtk.MenuItem create_music_menu() {
			Gtk.MenuItem ret = Gtk.MenuItem.with_mnemonic("_Music");
			Gtk.MenuItem item;
			Gtk.Menu sub = new Gtk.Menu();

			item = Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ADD, null);
			item.activate += on_music_add;
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			item = Gtk.ImageMenuItem.from_stock(Gtk.STOCK_SAVE, null);
			item.activate += on_music_save;
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			item = Gtk.ImageMenuItem.from_stock(Gtk.STOCK_QUIT, null);
			item.activate += on_music_quit;
			sub.append(item);

			ret.submenu = sub;

			return ret;
		}

		private Gtk.MenuItem create_playlist_menu() {
			Gtk.MenuItem ret = Gtk.MenuItem.with_mnemonic("_Playlist");
			Gtk.MenuItem item;
			Gtk.Menu sub = new Gtk.Menu();

			item = Gtk.ImageMenuItem.from_stock(Gtk.STOCK_NEW, null);
			//item.activate += on_playlist_new();
			sub.append(item);

			item = Gtk.MenuItem.with_mnemonic("_New from filter");
			//item.activate += on_playlist_new_from_filter();
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			item = Gtk.ImageMenuItem.with_mnemonic("_Add filter results");
			//item.activate += on_playlist_add_filter_results();
			sub.append(item);

			item = Gtk.ImageMenuItem.with_mnemonic("_Replace with filter results");
			//item.activate += on_playlist_replace_with_filter_results();
			sub.append(item);

			sub.append(new Gtk.SeparatorMenuItem());

			item = Gtk.ImageMenuItem.from_stock(Gtk.STOCK_CLEAR, null);
			//item.activate += on_playlist_clear();
			sub.append(item);

			item = Gtk.ImageMenuItem.with_mnemonic("_Shuffle");
			//item.activate += on_playlist_shuffle();
			sub.append(item);

			ret.submenu = sub;

			return ret;
		}

		private Gtk.MenuItem create_help_menu() {
			Gtk.MenuItem ret = Gtk.MenuItem.with_mnemonic("_Help");
			Gtk.MenuItem item;
			Gtk.Menu sub = new Gtk.Menu();

			item = Gtk.ImageMenuItem.from_stock(Gtk.STOCK_ABOUT, null);
			item.activate += on_help_about;
			sub.append(item);

			ret.submenu = sub;

			return ret;
		}

		/* callbacks */
		private void on_music_add(Gtk.MenuItem item) {
		}

		private void on_music_save(Gtk.MenuItem item) {
		}

		private void on_music_quit(Gtk.MenuItem item) {
			Abraca.instance().quit();
		}

		private void on_help_about(Gtk.MenuItem item) {
			Gtk.AboutDialog d = new Gtk.AboutDialog();

			d.name = Environment.get_application_name();
			d.comments = "A client for the XMMS2 music player";

			d.authors = new string[] {
				"Sebastian Sareyko <smoon@nooms.de>",
				"Martin Salzer <stoky@gmx.net>",
				null
			};

			d.copyright = "Copyright © 2007 Sebastian Sareyko";
			d.website = "http://nooms.de/projects/abraca/";

			d.run();
			d.hide();
		}
	}
}
