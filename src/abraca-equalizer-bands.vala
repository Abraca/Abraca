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

public class EqualizerBands : Gtk.Box {
	public signal void band_changed(int band, double value);
	private Gee.List<Gtk.Range> ranges = new Gee.ArrayList<Gtk.Scale>();
	private int band_count = 0;

	private Gee.List<double?> next_band_changes = new Gee.ArrayList<double?>();
	private int next_band_count = 0;

	private const int MAX_BANDS = 31;

	private const double START_VALUE = 0.0;
	private const double MAX_VALUE = 20.1;
	private const double MIN_VALUE = -20.0;

	private const double LINE_WIDTH = 1.5;

	private bool defer_updates = false;

	public EqualizerBands()
	{
		Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 5);
		create_bands();

		for (var i=0; i < EqualizerBands.MAX_BANDS; i++) {
			next_band_changes.add(null);
		}
	}

	private void create_bands()
	{
		for (var i=0; i < EqualizerBands.MAX_BANDS; i++) {
			var adjustment = new Gtk.Adjustment(
				EqualizerBands.START_VALUE,
				EqualizerBands.MIN_VALUE,
				EqualizerBands.MAX_VALUE,
				0.1, 0.1, 0.1
			);

			var scale = new Gtk.Scale(Gtk.Orientation.VERTICAL, adjustment);
			scale.draw_value = false;
			scale.inverted = true;
			scale.no_show_all = true;
			scale.change_value.connect(on_change_value);

			scale.button_press_event.connect((w) => {
				defer_updates = true;
				return false;
			});

			scale.button_release_event.connect((w) => {
				defer_updates = false;
				apply_changes();
				return false;
			});

			pack_start(scale, true, true);

			ranges.add(scale);
		}
	}

	public void set_band(int band, double value)
	{
		next_band_changes[band] = value;
		apply_changes();
	}

	public void set_bands(Gee.List<double?> bands)
	{
		next_band_count = bands.size;
		next_band_changes.insert_all(0, bands);
		apply_changes();
	}

	private void apply_changes()
	{
		if (defer_updates) {
			/* local updates in progress, defer remote updates */
			return;
		}

		band_count = next_band_count;

		for (var i=0; i < MAX_BANDS; i++) {
			if (band_count <= i) {
				ranges.get(i).hide();
			} else {
				ranges.get(i).show();
			}

			if (next_band_changes[i] != null) {
				apply_gain(i, next_band_changes[i]);
				next_band_changes[i] = null;
			}
		}

		var window = get_ancestor(typeof(Gtk.Window)) as Gtk.Window;
		window.resize(100, 180);
		queue_draw();
	}

	private double normalize(Gtk.Adjustment adjustment, double scale)
	{
		return (-adjustment.value / (-adjustment.lower + adjustment.upper) + 0.5) * scale;
	}

	private Cairo.Pattern draw_line(Cairo.Context cr)
	{
		var box_width = get_allocated_width();

		var range = ranges.get(0);

		int slider_length;
		range.style_get("slider-length", out slider_length);

		var range_height = range.get_allocated_height();

		var height = range_height - slider_length;
		var x_offset = box_width * 1.0 / band_count;
		var x_middle = x_offset / 2.0;
		var y_offset = slider_length / 2.0;

		cr.push_group();

		cr.set_line_width(LINE_WIDTH);
		cr.move_to(x_middle, normalize(range.adjustment, height) + y_offset);

		for (var i=0; i < band_count; i++) {
			var prev = int.max(i - 1, 0);
			var last = ranges.get(prev).adjustment;
			var curr = ranges.get(i).adjustment;

			cr.curve_to(
				(i * x_offset), normalize(last, height) + y_offset,
				(i * x_offset), normalize(curr, height) + y_offset,
				(i * x_offset + x_middle), normalize(curr, height) + y_offset
			);
		}

		cr.stroke();

		return cr.pop_group();
	}

	public override bool draw(Cairo.Context cr)
	{
		var line = draw_line(cr);

		var linear = new Cairo.Pattern.linear(0, 0, 0, get_allocated_height());
		linear.add_color_stop_rgba(0.00,  1, 0, 0, 1);
		linear.add_color_stop_rgba(0.25,  1, 1, 0, 1);
		linear.add_color_stop_rgba(0.50,  0, 1, 0, 1);
		linear.add_color_stop_rgba(0.75,  1, 1, 0, 1);
		linear.add_color_stop_rgba(1.00,  1, 0, 0, 1);

		cr.rectangle(0.0, 0.0, get_allocated_width(), get_allocated_height());
		cr.set_source(linear);

		cr.mask(line);

		base.draw(cr);

		return true;
	}

	public bool on_change_value(Gtk.Range range, Gtk.ScrollType type, double value)
	{
		queue_draw();

		band_changed(ranges.index_of(range),
		             double.max(EqualizerBands.MIN_VALUE, value));

		return false;
	}

	private void apply_gain(int band, double gain)
		requires(0 <= band && band <= EqualizerBands.MAX_BANDS)
		requires(EqualizerBands.MIN_VALUE <= gain && gain <= EqualizerBands.MAX_VALUE)
	{
		ranges.get(band).adjustment.value = gain;
	}
}
