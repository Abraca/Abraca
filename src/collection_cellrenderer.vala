namespace Abraca {
	public class CollCellRenderer : Gtk.CellRendererText {
		public weak Gdk.Pixbuf pixbuf {
			get; set;
		}

		public override void render (Gdk.Window window, Gtk.Widget widget,
		                             Gdk.Rectangle bg, Gdk.Rectangle cell,
		                             Gdk.Rectangle expose, Gtk.CellRendererState flags) {
			weak Gdk.GC[] gc;

			base.render(window, widget, bg, cell, expose, flags);

			if (pixbuf == null) {
				return;
			}

			gc = widget.style.text_gc;

			window.draw_pixbuf(widget.style.text_gc[0], pixbuf, 0, 0,
			                   cell.x - (pixbuf.width + 4), cell.y,
			                   pixbuf.width, pixbuf.height,
			                   Gdk.RgbDither.NONE, 0, 0);
		}
	}
}
