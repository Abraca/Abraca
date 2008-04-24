namespace Xmms {
	class MainLoop
	{
		[CCode (cprefix = "xmmsc_mainloop_gmain_", cheader_filename = "xmmsclient/xmmsclient-glib.h")]
		public class GMain
		{
			public static void *init (Client c);
			public static void shutdown (Client c, void *p);
		}
	}

}
