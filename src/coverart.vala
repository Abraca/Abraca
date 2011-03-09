/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2011  Abraca Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using GLib;

namespace Abraca {
	struct Candidate {
		public int mid;
		public string description;
	}

	class CoverArtDialog : Gtk.Dialog, Gtk.Buildable {
		public Gtk.ListStore store;

		private Gtk.Label lbl_artist;
		private Gtk.Label lbl_album;

		private Gtk.Image coverart;

		public Gdk.Pixbuf image {
			get {
				return coverart.get_pixbuf ();
			}
			set {
				var scaled = value.scale_simple (120, 120, Gdk.InterpType.BILINEAR);
				coverart.set_from_pixbuf (scaled);
			}
		}


		enum Column {
			ID,
			DESCRIPTION,
			SELECTED
		}


		public static CoverArtDialog build ()
		{
			var builder = new Gtk.Builder ();

			try {
				builder.add_from_string (Resources.XML.coverart,
				                         Resources.XML.coverart.length);
			} catch (GLib.Error e) {
				GLib.error (e.message);
			}

			return builder.get_object ("coverart_dialog") as CoverArtDialog;
		}


		public void parser_finished (Gtk.Builder builder)
		{
			store = builder.get_object ("liststore1") as Gtk.ListStore;

			coverart = builder.get_object ("image1") as Gtk.Image;

			lbl_album = builder.get_object ("lbl_album") as Gtk.Label;
			lbl_artist = builder.get_object ("lbl_artist") as Gtk.Label;

			var check_all = new Gtk.CheckButton ();
			check_all.toggled.connect (on_all_toggled);
			check_all.active = true;
			check_all.show ();

			var column = builder.get_object ("treeviewcolumn1") as Gtk.TreeViewColumn;
			column.widget = check_all;
			column.clicked.connect ((column) => {
				check_all.active = !check_all.active;
			});

			var renderer = builder.get_object ("cellrenderertoggle1") as Gtk.CellRendererToggle;
			renderer.toggled.connect (on_entry_toggled);
		}


		[CCode (instance_pos = -1)]
		public void on_entry_toggled (Gtk.CellRendererToggle renderer, string path)
		{
			Gtk.TreeIter iter;
			bool selected;

			if (!store.get_iter (out iter, new Gtk.TreePath.from_string (path)))
				return;

			store.get (iter, Column.SELECTED, out selected);
			store.set (iter, Column.SELECTED, !selected);
		}


		public void on_all_toggled (Gtk.ToggleButton button)
		{
			Gtk.TreeIter iter;

			if (!store.get_iter_first (out iter))
				return;

			do {
				store.set (iter, Column.SELECTED, button.active);
			} while (store.iter_next (ref iter));
		}


		public void set_metadata (string artist, string album)
		{
			lbl_album.set_text (album);
			lbl_artist.set_text (artist);
		}


		public void set_candidates (Gee.Collection<Candidate?> candidates)
		{
			foreach (var candidate in candidates) {
				Gtk.TreeIter iter;
				store.append (out iter);
				store.set (iter,
				           CoverArtDialog.Column.ID, candidate.mid,
				           CoverArtDialog.Column.DESCRIPTION, candidate.description,
				           CoverArtDialog.Column.SELECTED, (int) true);
			}
		}


		public bool get_selected_ids (out Gee.Collection<int> list)
		{
			Gtk.TreeIter iter;

			list = new Gee.ArrayList<int>();

			if (!store.get_iter_first (out iter))
				return false;

			do {
				int mid, selected;
				store.get (iter,
				           Column.SELECTED, out selected,
				           Column.ID, out mid);
				if (selected == (int) true)
					list.add(mid);
			} while (store.iter_next (ref iter));

			if (list.size <= 0)
				return false;

			return true;
		}
	}


	public class CoverArtManager : GLib.Object {
		private Client client;
		private CoverArtDialog dialog;
		private Gtk.Window parent;
		private Gee.Collection<int> selected_ids;
		private string artist;
		private string album;

		public CoverArtManager (Client client, Gtk.Window parent)
		{
			this.client = client;
			this.parent = parent;
		}


		private void on_update_preview (Gtk.FileChooser chooser)
		{
			var filename = chooser.get_preview_filename ();
			if (filename == null)
				return;

			try {
				var pixbuf = new Gdk.Pixbuf.from_file_at_scale (filename, 200, 200, true);

				var preview = chooser.preview_widget as Gtk.Image;
				preview.set_from_pixbuf (pixbuf);

				chooser.preview_widget_active = true;
			} catch (GLib.Error e) {
				chooser.preview_widget_active = false;
			}
		}


		private bool get_pixbuf (out Gdk.Pixbuf pixbuf)
		{
			var dialog = new Gtk.FileChooserDialog ("Select cover art image.",
			                                        parent,
			                                        Gtk.FileChooserAction.OPEN,
			                                        Gtk.Stock.CANCEL,
			                                        Gtk.ResponseType.CANCEL,
			                                        Gtk.Stock.OK,
			                                        Gtk.ResponseType.OK);

			dialog.preview_widget = new Gtk.Image ();
			dialog.preview_widget_active = false;
			dialog.use_preview_label = false;
			dialog.update_preview.connect (on_update_preview);

			var filter = new Gtk.FileFilter ();
			filter.set_name ("Coverart Images");
			filter.add_mime_type ("image/*");

			dialog.add_filter (filter);

			var response_id = dialog.run ();
			if (response_id == Gtk.ResponseType.CANCEL) {
				dialog.close ();
				return false;
			}

			var filename = dialog.get_filename ();
			if (filename == null) {
				dialog.close ();
				return false;
			}

			dialog.close ();

			try {
				pixbuf = new Gdk.Pixbuf.from_file (filename);
			} catch (GLib.Error e) {
				GLib.warning (e.message);
				return false;
			}

			return true;
		}


		private bool get_track_ids (Gee.Collection<Candidate?> candidates,
		                            Gdk.Pixbuf pixbuf,
		                            out Gee.Collection<int> ids)
		{
			var dialog = CoverArtDialog.build ();
			dialog.transient_for = parent;

			dialog.set_metadata (artist, album);
			dialog.set_candidates (candidates);

			dialog.image = pixbuf;


			if (dialog.run () != Gtk.ResponseType.OK) {
				dialog.close ();
				return false;
			}

			if (!dialog.get_selected_ids (out ids)) {
				dialog.close ();
				return false;
			}

			dialog.close ();

			return true;
		}


		public void update_coverart (int mid)
		{
			client.xmms.medialib_get_info(mid).notifier_set(on_media_info);
		}


		private bool on_media_info (Xmms.Value propdict)
		{
			Xmms.Collection coll;
			int is_compilation = 0;

			artist = null;
			album = null;

			var val = propdict.propdict_to_dict ();

			val.dict_entry_get_int("compilation", out is_compilation);

#if XMMS_API_COLLECTIONS_TWO_DOT_ZERO
			var universe = new Xmms.Collection (Xmms.CollectionType.UNIVERSE);
#else
			var universe = new Xmms.Collection (Xmms.CollectionType.REFERENCE);
			universe.attribute_set ("namespace", "Collections");
			universe.attribute_set ("reference", "All Media");
#endif

			if (!val.dict_entry_get_string ("album", out album) || album.length == 0) {
				int mid;

				val.dict_entry_get_int ("id", out mid);

				coll = new Xmms.Collection (Xmms.CollectionType.IDLIST);
				coll.idlist_append (mid);
			} else {
#if XMMS_API_COLLECTIONS_TWO_DOT_ZERO
				var album_coll = new Xmms.Collection (Xmms.CollectionType.MATCH);
				album_coll.add_operand (universe);
				album_coll.attribute_set ("field", "album");
				album_coll.attribute_set ("value", album);

				coll = new Xmms.Collection (Xmms.CollectionType.INTERSECTION);
				coll.add_operand (album_coll);

				if (is_compilation == (int) true) {
					var other_coll = new Xmms.Collection (Xmms.CollectionType.MATCH);
					other_coll.add_operand (universe);
					other_coll.attribute_set ("field", "compilation");
					other_coll.attribute_set ("value", "1");
					coll.add_operand (other_coll);
				} else if (!val.dict_entry_get_string ("artist", out artist) && artist.length > 0) {
					var other_coll = new Xmms.Collection (Xmms.CollectionType.MATCH);
					other_coll.add_operand (universe);
					other_coll.attribute_set ("field", "artist");
					other_coll.attribute_set ("value", artist);
					coll.add_operand (other_coll);
				}
#else
				var album_coll = new Xmms.Collection (Xmms.CollectionType.EQUALS);
				album_coll.add_operand (universe);
				album_coll.attribute_set ("field", "album");
				album_coll.attribute_set ("value", album);

				coll = new Xmms.Collection (Xmms.CollectionType.INTERSECTION);
				coll.add_operand (album_coll);

				if (is_compilation == (int) true) {
					var other_coll = new Xmms.Collection (Xmms.CollectionType.EQUALS);
					other_coll.add_operand (universe);
					other_coll.attribute_set ("field", "compilation");
					other_coll.attribute_set ("value", "1");
					coll.add_operand (other_coll);
					artist = "Various Artists";
				} else if (!val.dict_entry_get_string ("artist", out artist) && artist.length > 0) {
					var other_coll = new Xmms.Collection (Xmms.CollectionType.EQUALS);
					other_coll.add_operand (universe);
					other_coll.attribute_set ("field", "artist");
					other_coll.attribute_set ("value", artist);
					coll.add_operand (other_coll);
				}
#endif
			}

			var order = new Xmms.Value.from_list ();
			order.list_append (new Xmms.Value.from_string ("album"));
			order.list_append (new Xmms.Value.from_string ("tracknr"));

			var fetch = new Xmms.Value.from_list ();
			fetch.list_append (new Xmms.Value.from_string ("id"));
			fetch.list_append (new Xmms.Value.from_string ("title"));
			fetch.list_append (new Xmms.Value.from_string ("tracknr"));
			fetch.list_append (new Xmms.Value.from_string ("duration"));

			coll.add_operand (universe);

			client.xmms.coll_query_infos (coll, order, 0, 0, fetch).notifier_set (on_coll_query_infos);

			return true;
		}


		private bool on_coll_query_infos (Xmms.Value value)
		{
			unowned Xmms.ListIter iter;

			if (!value.get_list_iter (out iter)) {
				string error;
				value.get_error (out error);
				GLib.debug ("%s", error);
				return true;
			}

			var candidates = new Gee.LinkedList<Candidate?>();

			for (iter.first (); iter.valid (); iter.next ()) {
				unowned Xmms.Value entry;
				unowned string title;
				int mid;

				if (!iter.entry (out entry))
					continue;

				entry.dict_entry_get_string ("title", out title);
				entry.dict_entry_get_int ("id", out mid);

				candidates.add(Candidate () { mid = mid, description = title });
			}

			Gdk.Pixbuf pixbuf;
			if (!get_pixbuf (out pixbuf))
				return true;


			Gee.Collection<int> ids;
			if (!get_track_ids (candidates, pixbuf, out ids))
				return true;

			try {
				uint8[] buffer;
				if (!pixbuf.save_to_buffer (out buffer, "png"))
					return true;


				/* TODO: Need to store ids here due to a Vala reference bug. */
				selected_ids = ids;

				client.xmms.bindata_add (buffer).notifier_set (on_bindata_add);
			} catch (GLib.Error e) {
				GLib.warning ("Could not add cover art.");
			}

			return true;
		}


		private bool on_bindata_add (Xmms.Value value)
		{
			string hash;

			if (!value.get_string (out hash)) {
				string error;
				value.get_error (out error);
				GLib.debug ("%s", error);
				return true;
			}


			foreach (int mid in selected_ids) {
				client.xmms.medialib_entry_property_set_str (mid,
				                                             "picture_front",
				                                             hash);
				client.xmms.medialib_entry_property_set_str (mid,
				                                             "picture_front_mime",
				                                             "png");
			}

			selected_ids = null;

			return true;
		}
	}
}
