[CCode (cheader_filename="src/components/server/zeroconf/dmap-mdns-browser.h")]
namespace DMAP {
	public errordomain MdnsBrowserError {
		NOT_RUNNING, FAILED
	}

	public enum MdnsBrowserServiceType {
		INVALID = 0,
		DAAP,
		DPAP,
		DACP,
		RAOP,
		XMMS2
	}

	public enum MdnsBrowserTransportProtocol {
		TCP,
		UDP
	}

	[Compact]
	public struct MdnsBrowserService {
		public string service_name;
		public string name;
		public string host;
		public uint port;
		public bool password_protected;
		public string pair;
		public MdnsBrowserTransportProtocol transport_protocol;
	}

	public class MdnsBrowser : GLib.Object {
		public signal void service_added (MdnsBrowserService service);
		public signal void service_removed (MdnsBrowserService service);

		public MdnsBrowser (MdnsBrowserServiceType service_type);
		public bool start () throws MdnsBrowserError;
		public bool stop () throws MdnsBrowserError;

		public unowned GLib.SList<unowned MdnsBrowserService> get_services ();
		MdnsBrowserServiceType get_service_type ();
	}
}
