/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2012 Abraca Team
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

public class Abraca.Application : Gtk.Application {
	private const int IDLE_INTERVAL = 3;
	private const int IDLE_DELAY = 20;

	private time_t idle_last_event = 0;
	private uint idle_handler = 0;

	private MainWindow window;

	public signal void application_timeout ();

	private const ActionEntry[] actions = {
		{ "about", on_menu_about },
		{ "quit", on_menu_quit }
	};

	public Application()
	{
		Object(application_id: "org.xmms2.abraca", flags: ApplicationFlags.FLAGS_NONE);
		add_action_entries (actions, this);
		gdk_window_add_filter (null, on_gdk_event);
	}

	private Gdk.FilterReturn on_gdk_event (Gdk.XEvent xev, Gdk.Event ev)
	{
		idle_last_event = time_t();
		if (idle_handler == 0)
			idle_handler = GLib.Timeout.add_seconds(IDLE_INTERVAL, on_timeout_tickle);
		return Gdk.FilterReturn.CONTINUE;
	}

	private bool on_timeout_tickle ()
	{
		if ((idle_last_event + IDLE_DELAY) < time_t()) {
			idle_handler = 0;
			application_timeout();
			return false;
		}
		return true;
	}

	private void on_menu_about ()
	{
		try {
			var builder = new Gtk.Builder();

			builder.add_from_resource("/org/xmms2/Abraca/ui/about.xml");

			var about = builder.get_object("abraca_about") as Gtk.AboutDialog;

			about.set_logo(new Gdk.Pixbuf.from_resource("/org/xmms2/Abraca/abraca-192.png"));
			about.version = Build.Config.VERSION;

			about.transient_for = window;

			about.run();
			about.hide();
		} catch (GLib.Error e) {
			GLib.error("About dialog could not be shown. (%s)", e.message);
		}
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
			builder.add_from_resource("/org/xmms2/Abraca/ui/main_menu.xml");

			app_menu = builder.get_object ("app-menu") as MenuModel;
			menubar = builder.get_object("win-menu") as MenuModel;

			window = new MainWindow(this, client);

			Configurable.load();

			window.show_all ();

			if (!client.try_connect())
				GLib.Timeout.add(500, client.reconnect);

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
		var context = new OptionContext (_("- Abraca, an XMMS2 client."));
		context.add_group (Gtk.get_option_group (false));

		try {
			context.parse (ref args);
		} catch (GLib.OptionError err) {
			var help = context.get_help (true, null);
			GLib.print ("%s\n%s", err.message, help);
			Posix.exit (1);
		}

		try {
			create_icon_factory().add_default();
		} catch (GLib.Error e) {
			GLib.error(e.message);
		}

		GLib.Environment.set_application_name("Abraca");

		GLib.Intl.textdomain(Build.Config.APPNAME);
		GLib.Intl.bindtextdomain(Build.Config.APPNAME, Build.Config.LOCALEDIR);
		GLib.Intl.bind_textdomain_codeset(Build.Config.APPNAME, "UTF-8");

		var app = new Abraca.Application();

		return app.run();
	}
}
