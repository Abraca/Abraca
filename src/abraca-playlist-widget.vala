/* GtkScrolledWindow is final in GTK4, so wrap it rather than subclass. */
public class Abraca.PlaylistWidget : Gtk.Widget {
	private Gtk.ScrolledWindow scrolled;

	public PlaylistWidget (Client client, MetadataResolver resolver, Config config, Medialib medialib, Searchable search)
	{
		set_layout_manager (new Gtk.BinLayout ());
		hexpand = true;
		vexpand = true;

		scrolled = new Gtk.ScrolledWindow ();
		scrolled.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scrolled.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;

		var model = new PlaylistModel(client, resolver);
		scrolled.set_child(new PlaylistView(model, client, medialib, config, search));

		scrolled.set_parent (this);
	}

	public override void dispose ()
	{
		if (scrolled != null) {
			scrolled.unparent ();
			scrolled = null;
		}
		base.dispose ();
	}
}
