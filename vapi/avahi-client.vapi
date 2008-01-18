[CCode (cprefix = "Avahi", lower_case_cprefix = "avahi_", cheader_filename="avahi-client/client.h")]
namespace Avahi {

	[CCode (cprefix = "AVAHI_BROWSER_", cheader_filename = "avahi-client/client.h")]
	public enum BrowserEvent {
		NEW,
		REMOVE,
		CACHE_EXHAUSTED,
		ALL_FOR_NOW,
		FAILURE,
	}

	[CCode (cprefix = "AVAHI_CLIENT_", cheader_filename = "avahi-client/client.h")]
	public enum ClientFlags {
		IGNORE_USER_CONFIG,
		NO_FAIL,
	}

	[CCode (cprefix = "AVAHI_CLIENT_", cheader_filename = "avahi-client/client.h")]
	public enum ClientState {
		S_REGISTERING,
		S_RUNNING,
		S_COLLISION,
		FAILURE,
		CONNECTING,
	}

	[CCode (cprefix = "AVAHI_DOMAIN_BROWSER_", cheader_filename = "avahi-client/client.h")]
	public enum DomainBrowserType {
		BROWSE,
		BROWSE_DEFAULT,
		REGISTER,
		REGISTER_DEFAULT,
		BROWSE_LEGACY,
		MAX,
	}

	[CCode (cprefix = "AVAHI_ENTRY_GROUP_", cheader_filename = "avahi-client/client.h")]
	public enum EntryGroupState {
		UNCOMMITED,
		REGISTERING,
		ESTABLISHED,
		COLLISION,
		FAILURE,
	}

	[CCode (cprefix = "AVAHI_LOOKUP_", cheader_filename = "avahi-client/client.h")]
	public enum LookupFlags {
		USE_WIDE_AREA,
		USE_MULTICAST,
		NO_TXT,
		NO_ADDRESS,
	}

	[CCode (cprefix = "AVAHI_LOOKUP_RESULT_", cheader_filename = "avahi-client/client.h")]
	public enum LookupResultFlags {
		CACHED,
		WIDE_AREA,
		MULTICAST,
		LOCAL,
		OUR_OWN,
		STATIC,
	}

	[CCode (cprefix = "AVAHI_PUBLISH_", cheader_filename = "avahi-client/client.h")]
	public enum PublishFlags {
		UNIQUE,
		NO_PROBE,
		NO_ANNOUNCE,
		ALLOW_MULTIPLE,
		NO_REVERSE,
		NO_COOKIE,
		UPDATE,
		USE_WIDE_AREA,
		USE_MULTICAST,
	}

	[CCode (cprefix = "AVAHI_RESOLVER_", cheader_filename = "avahi-client/client.h")]
	public enum ResolverEvent {
		FOUND,
		FAILURE,
	}

	[CCode (cprefix = "AVAHI_SERVER_", cheader_filename = "avahi-client/client.h")]
	public enum ServerState {
		INVALID,
		REGISTERING,
		RUNNING,
		COLLISION,
		FAILURE,
	}

	[CCode (cprefix = "AVAHI_WATCH_", cheader_filename = "avahi-client/client.h")]
	public enum WatchEvent {
		IN,
		OUT,
		ERR,
		HUP,
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class Address {
		[CCode(cprefix="ADDRESS_")]
		public const int STR_MAX;

		public weak Avahi.Protocol proto;
		public pointer data;
		public int cmp (Avahi.Address b);
		public static weak Avahi.Address parse (string s, Avahi.Protocol af,
		                                        Avahi.Address ret_addr);
		public static weak string snprint (string ret_s, ulong length,
		                                   Avahi.Address a);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class AddressResolver {
		public weak Avahi.Client get_client ();
		public AddressResolver (Avahi.Client client,
		                        Avahi.IfIndex iface,
		                        Avahi.Protocol protocol,
		                        Avahi.Address a,
		                        Avahi.LookupFlags flags,
		                        Avahi.AddressResolverCallback callback,
		                        pointer userdata);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class Allocator {
		public GLib.Callback malloc;
		public GLib.Callback free;
		public GLib.Callback realloc;
		public GLib.Callback calloc;
	}

	[CCode (cheader_filename = "avahi-client/client.h", free_function="avahi_client_free")]
	public class Client {
		public int errno ();
		public weak string get_domain_name ();
		public weak string get_host_name ();
		public weak string get_host_name_fqdn ();
		public uint get_local_service_cookie ();
		public Avahi.ClientState get_state ();
		public weak string get_version_string ();
		public Client (Avahi.Poll poll_api, Avahi.ClientFlags flags,
		               Avahi.ClientCallback callback, pointer userdata, int error);
		public int set_host_name (string name);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class DomainBrowser {
		public weak Avahi.Client get_client ();
		public DomainBrowser (Avahi.Client client, Avahi.IfIndex iface,
		                      Avahi.Protocol protocol, string domain,
		                      Avahi.DomainBrowserType btype,
		                      Avahi.LookupFlags flags,
		                      Avahi.DomainBrowserCallback callback,
		                      pointer userdata);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class EntryGroup {
		public EntryGroup (Avahi.Client c,
		                   Avahi.EntryGroupCallback callback,
		                   pointer userdata);
		public int add_address (Avahi.IfIndex iface,
		                        Avahi.Protocol protocol,
		                        Avahi.PublishFlags flags,
		                        string name, Avahi.Address a);
		public int add_record (Avahi.IfIndex iface,
		                       Avahi.Protocol protocol,
		                       Avahi.PublishFlags flags,
		                       string name, ushort clazz,
		                       ushort type, uint ttl,
		                       pointer rdata, ulong size);
		public int add_service (Avahi.IfIndex iface,
		                        Avahi.Protocol protocol,
		                        Avahi.PublishFlags flags,
		                        string name, string type,
		                        string domain, string host,
		                        ushort port);
		public int add_service_strlst (Avahi.IfIndex iface,
		                               Avahi.Protocol protocol,
		                               Avahi.PublishFlags flags,
		                               string name, string type,
		                               string domain, string host,
		                               ushort port, Avahi.StringList txt);
		public int add_service_subtype (Avahi.IfIndex iface,
		                                Avahi.Protocol protocol,
		                                Avahi.PublishFlags flags,
		                                string name, string type,
		                                string domain, string subtype);
		public int commit ();
		public weak Avahi.Client get_client ();
		public int get_state ();
		public int is_empty ();
		public int reset ();
		public int update_service_txt (Avahi.IfIndex iface,
		                               Avahi.Protocol protocol,
		                               Avahi.PublishFlags flags,
		                               string name, string type,
		                               string domain);
		public int update_service_txt_strlst (Avahi.IfIndex iface,
		                                      Avahi.Protocol protocol,
		                                      Avahi.PublishFlags flags,
		                                      string name, string type,
		                                      string domain,
		                                      Avahi.StringList strlst);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class HostNameResolver {
		public weak Avahi.Client get_client ();
		public HostNameResolver (Avahi.Client client,
		                         Avahi.IfIndex iface,
		                         Avahi.Protocol protocol,
		                         string name,
		                         Avahi.Protocol aprotocol,
		                         Avahi.LookupFlags flags,
		                         Avahi.HostNameResolverCallback callback,
		                         pointer userdata);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public struct IPv4Address {
		public uint address;
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public struct IPv6Address {
		public weak uchar[] address;
	}

	[CCode (cprefix="AVAHI_IF_", cheader_filename = "avahi-client/client.h")]
	public enum IfIndex {
		UNSPEC = -1
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public abstract class Poll {
		public pointer userdata;
		public GLib.Callback watch_new;
		public GLib.Callback watch_update;
		public GLib.Callback watch_get_events;
		public GLib.Callback watch_free;
		public GLib.Callback timeout_new;
		public GLib.Callback timeout_update;
		public GLib.Callback timeout_free;
	}

	[CCode (cprefix="AVAHI_PROTO_", cheader_filename = "avahi-client/client.h")]
	public enum Protocol {
		INET = 0,
		INET6 = 1,
		UNSPEC = -1
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class RList {
		public weak Avahi.RList rlist_next;
		public weak Avahi.RList rlist_prev;
		public pointer data;
		public weak Avahi.RList prepend (pointer data);
		public weak Avahi.RList remove (pointer data);
		public weak Avahi.RList remove_by_link (Avahi.RList n);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class RecordBrowser {
		public weak Avahi.Client get_client ();
		public RecordBrowser (Avahi.Client client,
		                      Avahi.IfIndex iface,
		                      Avahi.Protocol protocol,
		                      string name, ushort clazz,
		                      ushort type,
		                      Avahi.LookupFlags flags,
		                      Avahi.RecordBrowserCallback callback,
		                      pointer userdata);
	}

	[CCode (cheader_filename = "avahi-client/lookup.h")]
	public class ServiceBrowser {
		public weak Avahi.Client get_client ();
		public ServiceBrowser (Avahi.Client client,
		                       Avahi.IfIndex iface,
		                       Avahi.Protocol protocol,
		                       string type, string domain,
		                       Avahi.LookupFlags flags,
		                       Avahi.ServiceBrowserCallback callback,
		                       pointer userdata);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class ServiceResolver {
		public weak Avahi.Client get_client ();
		public ServiceResolver (Avahi.Client client,
		                        Avahi.IfIndex iface,
		                        Avahi.Protocol protocol,
		                        string name, string type,
		                        string domain,
		                        Avahi.Protocol aprotocol,
		                        Avahi.LookupFlags flags,
		                        Avahi.ServiceResolverCallback callback,
		                        pointer userdata);
	}
	[CCode (cheader_filename = "avahi-client/client.h")]
	public class ServiceTypeBrowser {
		public weak Avahi.Client get_client ();
		public ServiceTypeBrowser (Avahi.Client client,
		                           Avahi.IfIndex iface,
		                           Avahi.Protocol protocol,
		                           string domain,
		                           Avahi.LookupFlags flags,
		                           Avahi.ServiceTypeBrowserCallback callback,
		                           pointer userdata);
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class SimplePoll {
		public int dispatch ();

		public weak Avahi.Poll get ();
		public int iterate (int sleep_time);
		public int loop ();
		public SimplePoll ();
		public int prepare (int timeout);
		public void quit ();
		public int run ();
		public void set_func (Avahi.PollFunc func, pointer userdata);
		public void wakeup ();
	}

	[CCode (copy_function = "avahi_string_list_copy", cheader_filename = "avahi-client/client.h")]
	public class StringList {
		public pointer next;
		public ulong size;
		public weak uchar[] text;
		public weak Avahi.StringList add (string text);
		public weak Avahi.StringList add_anonymous (ulong size);
		public weak Avahi.StringList add_arbitrary (uchar text, ulong size);
		public weak Avahi.StringList add_many ();
		public weak Avahi.StringList add_many_va (pointer va);
		public weak Avahi.StringList add_pair (string key, string val);
		public weak Avahi.StringList add_pair_arbitrary (string key, uchar val, ulong size);
		public weak Avahi.StringList add_printf (string format);
		public weak Avahi.StringList add_vprintf (string format, pointer va);
		public weak Avahi.StringList copy ();
		public int equal (Avahi.StringList b);
		public weak Avahi.StringList find (string key);
		public weak Avahi.StringList get_next ();
		public int get_pair (out string key, out string val, ulong size);
		public uint get_service_cookie ();
		public ulong get_size ();
		public uchar get_text ();
		public uint length ();
		public StringList (string txt);
		public StringList.from_array (out string array, int length);
		public StringList.va (pointer va);
		public static int parse (pointer data, ulong size, out Avahi.StringList ret);
		public weak Avahi.StringList reverse ();
		public ulong serialize (pointer data, ulong size);
		public weak string to_string ();
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class ThreadedPoll {
		public weak Avahi.Poll get ();
		public void @lock ();
		public ThreadedPoll ();
		public void quit ();
		public int start ();
		public int stop ();
		public void unlock ();
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class Timeout {
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class Usec {
	}

	[CCode (cheader_filename = "avahi-client/client.h")]
	public class Watch {
	}

	public static delegate void AddressResolverCallback (
		Avahi.AddressResolver r, Avahi.IfIndex iface,
		Avahi.Protocol protocol, Avahi.ResolverEvent event,
		Avahi.Address a, string name, Avahi.LookupResultFlags flags,
		pointer userdata);

	public static delegate void ClientCallback (
		Avahi.Client s, Avahi.ClientState state, pointer userdata);

	public static delegate void DomainBrowserCallback (
		Avahi.DomainBrowser b, Avahi.IfIndex iface,
		Avahi.Protocol protocol, Avahi.BrowserEvent event,
		string domain, Avahi.LookupResultFlags flags, pointer userdata);

	public static delegate void EntryGroupCallback (
		Avahi.EntryGroup g, Avahi.EntryGroupState state, pointer userdata);

	public static delegate void HostNameResolverCallback (
		Avahi.HostNameResolver r, Avahi.IfIndex iface,
		Avahi.Protocol protocol, Avahi.ResolverEvent event,
		string name, Avahi.Address a, Avahi.LookupResultFlags flags,
		pointer userdata);

	public static delegate int PollFunc (
		pointer ufds, uint nfds, int timeout, pointer userdata);

	public static delegate void RecordBrowserCallback (
		Avahi.RecordBrowser b, Avahi.IfIndex iface,
		Avahi.Protocol protocol, Avahi.BrowserEvent event,
		string name, ushort clazz, ushort type, pointer rdata,
		ulong size, Avahi.LookupResultFlags flags, pointer userdata);

	public static delegate void ServiceBrowserCallback (
		Avahi.ServiceBrowser b, Avahi.IfIndex iface,
		Avahi.Protocol protocol, Avahi.BrowserEvent event,
		string name, string type, string domain,
		Avahi.LookupResultFlags flags, pointer userdata);

	[CCode(cheader_filename="avahi-client/lookup.h")]
	public static delegate void ServiceResolverCallback (
		Avahi.ServiceResolver r, Avahi.IfIndex iface,
		Avahi.Protocol protocol, Avahi.ResolverEvent event,
		string name, string type, string domain, string host_name,
		Avahi.Address a, uint16 port, Avahi.StringList txt,
		Avahi.LookupResultFlags flags, pointer userdata);

	public static delegate void ServiceTypeBrowserCallback (
		Avahi.ServiceTypeBrowser b, Avahi.IfIndex iface,
		Avahi.Protocol protocol, Avahi.BrowserEvent event,
		string type, string domain, Avahi.LookupResultFlags flags,
		pointer userdata);

	public static delegate void TimeoutCallback (
		Avahi.Timeout t, pointer userdata);

	public static delegate void WatchCallback (
		Avahi.Watch w, int fd, Avahi.WatchEvent event, pointer userdata);

	public const int DEFAULT_TTL;
	public const int DEFAULT_TTL_HOST_NAME;
	public const int DOMAIN_NAME_MAX;
	public const int LABEL_MAX;
	public const string SERVICE_COOKIE;
	public const int SERVICE_COOKIE_INVALID;
	public static weak Avahi.Protocol af_to_proto (int af);
	public static weak Avahi.Usec age (pointer a);
	public static weak string alternative_host_name (string s);
	public static weak string alternative_service_name (string s);
	public static int domain_equal (string a, string b);
	public static uint domain_hash (string name);
	public static pointer elapse_time (pointer tv, uint ms, uint j);
	public static weak string escape_label (string src, ulong src_length,
	                                        out string ret_name, ulong ret_size);
	public static void free (pointer p);
	public static weak string get_type_from_subtype (string t);
	public static int is_valid_domain_name (string t);
	public static int is_valid_fqdn (string t);
	public static int is_valid_host_name (string t);
	public static int is_valid_service_name (string t);
	public static int is_valid_service_subtype (string t);
	public static int is_valid_service_type_generic (string t);
	public static int is_valid_service_type_strict (string t);
	public static pointer malloc (ulong size);
	public static pointer malloc0 (ulong size);
	public static pointer memdup (pointer s, ulong l);
	public static weak string normalize_name (string s, string ret_s, ulong size);
	public static weak string normalize_name_strdup (string s);
	public static int nss_support ();
	public static int proto_to_af (Avahi.Protocol proto);
	public static weak string proto_to_string (Avahi.Protocol proto);
	public static pointer realloc (pointer p, ulong size);
	public static weak string reverse_lookup_name (Avahi.Address a,
	                                               string ret_s, ulong length);
	public static int service_name_join (string p, ulong size,
	                                     string name, string type,
	                                     string domain);
	public static int service_name_split (string p, string name,
	                                      ulong name_size, string type,
	                                      ulong type_size, string domain,
	                                      ulong domain_size);
	public static void set_allocator (Avahi.Allocator a);
	public static weak string strdup (string s);
	public static weak string strdup_printf (string fmt);
	public static weak string strdup_vprintf (string fmt, pointer ap);
	public static weak string strerror (int error);
	public static weak string strndup (string s, ulong l);
	public static pointer timeval_add (pointer a, Avahi.Usec usec);
	public static int timeval_compare (pointer a, pointer b);
	public static weak Avahi.Usec timeval_diff (pointer a, pointer b);
	public static weak string unescape_label (out string name, string dest,
	                                          ulong size);
}
