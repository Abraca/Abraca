namespace Xmms {
	[CCode(
		cprefix = "XMMS_COLLECTION_CHANGED_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public enum CollectionChanged {
		ADD,
		UPDATE,
		RENAME,
		REMOVE,
	}

	[CCode(
		cprefix = "XMMS_MEDIAINFO_READER_STATUS_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public enum ReaderStatus {
		IDLE,
		RUNNING,
	}

	[CCode(
		cprefix = "XMMS_PLAYBACK_STATUS_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public enum PlaybackStatus {
		STOP,
		PLAY,
		PAUSE,
	}

	[CCode(
		cprefix = "XMMS_PLAYLIST_CHANGED_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
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


	[CCode(
		cprefix = "XMMS_PLUGIN_TYPE_",
		cheader_filename = "xmmsc/xmmsc_idnumbers.h"
	)]
	public enum PluginType {
		ALL,
		OUTPUT,
		XFORM,
	}

	[CCode(
		cprefix = "XMMS_COLLECTION_TOKEN_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
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

	[CCode(
		cprefix = "XMMS_COLLECTION_TYPE_",
		cheader_filename = "xmmsc/xmmsc_idnumbers.h"
	)]
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

	[CCode(
		cprefix = "XMMS_MEDIALIB_ENTRY_STATUS_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public enum EntryStatus {
		NEW,
		OK,
		RESOLVING,
		NOT_AVAILABLE,
		REHASH,
	}

	[CCode(
		cprefix = "XMMSC_RESULT_CLASS_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public enum ResultClass {
		DEFAULT,
		SIGNAL,
		BROADCAST,
	}

	[CCode(
		cprefix = "XMMSC_RESULT_VALUE_TYPE_",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public enum ResultType {
		NONE = 0,
		UINT32,
		INT32,
		STRING,
		DICT,
		PROPDICT,
		COLL,
		BIN,
	}


	[CCode(
		cname = "xmmsc_disconnect_func_t",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate void DisconnectFunc (
	);

	[CCode(
		cname = "xmmsc_dict_foreach_func",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate void DictForEachFunc (
		weak string key, Xmms.ResultType t, pointer val
	);

	[CCode(
		cname = "xmmsc_propdict_foreach_func",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate void PropDictForEachFunc (
		weak string key, Xmms.ResultType t, pointer val,
		weak string source
	);

	[CCode(
		cname = "xmmsc_result_notifier_t",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate void NotifierFunc (
		Result #res
	);

	[CCode(
		cname = "xmmsc_user_data_free_func_t",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate void UserDataFreeFunc (
		pointer obj
	);

	[CCode(
		cname = "xmmsc_coll_parse_tokens_f",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate CollectionToken CollectionParseTokensFunc (
		weak string key, weak string[] npos
	);

	[CCode(
		cname = "xmmsc_coll_parse_build_f",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate Collection CollectionParseBuildFunc (
		CollectionToken[] t
	);

	[CCode(
		cname = "xmmsc_coll_attribute_foreach_func",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public delegate void CollectionAttributeForeachFunc (
		weak string key, weak string val
	);

	public const string ACTIVE_PLAYLIST;
	public const string COLLECTION_NS_ALL;
	public const string COLLECTION_NS_COLLECTIONS;
	public const string COLLECTION_NS_PLAYLISTS;

	[CCode (
		cname = "xmmsc_coll_token_t",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public struct CollectionToken {
			public Xmms.CollectionTokenType type;
			[CCode(cname="string")]
			public weak string str;
			public weak CollectionToken next;
	}

	[CCode (
		cname = "xmmsc_connection_t",
		cprefix = "xmmsc_",
		ref_function = "xmmsc_ref",
		unref_function = "xmmsc_unref",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public class Client
	{
		[CCode (cname = "xmmsc_init")]
		public Client (
			weak string name
		);
		public bool connect (
			weak string path
		);

		/*
		 * Playback functions
		 */
		public Result playback_stop (
		);
		public Result playback_tickle (
		);
		public Result playback_start (
		);
		public Result playback_pause (
		);
		public Result playback_current_id (
		);
		public Result playback_seek_ms (
			uint32 milliseconds
		);
		public Result playback_seek_ms_rel (
			int milliseconds
		);
		public Result playback_seek_samples (
			uint32 samples
		);
		public Result playback_seek_samples_rel (
			int samples
		);
		public Result playback_playtime (
		);
		public Result playback_status (
		);
		public Result playback_volume_set (
			weak string channel, uint32 volume
		);
		public Result playback_volume_get (
		);
		public Result broadcast_playback_volume_changed (
		);
		public Result broadcast_playback_status (
		);
		public Result broadcast_playback_current_id (
		);
		public Result signal_playback_playtime (
		);

		/*
		 * Playlist functions
		 */
		public Result playlist_list (
		);
		public Result playlist_create (
			weak string playlist
		);
		public Result playlist_shuffle (
			weak string playlist
		);
		public Result playlist_add_args (
			weak string playlist, weak string url,
			int len, weak string[] args
		);
		public Result playlist_add_url (
			weak string playlist, weak string url
		);
		public Result playlist_add_id (
			weak string playlist, uint32 id
		);
		public Result playlist_add_encoded (
			weak string playlist, weak string url
		);
		public Result playlist_add_idlist (
			weak string playlist, Collection coll
		);
		public Result playlist_add_collection (
			weak string playlist, Collection coll, string[] order
		);
		public Result playlist_remove_entry (
			weak string playlist, uint32 id
		);
		public Result playlist_clear (
			weak string playlist
		);
		public Result playlist_remove (
			weak string playlist
		);
		public Result playlist_list_entries (
			weak string playlist = "Default"
		);
		[NoArrayLength]
		public Result playlist_sort (
			weak string playlist, weak string[] properties
		);
		public Result playlist_set_next (
			uint32 pos
		);
		public Result playlist_set_next_rel (
			int32 pos
		);
		public Result playlist_move_entry (
			weak string playlist, uint32 from, uint32 to
		);
		public Result playlist_current_pos (
			weak string playlist
		);
		public Result playlist_current_active (
		);
		public Result playlist_insert_args (
			weak string playlist, int pos, weak string url,
			int numargs, weak string[] args
		);
		public Result playlist_insert_url (
			weak string playlist, int pos, weak string url
		);
		public Result playlist_insert_id (
			weak string playlist, int pos, uint32 id
		);
		public Result playlist_insert_encoded (
			weak string playlist, int pos, weak string url
		);
		public Result playlist_insert_collection (
			weak string playlist, int pos,
			Collection coll, weak string[] order
		);
		public Result playlist_load (
			weak string playlist
		);
		public Result playlist_radd (
			weak string playlist, weak string url
		);
		public Result playlist_radd_encoded (
			weak string playlist, weak string url
		);
		public Result broadcast_playlist_changed (
		);
		public Result broadcast_playlist_current_pos (
		);
		public Result broadcast_playlist_loaded (
		);

		/*
		 * Medialib functions
		 */
		public Result medialib_add_entry (
			weak string url
		);
		public Result medialib_add_entry_args (
			weak string url, int numargs, weak string[] args
		);
		public Result medialib_add_entry_encoded (
			weak string url
		);
		public Result medialib_get_info (
			uint32 id
		);
		public Result medialib_path_import (
			weak string path
		);
		public Result medialib_path_import_encoded (
			weak string path
		);
		public Result medialib_rehash (
			uint32 id
		);
		public Result medialib_get_id (
			weak string url
		);
		public Result medialib_remove_entry (
			uint32 entry
		);
		public Result medialib_move_entry (
			uint32 entry, weak string url
		);
		public Result medialib_entry_property_set_int (
			uint32 id, weak string key, int32 val
		);
		public Result medialib_entry_property_set_int_with_source (
			uint32 id, weak string source,
			weak string key, int32 val
		);
		public Result medialib_entry_property_set_str (
			uint32 id, weak string key, weak string val
		);
		public Result medialib_entry_property_set_str_with_source (
			uint32 id, weak string source,
			weak string key, weak string val
		);
		public Result medialib_entry_property_remove (
			uint32 id, weak string key
		);
		public Result medialib_entry_property_remove_with_source (
			uint32 id, weak string source, weak string key
		);
		public Result broadcast_medialib_entry_changed (
		);
		public Result broadcast_medialib_entry_added (
		);
		public Result broadcast_mediainfo_reader_status (
		);
		public Result signal_mediainfo_reader_unindexed (
		);

		/*
		 * Config functions
		 */
		public Result configval_set (
			weak string key, weak string val
		);
		public Result configval_list (
		);
		public Result configval_get (
			weak string key
		);
		public Result configval_register (
			weak string valuename, weak string defaultvalue
		);
		public Result broadcast_configval_changed (
		);

		/*
		 * Browse functions
		 */
		public Result xform_media_browse (
			weak string url
		);
		public Result xform_media_browse_encoded (
			weak string url
		);

		/*
		 * Bindata functions
		 */
		public Result bindata_add (
			uchar[] data
		);
		public Result bindata_retrieve (
			weak string hash
		);
		public Result bindata_remove (
			weak string hash
		);

		/*
		 * Collection functions
		 */
		public Result coll_get (
			weak string collname, weak string ns
		);
		public Result coll_list (
			weak string ns
		);
		public Result coll_save (
			Collection c, weak string name, weak string ns
		);
		public Result coll_remove (
			weak string name, weak string ns
		);
		public Result coll_find (
			uint mediaid, weak string ns
		);
		public Result coll_rename (
			weak string from_name, weak string to_name, weak string ns
		);
		public Result coll_idlist_from_playlist_file (
			weak string path
		);
		public Result coll_sync (
		);
		public Result coll_query_ids (
			Collection coll, pointer order,
			uint limit_start = 0, uint limit_len = 0
		);
		public Result coll_query_infos (
			Collection coll, weak string[] order,
			uint limit_start = 0, uint limit_len = 0,
			weak string[] fetch = null,
			weak string[] group = null
		);
		public Result broadcast_collection_changed (
		);

		/*
		 * Other functions
		 */
		public static int entry_format (
			string target, int len, string fmt, Result res
		);
		public static weak string userconfdir_get (
			char[] buffer
		);
		public weak string get_last_error (
		);
		public Result quit(
		);
		public Result broadcast_quit (
		);
		public void disconnect_callback_set (
			DisconnectFunc func
		);
		public void disconnect_callback_set_full (
			DisconnectFunc func, UserDataFreeFunc ufunc
		);
		public Result plugin_list (
			Xmms.PluginType type = Xmms.PluginType.ALL
		);
		public Result main_stats (
		);
		public Result signal_visualisation_data (
		);
	}

	[CCode(
		cname = "xmmsc_coll_t",
		cprefix = "xmmsc_coll_",
		ref_function = "xmmsc_coll_ref",
		unref_function = "xmmsc_coll_unref",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public class Collection {
		[CCode (cname = "xmmsc_coll_new")]
		public Collection (
			CollectionType type
		);
		[NoArrayLength]
		public void set_idlist (
			uint[] ids
		);
		public void add_operand (
			Collection op
		);
		public void remove_operand (
			Collection op
		);
		public bool idlist_append (
			uint id
		);
		public bool idlist_insert (
			uint index, uint id
		);
		public bool idlist_move (
			uint index, uint newindex
		);
		public bool idlist_remove (
			uint index
		);
		public bool idlist_clear (
		);
		public bool idlist_get_index (
			uint index, out int32 val
		);
		public bool idlist_set_index (
			uint index, uint32 val
		);
		public uint idlist_get_size (
		);
		public CollectionType get_type (
		);
		public uint32[] get_idlist (
		);
		public bool operand_list_first (
		);
		public bool operand_list_valid (
		);
		public bool operand_list_entry (
			out Collection operand
		);
		public bool operand_list_next (
		);
		public bool operand_list_save (
		);
		public bool operand_list_restore (
		);
		public void operand_list_clear (
		);
		public void attribute_list_first (
		);
		public bool attribute_list_valid (
		);
		public void attribute_list_entry (
			out weak string key, out weak string val
		);
		public void attribute_list_next (
		);
		public void attribute_set (
			weak string key, weak string val
		);
		public bool attribute_remove (
			weak string key
		);
		public bool attribute_get (
			weak string key, out weak string val
		);
		public void attribute_foreach (
			CollectionAttributeForeachFunc func
		);
		public static Collection universe (
		);
		public static bool parse (
			weak string pattern, out Collection coll
		);
		public static bool parse_custom (
			weak string pattern, CollectionParseTokensFunc tokens_func,
			CollectionParseBuildFunc build_func, out Collection coll
		);
		public static Collection default_parse_build (
			CollectionToken[] tokens
		);
		public static CollectionToken[] default_parse_tokens (
			weak string str, out weak string newpos
		);
	}


	[CCode(
		cname = "xmmsc_result_t",
		cprefix = "xmmsc_result_",
		ref_function = "xmmsc_result_ref",
		unref_function = "xmmsc_result_unref",
		cheader_filename = "xmmsclient/xmmsclient.h"
	)]
	public class Result
	{
		public Result restart (
		);
		public ResultClass get_class (
		);
		public void disconnect (
		);
		public void notifier_set (
			NotifierFunc func
		);
		public void notifier_set_full (
			NotifierFunc func, UserDataFreeFunc free_func
		);
		public void wait (
		);
		public bool iserror (
		);
		public weak string get_error (
		);
		public bool get_int (
			out int32 val
		);
		public bool get_uint (
			out uint32 val
		);
		public bool get_string (
			out weak string val
		);
		public bool get_collection (
			out Collection val
		);
		public bool get_bin (
			out uchar[] val, out uint length
		);
		public ResultType get_dict_entry_type (
			weak string key
		);
		public bool get_dict_entry_string (
			weak string key, out weak string val
		);
		public bool get_dict_entry_int (
			weak string key, out int32 val
		);
		public bool get_dict_entry_uint (
			weak string key, out uint32 val
		);
		public bool get_dict_entry_collection (
			weak string key, out Collection coll
		);
		public bool dict_foreach (
			DictForEachFunc func
		);
		public int propdict_foreach (
			PropDictForEachFunc func
		);
		public void source_preference_set (
			weak string[] preference
		);
		public string[] source_preference_get (
		);
		public bool is_list (
		);
		public bool list_next (
		);
		public bool list_first (
		);
		public bool list_valid (
		);
		public string decode_url (
			weak string url
		);
		public void unref (
		);
		public weak Xmms.Result @ref (
		);
	}
}
