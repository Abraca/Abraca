[CCode (cprefix = "Avahi", lower_case_cprefix = "avahi_")]
namespace Avahi {
	[CCode (cheader_filename = "avahi-glib/glib-watch.h", free_function="avahi_glib_poll_free")]
	public class GLibPoll : Poll {
		public weak Avahi.Poll get ();
		public GLibPoll (GLib.MainContext context, int priority);
	}
	public static weak Avahi.Allocator glib_allocator ();
}
