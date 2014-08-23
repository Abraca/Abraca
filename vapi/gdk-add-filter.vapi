namespace Abraca {
	[CCode(cname="gdk_window_add_filter", cheader_filename="gdk/gdk.h")]
	public static void gdk_window_add_filter (Gdk.Window? window, Gdk.FilterFunc func);
}
