using GLib;
using Gtk;

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

			item = Gtk.ImageMenuItem.from_stock("gtk-add", null);
			item.activate += on_music_add;
			sub.append(item);

			sub.append(new SeparatorMenuItem());

			item = Gtk.ImageMenuItem.from_stock("gtk-save", null);
			item.activate += on_music_save;
			sub.append(item);

			sub.append(new SeparatorMenuItem());

			item = Gtk.ImageMenuItem.from_stock("gtk-quit", null);
			item.activate += on_music_quit;
			sub.append(item);

			ret.submenu = sub;

			return ret;
		}

		private Gtk.MenuItem create_playlist_menu() {
			Gtk.MenuItem ret = Gtk.MenuItem.with_mnemonic("_Playlist");
			Gtk.MenuItem item;
			Gtk.Menu sub = new Gtk.Menu();

			item = Gtk.ImageMenuItem.from_stock("gtk-new", null);
			//item.activate += on_playlist_new();
			sub.append(item);

			item = Gtk.MenuItem.with_mnemonic("_New from filter");
			//item.activate += on_playlist_new_from_filter();
			sub.append(item);

			sub.append(new SeparatorMenuItem());

			item = Gtk.ImageMenuItem.with_mnemonic("_Add filter results");
			//item.activate += on_playlist_add_filter_results();
			sub.append(item);

			item = Gtk.ImageMenuItem.with_mnemonic("_Replace with filter results");
			//item.activate += on_playlist_replace_with_filter_results();
			sub.append(item);

			sub.append(new SeparatorMenuItem());

			item = Gtk.ImageMenuItem.from_stock("gtk-clear", null);
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

			item = Gtk.ImageMenuItem.from_stock("gtk-about", null);
			//item.activate += on_help_about();
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
			MainWindow.instance().quit();
		}
	}
}
