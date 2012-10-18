public class Abraca.HTTPClient
{
	private static bool skip_header(GLib.StringBuilder sb, uint8[] data)
	{
		for (var i = 0; i < data.length - 4; i++) {
			if (data[i] == '\r' && data[i + 1] == '\n' && data[i + 2] == '\r' && data[i + 3] == '\n') {
				sb.erase(0, i + 4);
				return true;
			}
		}
		return false;
	}

	public static async string get_content(string host, string url)
		throws GLib.Error
	{
		var client = new GLib.SocketClient();

		var conn = yield client.connect_to_host_async(host, 80);

		var sb = new GLib.StringBuilder();
		sb.append("GET %s HTTP/1.0\r\n".printf(url));
		sb.append("Host: %s\r\n".printf(host));
		sb.append("User-Agent: Abraca\r\n");
		sb.append("\r\n");

		var obuffer = sb.data;

		var os = conn.get_output_stream();
		while (obuffer.length > 0) {
			ssize_t written = yield os.write_async(obuffer);
			if (written == obuffer.length)
				break;
			obuffer = obuffer[written:obuffer.length];
		}

		sb.erase();

		var ibuffer = new uint8[8192];
		ibuffer.length = ibuffer.length - 1;
		ibuffer[ibuffer.length] = 0;

		var header_skipped = true;

		var is = conn.get_input_stream();
		while (true) {
			ssize_t read = yield is.read_async(ibuffer);
			if (read == 0)
				break;

			ibuffer[read] = 0;

			sb.append((string) ibuffer);

			if (header_skipped)
				header_skipped = skip_header(sb, sb.data);
		}

		return sb.str;
	}
}
