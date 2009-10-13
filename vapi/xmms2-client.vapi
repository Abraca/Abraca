[CCode(cheader_filename = "xmmsclient/xmmsclient.h")]
namespace Xmms {
	[CCode(cprefix="XMMS_COLLECTION_CHANGED_")]
	public enum CollectionChanged {
		ADD,
		UPDATE,
		RENAME,
		REMOVE,
	}

	[CCode(cprefix="XMMS_MEDIAINFO_READER_STATUS_")]
	public enum ReaderStatus {
		IDLE,
		RUNNING,
	}

	[CCode(cprefix="XMMS_PLAYBACK_STATUS_")]
	public enum PlaybackStatus {
		STOP,
		PLAY,
		PAUSE,
	}

	[CCode(cprefix="XMMS_PLAYLIST_CHANGED_")]
	public enum PlaylistChange {
		ADD,
		INSERT,
		SHUFFLE,
		REMOVE,
		CLEAR,
		MOVE,
		SORT,
		UPDATE,
	}


	[CCode(cprefix="XMMS_PLUGIN_TYPE_")]
	public enum PluginType {
		ALL,
		OUTPUT,
		XFORM,
	}

	[CCode(cprefix="XMMS_COLLECTION_TOKEN_")]
	public enum CollectionTokenType {
		INVALID,
		GROUP_OPEN,
		GROUP_CLOSE,
		REFERENCE,
		SYMBOL_ID,
		STRING,
		PATTERN,
		INTEGER,
		SEQUENCE,
		PROP_LONG,
		PROP_SHORT,
		OPSET_UNION,
		OPSET_INTERSECTION,
		OPSET_COMPLEMENT,
		OPFIL_HAS,
		OPFIL_EQUALS,
		OPFIL_MATCH,
		OPFIL_SMALLER,
		OPFIL_GREATER,
		OPFIL_SMALLEREQ,
		OPFIL_GREATEREQ,
	}

	[CCode(cprefix="XMMS_COLLECTION_TYPE_")]
	public enum CollectionType {
		REFERENCE,
		UNION,
		INTERSECTION,
		COMPLEMENT,
		HAS,
		EQUALS,
		MATCH,
		SMALLER,
		GREATER,
		IDLIST,
		QUEUE,
		PARTYSHUFFLE,
	}

	[CCode(cprefix="XMMS_MEDIALIB_ENTRY_STATUS_")]
	public enum EntryStatus {
		NEW,
		OK,
		RESOLVING,
		NOT_AVAILABLE,
		REHASH,
	}

	[CCode(cprefix="XMMSC_RESULT_CLASS_")]
	public enum ResultType {
		DEFAULT,
		SIGNAL,
		BROADCAST,
	}

	[CCode(cprefix="XMMSV_TYPE_", cname="xmmsv_type_t")]
	public enum ValueType {
		NONE = 0,
		ERROR,
		INT32,
		STRING,
		COLL,
		BIN,
		LIST,
		DICT,
		END,
	}

	[CCode(cname="xmmsc_disconnect_func_t")]
	public delegate void DisconnectFunc ();

	[CCode(cname="xmmsv_list_foreach_func")]
	public delegate void ListForeachFunc (Xmms.Value val);

	[CCode(cname="xmmsv_dict_foreach_func")]
	public delegate void DictForeachFunc (string key, Xmms.Value val);

	[CCode(cname="xmmsc_result_notifier_t")]
	public delegate bool NotifierFunc (Xmms.Value val);

	[CCode(cname="xmmsc_user_data_free_func_t")]
	public delegate void UserDataFreeFunc (void *obj);

	[CCode(cname="xmmsc_coll_parse_tokens_f")]
	public delegate CollectionToken CollectionParseTokensFunc (string key, string[] npos);

	[CCode(cname="xmmsc_coll_parse_build_f")]
	public delegate Collection CollectionParseBuildFunc (CollectionToken[] t);

	[CCode(cname="xmmsc_coll_attribute_foreach_func")]
	public delegate void CollectionAttributeForeachFunc (string key, string val);

	public const string ACTIVE_PLAYLIST;
	public const string COLLECTION_NS_ALL;
	public const string COLLECTION_NS_COLLECTIONS;
	public const string COLLECTION_NS_PLAYLISTS;

	[Compact]
	[CCode (cname="xmmsc_coll_token_t")]
	public class CollectionToken {
			public Xmms.CollectionTokenType type;
			[CCode(cname="string")]
			public string str;
			public unowned CollectionToken next;
	}

	[Compact]
	[CCode (cname="xmmsc_connection_t",	cprefix="xmmsc_", ref_function="xmmsc_ref", unref_function="xmmsc_unref")]
	public class Client
	{
		[CCode (cname="xmmsc_init")]
		public Client(string name);
		public bool connect (string? path=null);

		/*
		 * Playback functions
		 */
		public Result playback_stop();
		public Result playback_tickle();
		public Result playback_start();
		public Result playback_pause();
		public Result playback_current_id();
		public Result playback_seek_ms(uint milliseconds);
		public Result playback_seek_ms_rel(int milliseconds);
		public Result playback_seek_samples(uint samples);
		public Result playback_seek_samples_rel(int samples);
		public Result playback_playtime();
		public Result playback_status();
		public Result playback_volume_set(string channel, uint volume);
		public Result playback_volume_get();
		public Result broadcast_playback_volume_changed();
		public Result broadcast_playback_status();
		public Result broadcast_playback_current_id();
		public Result signal_playback_playtime();

		/*
		 * Playlist functions
		 */
		public Result playlist_list();
		public Result playlist_create(string playlist);
		public Result playlist_shuffle(string playlist);
		public Result playlist_add_args(string playlist, string url, int len, string[] args);
		public Result playlist_add_url(string playlist, string url);
		public Result playlist_add_id(string playlist, uint id);
		public Result playlist_add_encoded(string playlist, string url);
		public Result playlist_add_idlist(string playlist, Collection coll);
		[NoArrayLength]
		public Result playlist_add_collection(string playlist, Collection coll, Xmms.Value? order);
		public Result playlist_remove_entry(string playlist, uint id);
		public Result playlist_clear(string playlist);
		public Result playlist_remove(string playlist);
		public Result playlist_list_entries(string playlist = "Default");
		[NoArrayLength]
		public Result playlist_sort(string playlist, Xmms.Value order);
		public Result playlist_set_next(uint pos);
		public Result playlist_set_next_rel(int pos);
		public Result playlist_move_entry(string playlist, uint from, uint to);
		public Result playlist_current_pos(string playlist);
		public Result playlist_current_active();
		public Result playlist_insert_args(string playlist, int pos, string url, int numargs, string[] args);
		public Result playlist_insert_url(string playlist, int pos, string url);
		public Result playlist_insert_id(string playlist, int pos, uint id);
		public Result playlist_insert_encoded(string playlist, int pos, string url);
		[NoArrayLength]
		public Result playlist_insert_collection(string playlist, int pos, Xmms.Collection coll, Xmms.Value? order);
		public Result playlist_load(string playlist);
		public Result playlist_radd(string playlist, string url);
		public Result playlist_radd_encoded(string playlist, string url);
		public Result broadcast_playlist_changed();
		public Result broadcast_playlist_current_pos();
		public Result broadcast_playlist_loaded();

		/*
		 * Medialib functions
		 */
		public Result medialib_add_entry(string url);
		public Result medialib_add_entry_args(string url, int numargs, string[] args);
		public Result medialib_add_entry_encoded(string url);
		public Result medialib_get_info(uint id);
		public Result medialib_path_import(string path);
		public Result medialib_path_import_encoded(string path);
		public Result medialib_rehash(uint id);
		public Result medialib_get_id(string url);
		public Result medialib_remove_entry(uint entry);
		public Result medialib_move_entry(uint entry, string url);
		public Result medialib_entry_property_set_int(uint id, string key, int val);
		public Result medialib_entry_property_set_int_with_source(uint id, string source, string key, int val);
		public Result medialib_entry_property_set_str(uint id, string key, string val);
		public Result medialib_entry_property_set_str_with_source(uint id, string source, string key, string val);
		public Result medialib_entry_property_remove(uint id, string key);
		public Result medialib_entry_property_remove_with_source(uint id, string source, string key);
		public Result broadcast_medialib_entry_changed();
		public Result broadcast_medialib_entry_added();
		public Result broadcast_mediainfo_reader_status();
		public Result signal_mediainfo_reader_unindexed();

		/*
		 * Config functions
		 */
		public Result configval_set(string key, string val);
		public Result configval_list();
		public Result configval_get(string key);
		public Result configval_register(string valuename, string defaultvalue);
		public Result broadcast_configval_changed();

		/*
		 * Browse functions
		 */
		public Result xform_media_browse(string url);
		public Result xform_media_browse_encoded(string url);

		/*
		 * Bindata functions
		 */
		public Result bindata_add (uchar[] data);
		public Result bindata_retrieve(string hash);
		public Result bindata_remove(string hash);

		/*
		 * Collection functions
		 */
		public Result coll_get(string collname, string ns);
		public Result coll_list(string ns);
		public Result coll_save(Collection c, string name, string ns);
		public Result coll_remove(string name, string ns);
		public Result coll_find(uint mediaid, string ns);
		public Result coll_rename(string from_name, string to_name, string ns);
		public Result coll_idlist_from_playlist_file(string path);
		public Result coll_sync();
		[NoArrayLength]
		public Result coll_query_ids(Collection coll, Xmms.Value order, uint limit_start = 0, uint limit_len = 0);
		[NoArrayLength]
		public Result coll_query_infos(Collection coll, Xmms.Value order, uint limit_start = 0, uint limit_len = 0, Xmms.Value? fetch = null, Xmms.Value? group = null);
		public Result broadcast_collection_changed();

		/*
		 * Other functions
		 */
		public static int entry_format (string target, int len, string fmt, Xmms.Value val);
		public static unowned string userconfdir_get (char[] buffer);
		public string get_last_error ();
		public Result quit();
		public Result broadcast_quit ();
		public void disconnect_callback_set (DisconnectFunc func);
		public void disconnect_callback_set_full (DisconnectFunc func, UserDataFreeFunc ufunc);
		public Result plugin_list (Xmms.PluginType type = Xmms.PluginType.ALL);
		public Result main_stats ();
		public Result signal_visualisation_data ();
	}

	[Compact]
	[CCode(cname="xmmsv_coll_t", cprefix="xmmsv_coll_", ref_function="xmmsv_coll_ref", unref_function="xmmsv_coll_unref")]
	public class Collection {
		[CCode (cname = "xmmsc_coll_new")]
		public Collection(CollectionType type);
		[NoArrayLength]
		public void set_idlist(uint[] ids);
		public void add_operand(Collection op);
		public void remove_operand(Collection op);

		public bool idlist_append(uint id);
		public bool idlist_insert(uint index, uint id);
		public bool idlist_move(uint index, uint newindex);
		public bool idlist_remove(uint index);
		public bool idlist_clear();
		public bool idlist_get_index(uint index, out int val);
		public bool idlist_set_index(uint index, uint val);
		public uint idlist_get_size();

		public CollectionType get_type();
		public uint[] get_idlist();

		public bool operand_list_first();
		public bool operand_list_valid();
		public bool operand_list_entry(out Collection operand);
		public bool operand_list_next();
		public bool operand_list_save();
		public bool operand_list_restore();
		public void operand_list_clear();

		public void attribute_list_first();
		public bool attribute_list_valid();
		public void attribute_list_entry(out unowned string key, out unowned string val);
		public void attribute_list_next();
		public void attribute_set(string key, string val);
		public bool attribute_remove(string key);
		public bool attribute_get(string key, out unowned string val);
		public void attribute_foreach(CollectionAttributeForeachFunc func);

		public static Collection universe();
		public static bool parse(string pattern, out Collection coll);
		public static bool parse_custom(string pattern, CollectionParseTokensFunc tokens_func, CollectionParseBuildFunc build_func, out Collection coll);
		public static Collection default_parse_build(CollectionToken[] tokens);
		public static CollectionToken[] default_parse_tokens(string str, out unowned string newpos);
	}


	[Compact]
	[CCode(cname="xmmsc_result_t", cprefix="xmmsc_result_", ref_function="xmmsc_result_ref", unref_function="xmmsc_result_unref")]
	public class Result
	{
		public ResultType get_class();
		public void disconnect();
		public Xmms.Value get_value();
		public void notifier_set(NotifierFunc func);
		public void notifier_set_full(NotifierFunc func, UserDataFreeFunc free_func);
		public void wait();
	}

	[Compact]
	[CCode(cname="xmmsv_t", cprefix="xmmsv_", ref_function="xmmsv_ref", unref_function="xmmsv_unref")]
	public class Value {
		[CCode(cname="xmmsv_new_none")]
		public Value.from_none();
		[CCode(cname="xmmsv_new_int")]
		public Value.from_int(int val);
		[CCode(cname="xmmsv_new_uint")]
		public Value.from_uint(uint val);
		[CCode(cname="xmmsv_new_string")]
		public Value.from_string(string val);
		[CCode(cname="xmmsv_new_coll")]
		public Value.from_coll(Xmms.Collection val);
		[CCode(cname="xmmsv_new_bin")]
		public Value.from_bin(uchar[] val);
		[CCode(cname="xmmsv_new_list")]
		public Value.from_list();
		[CCode(cname="xmmsv_new_dict")]
		public Value.from_dict();

		public bool is_error();
		public bool is_type(Xmms.ValueType typ);

		public Xmms.ValueType get_type();

		public bool get_error (out unowned string error);
		public bool get_int (out int val);
		public bool get_string (out unowned string val);
		public bool get_coll (out Xmms.Collection coll);
		public bool get_bin ([CCode(array_length_type="uint")] out unowned uchar[] val);

		public bool get_list_iter (out unowned Xmms.ListIter iter);
		public bool get_dict_iter (out unowned Xmms.DictIter iter);

		public bool list_get(int pos, out Xmms.Value val);
		public bool list_set(Xmms.Value val);
		public bool list_append(Xmms.Value val);
		public bool list_insert(int pos, Xmms.Value val);
		public bool list_remove(int pos);
		public bool list_clear();
		public bool list_foreach(Xmms.ListForeachFunc func);
		public int  list_get_size();

		public bool dict_get(string key, out unowned Xmms.Value val);
		public bool dict_set(string key, Xmms.Value val);
		public bool dict_remove(string key);
		public bool dict_clear();
		public bool dict_foreach(Xmms.DictForeachFunc func);
		public int dict_get_size();

		public Xmms.ValueType dict_entry_get_type(string key);
		public bool dict_entry_get_string(string key, out unowned string val);
		public bool dict_entry_get_int(string key, out int val);
		public bool dict_entry_get_uint(string key, out uint val);
		public bool dict_entry_get_collection(string key, out Xmms.Collection coll);

		public Xmms.Value propdict_to_dict([CCode (array_length = false)] string[]? prefs=null);
	}

	[Compact]
	[CCode(cname = "xmmsv_list_iter_t",	cprefix = "xmmsv_list_iter_")]
	public class ListIter {
		public bool entry(out unowned Xmms.Value val);
		public bool valid();
		public void first();
		public bool next();
		public bool seek(int pos);
		public bool insert(Xmms.Value val);
		public bool remove();
	}

	[Compact]
	[CCode(cname = "xmmsv_dict_iter_t",	cprefix = "xmmsv_dict_iter_", free_function="")]
	public class DictIter {
		public bool pair(out unowned string key, out unowned Xmms.Value val);
		public bool valid();
		public void first();
		public void next();
		public bool seek(string key);
		public bool set(Xmms.Value val);
		public bool remove();
	}
}
