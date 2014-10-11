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

public errordomain ConfigError {
	INVALID,
	MISSING
}

public enum Abraca.EqualizerMode {

	DISABLED,
	LEGACY,
	BANDS_10,
	BANDS_15,
	BANDS_25,
	BANDS_31;

	public bool is_legacy()
	{
		return this == LEGACY;
	}

	public int band_count()
	{
		switch (this)
		{
		case LEGACY:
			return 10;
		case BANDS_10:
			return 10;
		case BANDS_15:
			return 15;
		case BANDS_25:
			return 25;
		case BANDS_31:
			return 31;
		default:
			return 10;
		}
	}

	public static EqualizerMode from_settings(int band_count, bool legacy, bool enabled)
	{
		if (!enabled)
			return EqualizerMode.DISABLED;

		if (legacy)
			return EqualizerMode.LEGACY;

		switch (band_count) {
		case 10:
			return EqualizerMode.BANDS_10;
		case 15:
			return EqualizerMode.BANDS_15;
		case 25:
			return EqualizerMode.BANDS_25;
		case 31:
			return EqualizerMode.BANDS_31;
		default:
			return EqualizerMode.DISABLED;
		}
	}
}

public class Abraca.EqualizerModel : GLib.Object {
	private const int GRACE_PERIOD_USEC = 125 * 1000;

	private const string CONFIG_FORMAT_PREAMP = "equalizer.preamp";
	private const string CONFIG_FORMAT_LEGACY = "equalizer.legacy%d";
	private const string CONFIG_FORMAT_NORMAL = "equalizer.gain%02d";

	private static int VOLUME_INDEX = 0;
	private static int PREAMP_INDEX = 1;
	private static int GAIN_OFFSET = 2;

	public signal void mode_changed(EqualizerMode mode, bool initial);
	public signal void band_list_changed(Gee.List<double?> bands);
	public signal void band_changed(int band, double gain);
	public signal void preamp_changed(double gain);

	private Gee.List<double?> unapplied_changes;
	private uint updater_source = 0;
	private GLib.TimeVal updater_timestamp;

	private Client client;

	private bool initialized = false;

	public EqualizerMode mode {
		get; private set; default = EqualizerMode.DISABLED;
	}

	public EqualizerModel(Client c) {
		client = c;
		client.configval_changed.connect(on_config_changed);
		client.connection_state_changed.connect(on_connection_state_changed);

		unapplied_changes = new Gee.ArrayList<double?>();

		unapplied_changes.add(null); // Volume
		unapplied_changes.add(null); // Pre-Amp
		for (var i = 0; i < EqualizerMode.BANDS_31.band_count(); i++)
			unapplied_changes.add(null);
	}

	public bool enable_equalizer(Xmms.Value value)
	{
		unowned Xmms.DictIter iter;
		unowned string key, str_value;
		var free_idx = 0;
		var found = false;

		value.get_dict_iter(out iter);
		while (iter.pair_string(out key, out str_value)) {
			var position = -1;

			if (key.has_prefix("effect.order.")) {
				if (str_value == "equalizer") {
					found = true;
					break;
				}

				key.scanf("effect.order.%d", out position);
				if (position != -1 && position < free_idx)
					free_idx = position;
			}

			iter.next();
		}

		if (!found) {
			GLib.warning("free index: %d", free_idx);
			/* enable equalizer at free_idx */
		}

		return true;
	}

	public void set_volume(double volume)
	{
		unapplied_changes[VOLUME_INDEX] = volume;
		throttle_changes();
	}

	public void set_preamp(double gain)
	{
		unapplied_changes[PREAMP_INDEX] = gain;
		throttle_changes();
	}

	public void set_gain(int band, double gain)
	{
		unapplied_changes[GAIN_OFFSET + band] = gain;
		throttle_changes();
	}

	private void throttle_changes()
	{
		updater_timestamp = GLib.TimeVal ();
		updater_timestamp.add (GRACE_PERIOD_USEC);

		if (updater_source == 0)
			updater_source = GLib.Timeout.add (GRACE_PERIOD_USEC / (2 * 1000), apply_changes);
	}

	private bool apply_changes()
	{
		var now = GLib.TimeVal ();

		var d_sec = now.tv_sec - updater_timestamp.tv_sec;
		var d_usec = now.tv_usec - updater_timestamp.tv_usec;

		if (!(d_sec > 0 || (d_sec == 0 && d_usec > 0)))
			return true;

		if (unapplied_changes[VOLUME_INDEX] != null) {
			var next = (int) unapplied_changes[VOLUME_INDEX];
			client.xmms.playback_volume_get().notifier_set_full((channels) => {
				if (!channels.is_error ()) {
					channels.dict_foreach((channel, volume) => {
						client.xmms.playback_volume_set (channel, next);
					});
				}
				return true;
			});
			unapplied_changes[VOLUME_INDEX] = null;
		}

		if (unapplied_changes[PREAMP_INDEX] != null) {
			client.xmms.config_set_value(CONFIG_FORMAT_PREAMP, unapplied_changes[PREAMP_INDEX].to_string());
			unapplied_changes[PREAMP_INDEX] = null;
		}

		var key = mode.is_legacy() ? CONFIG_FORMAT_LEGACY : CONFIG_FORMAT_NORMAL;
		var gain_end_offset = EqualizerMode.BANDS_31.band_count() + GAIN_OFFSET;
		for (var i = GAIN_OFFSET; i < gain_end_offset; i++) {
			if (unapplied_changes[i] != null) {
				client.xmms.config_set_value(key.printf(i - GAIN_OFFSET), unapplied_changes[i].to_string());
				unapplied_changes[i] = null;
			}
		}

		updater_source = 0;

		return false;
	}

	public void reset()
	{
		client.xmms.config_set_value(CONFIG_FORMAT_PREAMP, "0.0");
		for (var i = 0; i < 10; i++)
			client.xmms.config_set_value(CONFIG_FORMAT_LEGACY.printf(i), "0.0");
		for (var i = 0; i < 31; i++)
			client.xmms.config_set_value(CONFIG_FORMAT_NORMAL.printf(i), "0.0");
	}

	private void on_connection_state_changed(Client client, Client.ConnectionState state)
	{
		if (state == Client.ConnectionState.Connected) {
			refresh();
		} else {
			initialized = false;
		}
	}

	private void on_config_changed(Client c, string key, string value, bool initial)
	{
		int band = 0;

		if (!key.has_prefix("equalizer")) {
			return;
		}

		if (key == "equalizer.use_legacy" || key == "equalizer.bands" || key == "equalizer.enabled") {
			if (!initial)
				refresh();
		} else if ((mode.is_legacy() && (key.scanf(CONFIG_FORMAT_LEGACY, out band) == 1)) ||
		           (!mode.is_legacy() && (key.scanf(CONFIG_FORMAT_NORMAL, out band) == 1))) {
			try {
				band_changed(band, double_from_string(value));
			} catch (ConfigError e) {
				GLib.warning("Could not parse value for '%s': '%s'".printf(key, value));
			}
		} else if (key == "equalizer.preamp") {
			preamp_changed(double_from_string(value));
		} else {
			GLib.debug("Skipping %s = %s".printf(key, value));
		}
	}

	private void refresh() {
		client.xmms.config_list_values().notifier_set(on_config_list);
	}

	private Gee.List<double?> get_legacy_bands(Xmms.Value dict)
		throws ConfigError
	{
		Gee.List<double?> bands = new Gee.ArrayList<double?>();

		for (var i=0; i < 10; i++) {
			var key = "equalizer.legacy%d".printf(i);
			bands.add(lookup_gain(dict, key));
		}

		return bands;
	}

	private Gee.List<double?> get_dummy_bands(int count)
	{
		var bands = new Gee.ArrayList<double?>();
		for (var i = 0; i < count; i++)
			bands.add(0.0);
		return bands;
	}

	private Gee.List<double?> get_bands(Xmms.Value dict)
		throws ConfigError
	{
		Gee.List<double?> bands = new Gee.ArrayList<double?>();
		string? value;
		int64 count;

		if (!dict.dict_entry_get_string("equalizer.bands", out value)) {
			throw new ConfigError.MISSING("Equalizer bands config key missing.");
		}

		if (!int64.try_parse(value, out count)) {
			throw new ConfigError.INVALID("Equalizer bands config not an integer.");
		}

		for (var i = 0; i < count; i++) {
			var key = "equalizer.gain%02d".printf(i);
			bands.add(lookup_gain(dict, key));
		}

		return bands;
	}

	private bool on_config_list(Xmms.Value dict)
	{
		string value;

		try {
			if (!dict.dict_entry_get_string("equalizer.use_legacy", out value))
				value = "0";
			var use_legacy = (bool) int_from_string(value);

			if (!dict.dict_entry_get_string("equalizer.enabled", out value))
				value = "0";
			var enabled = (bool) int_from_string(value);

			var bands = use_legacy ? get_legacy_bands(dict) : get_bands(dict);

			mode = EqualizerMode.from_settings(bands.size, use_legacy, enabled);
			mode_changed(mode, initialized == false);
			initialized = true;

			band_list_changed(bands);

		} catch (ConfigError e) {
			GLib.warning(e.message);
			mode = EqualizerMode.DISABLED;
			mode_changed(mode, false);
			band_list_changed(get_dummy_bands(mode.band_count()));
		}

		return true;
	}

	private static double double_from_string(string value)
		throws ConfigError
	{
		double result;

		if (!double.try_parse(value, out result)) {
			var message = "'%s', not a double.".printf(value);
			throw new ConfigError.INVALID(message);
		}

		return result;
	}

	private static int64 int_from_string(string value)
		throws ConfigError
	{
		int64 result;
		if (!int64.try_parse(value, out result))
			throw new ConfigError.INVALID("'%s', not an integer.".printf(value));
		return result;
	}

	private static double lookup_gain(Xmms.Value value, string key)
		throws ConfigError
	{
		string gain;
		if (!value.dict_entry_get_string(key, out gain))
			throw new ConfigError.MISSING("Equalizer key '%s' not available.".printf(key));
		return double_from_string(gain);
	}
}
