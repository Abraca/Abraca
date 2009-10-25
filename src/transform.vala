/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008  Abraca Team
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
	public abstract class Transform {
		public static bool normalize_dict (Xmms.Value dict, string key, out string repr)
		{
			unowned Xmms.Value value;

			if (!dict.dict_get (key, out value)) {
				repr = "%s".printf(_("Unknown"));
				return false;
			}

			return normalize_value (value, key, out repr);
		}

		public static bool normalize_value (Xmms.Value value, string key, out string repr)
		{
			switch (key) {
			case "duration":
				if (duration (value, out repr))
					return true;
				break;
			case "bitrate":
				if (bitrate (value, out repr))
					return true;
				break;
			case "laststarted":
				if (date (value, "laststarted", out repr))
					return true;
				break;
			case "added":
				if (date (value, "added", out repr))
					return true;
				break;
			case "lmod":
				if (date (value, "lmod", out repr))
					return true;
				break;
			case "size":
				if (size (value, out repr))
					return true;
				break;
			default:
				if (generic (value, key, out repr))
					return true;
				break;
			}

			repr = "%s".printf(_("Unknown"));

			return false;
		}

		public static bool size (Xmms.Value val, out string repr)
		{
			int size;

			if (!val.get_int (out size))
				return false;

			repr = "%dkB".printf (size / 1024);

			return true;
		}

		public static bool duration (Xmms.Value val, out string repr)
		{
			int dur_sec, dur_min, duration;

			if (!val.get_int(out duration)) {
				return false;
			}

			dur_min = duration / 60000;
			dur_sec = (duration % 60000) / 1000;

			repr = "%d:%02d".printf (dur_min, dur_sec);

			return true;
		}

		public static bool bitrate (Xmms.Value val, out string repr)
		{
			int bitrate;

			if (!val.get_int(out bitrate)) {
				return false;
			}

			repr = "%.1f kbps".printf (bitrate / 1000.0 );

			return true;
		}

		public static bool date (Xmms.Value val, string key, out string repr)
		{
			int timestamp;

			if (!val.get_int(out timestamp)) {
				return false;
			}

			var now = TimeVal();
			var today_start = now.tv_sec - (now.tv_sec % (60 * 60 * 24));
			var yesterday_start = today_start - (60 * 60 * 24);

			if (today_start < timestamp) {
				repr = _("Today");
			} else if (yesterday_start < timestamp) {
				repr = _("Yesterday");
			} else if (timestamp > 0) {
				var time = Time.gm ((time_t) timestamp);
				repr = time.format ("%Y-%0m-%0d");
			} else {
				repr = _("Never");
			}

			return true;
		}

		public static bool generic (Xmms.Value val, string key, out string repr)
		{
			switch (val.get_type()) {
				case Xmms.ValueType.INT32:
					int tmp;
					if (!val.get_int(out tmp)) {
						return false;
					}
					repr = "%d".printf(tmp);
					break;
				case Xmms.ValueType.STRING:
					if (!val.get_string(out repr)) {
						return false;
					}
					repr = "%s".printf(repr);
					break;
				default:
					return false;
			}

			return true;
		}
	}
}