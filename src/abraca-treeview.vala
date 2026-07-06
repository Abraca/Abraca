/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2014 Abraca Team
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

namespace Abraca {
	public delegate void SelectedRowFunc (uint position, GLib.Object item);
	public delegate void VoidFunc ();

	/**
	 * Common base for Abraca's ColumnView-based lists. GtkColumnView is a final
	 * type and cannot be subclassed, so this wraps one by composition and
	 * forwards the operations the views need, plus helpers for iterating the
	 * selection and popping up a context menu on secondary click. GTK4's
	 * ColumnView handles ctrl/shift/rubberband selection and drag-of-selection
	 * natively, so the old GtkTreeView selection juggling is gone.
	 */
	public class SelectableView : Gtk.Widget, Gtk.Scrollable {
		protected Gtk.ColumnView column_view;
		protected Gtk.SelectionModel selection;

		private Gtk.PopoverMenu context_menu;

		/* Gtk.Scrollable, proxied to the wrapped ColumnView so a ScrolledWindow
		 * can drive scrolling through this wrapper. */
		public Gtk.Adjustment hadjustment {
			get { return (column_view != null) ? column_view.hadjustment : null; }
			set construct { if (column_view != null) column_view.hadjustment = value; }
		}
		public Gtk.Adjustment vadjustment {
			get { return (column_view != null) ? column_view.vadjustment : null; }
			set construct { if (column_view != null) column_view.vadjustment = value; }
		}
		public Gtk.ScrollablePolicy hscroll_policy {
			get { return (column_view != null) ? column_view.hscroll_policy : Gtk.ScrollablePolicy.MINIMUM; }
			set { if (column_view != null) column_view.hscroll_policy = value; }
		}
		public Gtk.ScrollablePolicy vscroll_policy {
			get { return (column_view != null) ? column_view.vscroll_policy : Gtk.ScrollablePolicy.MINIMUM; }
			set { if (column_view != null) column_view.vscroll_policy = value; }
		}

		public bool get_border (out Gtk.Border border) {
			if (column_view != null)
				return column_view.get_border (out border);
			border = {};
			return false;
		}

		construct {
			set_layout_manager (new Gtk.BinLayout ());
			hexpand = true;
			vexpand = true;

			column_view = new Gtk.ColumnView (null);
			column_view.set_parent (this);
		}

		protected void use_model (GLib.ListModel model, bool multiple)
		{
			if (multiple)
				selection = new Gtk.MultiSelection (model);
			else
				selection = new Gtk.SingleSelection (model);
			column_view.set_model (selection);
		}

		/* Column forwarding so subclasses can keep talking in ColumnView terms. */
		protected void append_column (Gtk.ColumnViewColumn column)
		{
			column_view.append_column (column);
		}

		protected void remove_column (Gtk.ColumnViewColumn column)
		{
			column_view.remove_column (column);
		}

		protected GLib.ListModel get_columns ()
		{
			return column_view.get_columns ();
		}

		public uint count_selected ()
		{
			return (uint) selection.get_selection ().get_size ();
		}

		public void foreach_selected (SelectedRowFunc func)
		{
			var bitset = selection.get_selection ();
			Gtk.BitsetIter iter = {};
			uint pos;

			if (iter.init_first (bitset, out pos)) {
				do {
					var item = selection.get_item (pos);
					if (item != null)
						func (pos, item);
				} while (iter.next (out pos));
			}
		}

		public GLib.Object? first_selected ()
		{
			var bitset = selection.get_selection ();
			Gtk.BitsetIter iter = {};
			uint pos;

			if (iter.init_first (bitset, out pos))
				return selection.get_item (pos);

			return null;
		}

		public void select_all_rows ()
		{
			selection.select_all ();
		}

		/**
		 * Install a right-click context menu backed by a GMenu model. The
		 * matching actions live in an action group the subclass installs.
		 */
		protected void install_context_menu (GLib.MenuModel model)
		{
			context_menu = new Gtk.PopoverMenu.from_model (model);
			context_menu.set_parent (column_view);
			context_menu.set_has_arrow (false);

			var gesture = new Gtk.GestureClick ();
			gesture.set_button (3);
			gesture.pressed.connect ((n_press, x, y) => {
				before_context_menu ();
				Gdk.Rectangle rect = { (int) x, (int) y, 1, 1 };
				context_menu.set_pointing_to (rect);
				context_menu.popup ();
			});
			column_view.add_controller (gesture);
		}

		/** Overridden by subclasses to refresh action sensitivity before popup. */
		protected virtual void before_context_menu () { }

		public override void dispose ()
		{
			if (context_menu != null) {
				context_menu.unparent ();
				context_menu = null;
			}
			if (column_view != null) {
				column_view.unparent ();
				column_view = null;
			}
			base.dispose ();
		}
	}
}
