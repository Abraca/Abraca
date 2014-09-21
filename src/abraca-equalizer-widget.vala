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

[GtkTemplate(ui = "/org/xmms2/Abraca/ui/abraca-equalizer.ui")]
public class Abraca.Equalizer : Gtk.Dialog {
	private static const string[] BAND_NAMES_10_LEGACY = {
		"60Hz", "170Hz", "310Hz", "600Hz", "1kHz", "3kHz", "6kHz", "12kHz", "14kHz", "16kHz"
	};

	private static const string[] BAND_NAMES_10 = {
		"31Hz", "62Hz", "125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz", "16kHz"
	};

	private static const string[] BAND_NAMES_15 = {
		"25Hz", "40Hz", "63Hz", "100Hz", "160Hz", "250Hz", "400Hz", "630Hz", "1kHz", "1.6kHz",
		"2.5kHz", "4kHz", "6.3kHz", "10kHz", "16kHz"
	};

	private static const string[] BAND_NAMES_25 =  {
		"20Hz", "31.5Hz", "40Hz", "50Hz", "80Hz", "100Hz", "125Hz", "160Hz", "250Hz", "315Hz",
		"400Hz", "500Hz", "800Hz", "1kHz", "1.25kHz", "1.6kHz", "2.5kHz", "3.15kHz", "4kHz",
		"5kHz", "8kHz", "10kHz", "12.5kHz", "16kHz", "20kHz"
	};

	private static const string[] BAND_NAMES_31 =  {
		"20Hz", "25Hz", "31.5Hz", "40Hz", "50Hz", "63Hz", "80Hz", "100Hz", "125Hz", "160Hz",
		"200Hz", "250Hz", "315Hz", "400Hz", "500Hz", "630Hz", "800Hz", "1kHz", "1.25kHz", "1.6kHz",
		"2kHz", "2.5kHz", "3.15kHz", "4kHz", "5kHz", "6.3kHz", "8kHz", "10kHz", "12.5kHz", "16kHz", "20kHz"
	};

	private const int MAX_BANDS = 31;

	private const double START_VALUE = 0.0;

	private const double MAX_GAIN = 20.1;
	private const double MIN_GAIN = -20.0;

	private const int MAX_VOLUME = 100;
	private const int MIN_VOLUME = 0;

	private static int VOLUME_INDEX = 0;
	private static int PREAMP_INDEX = 1;
	private static int GAIN_OFFSET = 2;

	private Gee.List<Gtk.Range> ranges = new Gee.ArrayList<Gtk.Scale>();
	private int band_count = 0;

	private Gee.List<double?> next_scale_changes = new Gee.ArrayList<double?>();
	private int next_band_count = 0;
	private string[] next_band_names = {};

	private bool defer_updates = false;
	private bool need_resize = false;

	private EqualizerModel model;
	private Client client;

	[GtkChild]
	private Gtk.ComboBox combobox_bands;

	[GtkChild]
	private Gtk.Range volume_scale;

	[GtkChild]
	private Gtk.Range preamp_scale;

	[GtkChild]
	private Gtk.Box box_bands;

	[GtkChild]
	private Gtk.Box box_labels;

	public Equalizer(Client c)
	{
		Object(use_header_bar: 1);

		client = c;

		model = new EqualizerModel(client);

		ranges.add(volume_scale);
		ranges.add(preamp_scale);

		foreach (var child in box_bands.get_children())
			ranges.add(child as Gtk.Range);

		for (var i=0; i < Equalizer.MAX_BANDS + 2; i++)
			next_scale_changes.add(null);

		model.mode_changed.connect(on_equalizer_mode_changed);

		model.band_list_changed.connect((bands) => {
			for (var i = 0; i < bands.size; i++)
				next_scale_changes[GAIN_OFFSET + i] = normalize(bands[i], -20.0, 20.0);
			apply_changes();
		});

		model.band_changed.connect((band, gain) => {
			next_scale_changes[GAIN_OFFSET + band] = normalize(gain, -20.0, 20.0);
			apply_changes();
		});

		model.preamp_changed.connect((gain) => {
			next_scale_changes[PREAMP_INDEX] = normalize(gain, -20.0, 20.0);
			apply_changes();
		});

		client.playback_volume.connect((channels) => {
			unowned Xmms.DictIter iter;
			unowned string channel;
			int count, value, i = 0, volume = 0;

			count = channels.dict_get_size();

			if (channels.is_error() || count == 0) {
				volume_scale.sensitive = false;
				return;
			}

			volume_scale.sensitive = true;

			channels.get_dict_iter (out iter);
			while (iter.pair_int (out channel, out value)) {
				volume += value;
				iter.next ();
			}

			next_scale_changes[VOLUME_INDEX] = normalize(volume / channels.dict_get_size(), 0, 100);
			apply_changes();
		});
	}

	[GtkCallback]
	private void on_reset()
	{
		model.reset();
	}

	private void on_equalizer_mode_changed(EqualizerModel model, EqualizerMode mode)
	{
		next_band_names = BAND_NAMES_10_LEGACY;

		model.reset();

		switch (mode) {
		case EqualizerMode.LEGACY:
			next_band_names = BAND_NAMES_10_LEGACY;
			combobox_bands.set_active(1);
			break;
		case EqualizerMode.BANDS_10:
			next_band_names = BAND_NAMES_10;
			combobox_bands.set_active(2);
			break;
		case EqualizerMode.BANDS_15:
			next_band_names = BAND_NAMES_15;
			combobox_bands.set_active(3);
			break;
		case EqualizerMode.BANDS_25:
			next_band_names = BAND_NAMES_25;
			combobox_bands.set_active(4);
			break;
		case EqualizerMode.BANDS_31:
			next_band_names = BAND_NAMES_31;
			combobox_bands.set_active(5);
			break;
		default:
			combobox_bands.set_active(0);
			break;
		}

		if (mode != EqualizerMode.DISABLED) {
			preamp_scale.sensitive = true;
			box_bands.sensitive = true;
		} else {
			preamp_scale.sensitive = false;
			box_bands.sensitive = false;
		}

		next_band_count = mode.band_count();
	}

	[GtkCallback]
	private void on_combobox_changed(Gtk.ComboBox combobox)
	{
		Gtk.TreeIter iter;
		unowned string value;

		if (!combobox_bands.get_active_iter(out iter))
			return;

		combobox_bands.model.get(iter, combobox_bands.id_column, out value);

		if (value == "disabled") {
			client.xmms.config_set_value("equalizer.enabled", "0");
		} else {
			client.xmms.config_set_value("equalizer.enabled", "1");
			client.xmms.config_list_values().notifier_set(model.enable_equalizer);
			if (value == "legacy") {
				client.xmms.config_set_value("equalizer.use_legacy", "1");
			} else {
				client.xmms.config_set_value("equalizer.use_legacy", "0");
				client.xmms.config_set_value("equalizer.bands", value);
			}
		}
	}

	private static double normalize(double gain, double min, double max)
	{
		return double.max(min, double.min(max, gain));
	}

	[GtkCallback]
	private void on_volume_changed(Gtk.Range range)
	{
		model.set_volume(normalize(range.adjustment.value, 0, 100));
	}

	[GtkCallback]
	private void on_preamp_changed(Gtk.Range range)
	{
		model.set_preamp(normalize(range.adjustment.value, -20.0, 20.0));
	}

	[GtkCallback]
	private void on_band_changed(Gtk.Range range)
	{
		model.set_gain(ranges.index_of(range) - GAIN_OFFSET,
		               normalize(range.adjustment.value, -20.0, 20.0));
	}

	[GtkCallback]
	private bool on_scale_pressed(Gdk.EventButton ev)
	{
		defer_updates = true;
		return false;
	}

	[GtkCallback]
	private bool on_scale_released(Gdk.EventButton ev)
	{
		defer_updates = false;
		apply_changes();
		return false;
	}

	private void apply_changes()
	{

		if (defer_updates) {
			/* local updates in progress, defer remote updates */
			return;
		}

		if (band_count != next_band_count) {
			band_count = next_band_count;
			need_resize = true;
		}

		for (var i = 0; i < ranges.size; i++) {
			if (next_scale_changes[i] != null) {
				ranges.get(i).adjustment.value = next_scale_changes[i];
				next_scale_changes[i] = null;
			}
		}

		if (need_resize) {
			for (var i = GAIN_OFFSET; i < ranges.size; i++) {
				if (band_count <= (i - GAIN_OFFSET)) {
					ranges.get(i).hide();
				} else {
					ranges.get(i).show();
				}
			}

			if (next_band_names != null) {
				int j = 0;
				foreach (var child in box_labels.get_children()) {
					var label = child as Gtk.Label;
					label.use_markup = true;
					if (j < next_band_names.length) {
						label.set_markup("<span size=\"x-small\" color=\"#888\">%s</span>".printf(next_band_names[j]));
						label.show();
					} else {
						label.hide();
					}
					j++;
				}
				next_band_names = null;
			}


			if (need_resize)
				resize(400, 300);
		}
	}
}
