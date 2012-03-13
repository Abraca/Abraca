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

public errordomain ConfigError {
	INVALID,
	MISSING
}

public class Abraca.EqualizerModel : GLib.Object {
	public signal void band_count_changed (bool use_legacy, int band_count);
	public signal void band_list_changed (Gee.List<double?> bands);
	public signal void band_changed (int band, double gain);

	private Client client;

	private bool _use_legacy = false;
	public bool use_legacy { get { return _use_legacy; } }

	private int _band_count = -1;
	public int band_count { get { return _band_count; } }

	private const string CONFIG_FORMAT_LEGACY = "equalizer.legacy%d";
	private const string CONFIG_FORMAT_NORMAL = "equalizer.gain%02d";

	public EqualizerModel (Client c) {
		client = c;
		client.configval_changed.connect(on_config_changed);
		client.connection_state_changed.connect(on_connection_state_changed);
	}

	public void set_gain (int band, double gain)
	{
		var key = use_legacy ? CONFIG_FORMAT_LEGACY : CONFIG_FORMAT_NORMAL;
		var value = "%.2f".printf (gain);
		client.xmms.config_set_value (key.printf(band), value);
	}

	private void on_connection_state_changed (Client client, Client.ConnectionState state)
	{
		if (state == Client.ConnectionState.Connected) {
			refresh();
		}
	}

	private void on_config_changed (Client c, string key, string value)
	{
		int band = 0;

		if (!key.has_prefix("equalizer")) {
			return;
		}

		if (key == "equalizer.use_legacy" || key == "equalizer.bands") {
			refresh();
		} else if ((use_legacy && (key.scanf(CONFIG_FORMAT_LEGACY, out band) == 1)) ||
		           (!use_legacy && (key.scanf(CONFIG_FORMAT_NORMAL, out band) == 1))) {
			try {
				band_changed (band, double_from_string (value));
			} catch (ConfigError e) {
				GLib.warning ("Could not parse value for '%s': '%s'".printf(key, value));
			}
		} else {
			GLib.debug ("Skipping %s = %s".printf(key, value));
		}
	}

	private void refresh() {
		client.xmms.config_list_values().notifier_set(on_config_list);
	}

	private Gee.List<double?> get_legacy_bands (Xmms.Value dict)
		throws ConfigError
	{
		Gee.List<double?> bands = new Gee.ArrayList<double?>();

		for (var i=0; i < 10; i++) {
			var key = "equalizer.legacy%d".printf(i);
			bands.add(lookup_gain(dict, key));
		}

		return bands;
	}

	private Gee.List<double?> get_bands (Xmms.Value dict)
		throws ConfigError
	{
		Gee.List<double?> bands = new Gee.ArrayList<double?>();
		string? value;
		int64 count;

		if (!dict.dict_entry_get_string ("equalizer.bands", out value)) {
			throw new ConfigError.MISSING("Equalizer bands config key missing.");
		}

		if (!int64.try_parse (value, out count)) {
			throw new ConfigError.INVALID("Equalizer bands config not an integer.");
		}

		for (var i=0; i < count; i++) {
			var key = "equalizer.gain%02d".printf(i);
			bands.add(lookup_gain(dict, key));
		}

		return bands;
	}

	private bool on_config_list (Xmms.Value dict)
	{
		try {
			string value;

			if (!dict.dict_entry_get_string ("equalizer.use_legacy", out value)) {
				return true;
			}

			_use_legacy = (bool) int_from_string (value);

			var bands = use_legacy ? get_legacy_bands (dict) : get_bands (dict);
			_band_count = bands.size;

			band_count_changed (use_legacy, band_count);
			band_list_changed (bands);
		} catch (ConfigError e) {
			GLib.warning (e.message);
		}

		return true;
	}

	private static double double_from_string (string value)
		throws ConfigError
	{
		double result;

		if (!double.try_parse (value, out result)) {
			var message = "'%s', not a double.".printf(value);
			throw new ConfigError.INVALID(message);
		}

		return result;
	}

	private static int64 int_from_string (string value)
		throws ConfigError
	{
		int64 result;

		if (!int64.try_parse (value, out result)) {
			var message = "'%s', not an integer.".printf(value);
			throw new ConfigError.INVALID(message);
		}

		return result;
	}

	private static double lookup_gain (Xmms.Value value, string key)
		throws ConfigError
	{
		string gain;

		if (!value.dict_entry_get_string(key, out gain)) {
			var message = "Equalizer key '%s' not available.".printf(key);
			throw new ConfigError.MISSING(message);
		}

		return double_from_string(gain);
	}


}
