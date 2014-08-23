/**
 * SubZero, a MDNS browser.
 * Copyright (C) 2012 Daniel Svensson
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

internal class SubZero.Util
{
	/**
	 * Dump buffer in a readable layout according to:
	 * 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  a a a a a a a a  a a a a a a a a
	 * ....
	 * Crude crude crude, but usable hack.
	 */
	public static void hexdump(uint8[] buffer)
	{
		var sb = new GLib.StringBuilder();
		sb.append("0000: ");
		var i = 0;
		for (; i < buffer.length; i++) {
			sb.append_printf("%02x ", buffer[i]);
			if (((i+1) % 8) == 0)
				sb.append(" ");
			if (((i+1) % 16) == 0) {
				for (var j = i - 15; j < buffer.length && j <= i; j++) {
					uint8 b = buffer[j];
					sb.append_printf("%c ", (b >= 0x21 && b <= 0x7e) ? b : '.');
					if (((j+1) % 8) == 0)
						sb.append(" ");
				}
				sb.append_printf("\n%04x: ", i + 1);
			}
		}

		if ((i % 16) != 0) {
			var r = 0;
			for (var j = 1; j < (50 - (i % 16) * 3); j++)
				sb.append(" ");
			for (var j = i - (i % 16); j < buffer.length && j <= i; j++, r++) {
				uint8 b = buffer[j];
				sb.append_printf("%c ", (b >= 0x21 && b <= 0x7e) ? b : '.');
				if (((r+1) % 8) == 0)
					sb.append(" ");
			}
			sb.append("\n");
		}

		GLib.debug("Dump:\n\n%s", sb.str);
	}
}