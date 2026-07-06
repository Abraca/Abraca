/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2014 Abraca Team
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

public class Abraca.Application : Adw.Application {
	private Window window;

	/* Held so the browser (and its in-flight async discovery) outlives the
	 * dialog closing; otherwise a late async callback derefs a freed instance. */
	private ServerBrowser server_browser;

	private const ActionEntry[] actions = {
		{ "about", on_menu_about },
		{ "quit", on_menu_quit }
	};

	public Application()
	{
		Object(application_id: "org.xmms2.abraca", flags: ApplicationFlags.DEFAULT_FLAGS);
		add_action_entries (actions, this);
	}

	private void on_menu_about ()
	{
		var about = new Adw.AboutDialog () {
			application_name = "Abraca",
			application_icon = "org.xmms2.abraca",
			version = Build.Config.VERSION,
			website = "https://github.com/Abraca/Abraca",
			copyright = "© 2007-2020 Abraca Team",
			license_type = Gtk.License.GPL_2_0,
			developers = About.developers,
			artists = About.artists,
			translator_credits = string.joinv ("\n", About.translators)
		};

		about.present (window);
	}

	private void on_menu_quit ()
	{
		Configurable.save();
		quit();
	}

	protected override void activate ()
	{
		unowned List<Gtk.Window> windows = get_windows();

		if (windows != null)
			return;

		var client = new Client();

		var builder = new Gtk.Builder ();

		try {
			builder.add_from_resource("/org/xmms2/Abraca/ui/abraca-main-menu.ui");

			var menu = builder.get_object("win-menu") as MenuModel;

			window = new Window(this, client, menu);

			Configurable.load();

			var provider = new Gtk.CssProvider();
			provider.load_from_resource("/org/xmms2/Abraca/ui/style.css");

			Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider,
			                                          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

			window.present ();

			GLib.Idle.add(() => {
				server_browser = new ServerBrowser(window, client);
				server_browser.run();
				return false;
			});
		} catch (GLib.Error e) {
			GLib.error("%s", e.message);
		}

		base.activate();
	}

	protected override void shutdown ()
	{
		base.shutdown();
	}

	public static int main (string[] args)
	{
		GLib.Environment.set_application_name("Abraca");

		GLib.Intl.textdomain(Build.Config.APPNAME);
		GLib.Intl.bindtextdomain(Build.Config.APPNAME, Build.Config.LOCALEDIR);
		GLib.Intl.bind_textdomain_codeset(Build.Config.APPNAME, "UTF-8");

		var app = new Abraca.Application();

		return app.run(args);
	}
}
