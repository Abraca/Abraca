[CCode(cprefix="", cheader_filename = "build-config.h")]
namespace Build {
	[CCode(cprefix="")]
	public class Config {
		public const string APPNAME;
		public const string VERSION;
		public const string DATADIR;
		public const string LOCALEDIR;
	}
}
