namespace Abraca {
	[Compact]
	[CCode (
		cname = "property_list_t",
		cprefix = "property_list_",
		ref_function = "property_list_ref",
		unref_function = "property_list_unref",
		cheader_filename = "property_list.h"
	)]
	public class PropertyList {
		public PropertyList (string[] args);
		public weak string[] get ();
		public int get_length ();
	}

}
