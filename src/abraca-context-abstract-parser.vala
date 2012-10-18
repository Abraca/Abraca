public abstract class Abraca.AbstractParser<T> : GLib.Object
{
	protected delegate void TextHandler (string text);

	protected GLib.MarkupParseContext context;
	private unowned TextHandler? text_handler;

	protected T builder;

	public void parse (string content, T builder)
		throws MarkupError
	{
		this.builder = builder;
		this.context.parse(content, -1);
		this.builder = null;
	}

	protected void set_text_handler (TextHandler text_handler)
	{
		this.text_handler = text_handler;
	}

	protected static string? find_attribute(string[] keys, string[] values, string attribute)
	{
		for (int i = 0; i < keys.length; i++)
			if (keys[i] == attribute)
				return values[i];
		return null;
	}

	protected void on_text (GLib.MarkupParseContext context, string text, size_t text_len)
		throws MarkupError
	{
		if (text_handler != null) {
			text_handler(text);
			text_handler = null;
		}
	}
}
