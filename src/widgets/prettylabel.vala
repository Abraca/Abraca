namespace Abraca {
	public class PrettyLabel : Gtk.DrawingArea, Gtk.Buildable
	{
		public string label { get; set; }

		construct
		{
			set_size_request (100, 40);
		}

		public PrettyLabel (string str)
		{
			label = str;

		}

		public override bool expose_event (Gdk.EventExpose ev)
		{
			var cr = Gdk.cairo_create (this.window);

			var width = ev.area.width;
			var height = ev.area.height;

			cr.set_source_rgb(152/255.0, 186/255.0, 94/255.0);
			cr.rectangle(ev.area.x, ev.area.y, ev.area.width, ev.area.height);
			cr.stroke_preserve();

			cr.fill_preserve();
			cr.clip();

			var linear = new Cairo.Pattern.linear(0.0, 0.0, 0, height/2);
			linear.add_color_stop_rgba(0.0, 153/255.0, 190/255.0, 90/255.0, 1);
			linear.add_color_stop_rgba(1.0, 180/255.0, 211/255.0, 131/255.0, 1);

			cr.set_source_rgb(1.59, 0.72, 0.36);
			cr.move_to(-50, 0);
			cr.line_to(width+20, 0);
			cr.line_to(width+20, height/2);
			cr.curve_to(width+50,height/4, width-50, 3*height/4, width/2, height/2);
			cr.curve_to(50, height/4, -50, 3*height/4, -50, height/2);
			cr.line_to(-50, 0);
			cr.set_source(linear);
			cr.fill();

			cr.select_font_face("Liberation Sans", Cairo.FontSlant.NORMAL,
			                    Cairo.FontWeight.NORMAL);

			var font_size = 24;

			cr.set_font_size(font_size);

			cr.set_source_rgba(0.0,0.0,0.0, 0.5);

			cr.move_to(10, height/2+font_size/2-2);
			cr.show_text(this.label);

			cr.move_to(9, height/2+font_size/2-2-2);
			cr.show_text(this.label);

			cr.set_source_rgb(1,1,1);

			cr.move_to(10-1, height/2+font_size/2-1-2);
			cr.show_text(this.label);

			return false;
		}
	}
}
