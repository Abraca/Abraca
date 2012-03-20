[CCode(cheader_filename="gtkosxapplication.h")]
public class Gtk.OSXApplication : GLib.Object {
	[CCode(cname="GTK_TYPE_OSX_APPLICATION")]
	public static GLib.Type GTK_TYPE_OSX_APPLICATION;

	public static OSXApplication get_instance() {
		return (Gtk.OSXApplication) GLib.Object.new(GTK_TYPE_OSX_APPLICATION);
	}
	[CCode(cname="gtk_osxapplication_set_menu_bar")]
	public void set_menu_bar(Gtk.MenuShell shell);

	[CCode(cname="gtk_osxapplication_ready")]
	public void ready();

	[CCode(cname="gtk_osxapplication_sync_menubar")]
	public void sync_menu_bar();
}
