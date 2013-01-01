/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2012 Abraca Team
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

public class Abraca.TreeView : Gtk.TreeView
{
	private ulong event_handle_drag_begin;
	private ulong event_handle_button_release;

	private bool selectable = true;

	private Gtk.TreePath anchor_path;

	private int press_x;

	public unowned Gtk.TreeSelection selection {
		get {
			return get_selection();
		}
	}

	public TreeView()
	{
		button_press_event.connect(on_button_press);
		drag_begin.connect_after(on_after_drag_begin);

		selection.set_select_function((selection, model, path, is_selected) => {
			return selectable;
		});
	}

	private static bool is_ctrl_modified(Gdk.EventButton ev)
	{
		return (ev.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK;
	}

	private static bool is_shift_modified(Gdk.EventButton ev)
	{
		return (ev.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK;
	}

	private static void get_surface_size(Cairo.Surface surface, out int width, out int height)
	{
		double x1, y1, x2, y2;

		var cr = new Cairo.Context(surface);
		cr.clip_extents(out x1, out y1, out x2, out y2);

		width = (int)(x2 - x1);
		height = (int)(y2 - y1);
	}

	private Gtk.TreePath? get_path_from_event(Gdk.EventButton ev)
	{
		Gtk.TreePath path;

		if (get_path_at_pos((int) ev.x, (int) ev.y, out path, null, null, null))
			return path;

		return null;
	}

	private void enable_gtk_selection()
	{
		if (event_handle_button_release != 0) {
			disconnect(event_handle_button_release);
			event_handle_button_release = 0;
		}

		if (event_handle_drag_begin != 0) {
			disconnect(event_handle_drag_begin);
			event_handle_drag_begin = 0;
		}

		selectable = true;
	}

	private void disable_gtk_selection()
	{
		if (event_handle_button_release == 0)
			event_handle_button_release = button_release_event.connect(on_button_release);
		selectable = false;
	}

	private bool on_button_press (Gdk.EventButton ev)
	{

		if (ev.button != 1)
			return false;

		var path = get_path_from_event(ev);
		if (path == null)
			return false;

		if (!is_shift_modified(ev))
			anchor_path = path;

		if (!selection.path_is_selected(path))
			return false;

		disable_gtk_selection();

		convert_widget_to_bin_window_coords((int) ev.x, (int) ev.y, out press_x, null);

		if (event_handle_drag_begin == 0)
			event_handle_drag_begin = drag_begin.connect(on_drag_begin);

		return false;
	}

	private bool on_button_release(Gdk.EventButton ev)
	{
		enable_gtk_selection();

		var path = get_path_from_event(ev);

		if (is_ctrl_modified(ev)) {
			if (is_shift_modified(ev)) {
				selection.select_range(anchor_path, path);
			} else {
				if (selection.path_is_selected(path)) {
					selection.unselect_path(path);
				} else {
					selection.select_path(path);
				}
			}
		} else {
			selection.unselect_all();
			if (is_shift_modified(ev)) {
				selection.select_range(anchor_path, path);
			} else {
				selection.select_path(path);
			}
		}

		return false;
	}

	private void on_drag_begin(Gdk.DragContext context)
	{
		enable_gtk_selection();
	}

	private void on_after_drag_begin (Gdk.DragContext context)
	{
		var pixbuf = create_rows_drag_icon();
		Gtk.drag_set_icon_pixbuf(context, pixbuf, press_x, pixbuf.height);
	}

	private Gdk.Pixbuf create_rows_drag_icon()
	{
		int width, row_height;

		GLib.List<unowned Gtk.TreePath> paths = selection.get_selected_rows(null);

		var surfaces = new GLib.List<Cairo.Surface>();
		foreach (unowned Gtk.TreePath path in paths)
			surfaces.append(create_row_drag_icon(path));

		var template = surfaces.first().data;

		get_surface_size(template, out width, out row_height);

		/* remove bottom border for each row, but keep it for the last row */
		var height = (row_height - 1) * selection.count_selected_rows() + 1;

		var target = new Cairo.Surface.similar(template, template.get_content(), width, height);

		var cr = new Cairo.Context(target);
		cr.translate(2, 2);
		foreach (Cairo.Surface surface in surfaces) {
			cr.set_source_surface(surface, 0, 0);
			cr.paint();
			cr.translate(0, row_height - 1);
		}

		return Gdk.pixbuf_get_from_surface(target, 0, 0, width, height);
	}
}
