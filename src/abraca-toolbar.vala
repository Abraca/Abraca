/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2013 Abraca Team
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

public class Abraca.ToolBar : Gtk.EventBox, Gtk.Buildable {
	private Gtk.Image playback_image_play;
	private Gtk.Image playback_image_pause;
	private Gtk.Image playback_image_stop;

	private Gtk.Button playback_button;

	private Gtk.Button equalizer_button;
	private Gtk.Dialog equalizer_dialog;

	private int duration = 0;
	private uint position = 0;
	private bool is_seeking = false;

	private Gtk.Image coverart;

	private Gtk.Label track_label;
	private Gtk.Scale time_slider;

	private Client client;

	private CoverArtManager manager;

	private static void attach_accelerator (Gtk.Builder builder, string name, string accel)
	{
		Gdk.ModifierType modifier;
		uint key;

		var group = builder.get_object("abraca-accel-group") as Gtk.AccelGroup;
		var button = builder.get_object(name) as Gtk.Button;

		Gtk.accelerator_parse(accel, out key, out modifier);
		button.add_accelerator("activate", group, key, modifier, 0);
	}

	public void parser_finished (Gtk.Builder builder)
	{
		events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
		events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;

		track_label = builder.get_object ("playback-label") as Gtk.Label;
		time_slider = builder.get_object("playback-playtime-slider") as Gtk.Scale;

		attach_accelerator (builder, "playback-btn-prev", "<Primary>Left");
		attach_accelerator (builder, "playback-btn-play-pause-stop", "<Primary>p");
		attach_accelerator (builder, "playback-btn-next", "<Primary>Right");

		playback_button = builder.get_object("playback-btn-play-pause-stop") as Gtk.Button;

		playback_image_play = builder.get_object("playback-img-play") as Gtk.Image;
		playback_image_pause = builder.get_object("playback-img-pause") as Gtk.Image;
		playback_image_stop = builder.get_object("playback-img-stop") as Gtk.Image;

		client = builder.get_object("abraca-client") as Client;
		client.playback_status.connect(on_playback_status_change);
		client.playback_playtime.connect(on_playback_playtime);
		client.connection_state_changed.connect(on_connection_state_changed);
		client.playback_current_info.connect(on_playback_current_info);
		client.playback_current_coverart.connect(on_playback_current_coverart);

		var parent_window = builder.get_object("abraca-parent-window") as Gtk.Window;

		manager = new CoverArtManager (client, parent_window);

		equalizer_dialog = new Gtk.Dialog.with_buttons(
			"Equalizer", parent_window,
			Gtk.DialogFlags.DESTROY_WITH_PARENT
		);
		equalizer_dialog.window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
		var box = equalizer_dialog.get_content_area () as Gtk.Box;
		box.pack_start (new Equalizer (client));

		builder.connect_signals(this);
	}

	public static ToolBar create (Client c, Gtk.Window parent, Gtk.AccelGroup accel_group)
	{
		var builder = new Gtk.Builder ();
		builder.expose_object ("abraca-client", c);
		builder.expose_object ("abraca-parent-window", parent);
		builder.expose_object ("abraca-accel-group", accel_group);

		try {
			builder.add_from_resource ("/org/xmms2/Abraca/ui/toolbar.xml");
		} catch (GLib.Error e) {
			GLib.error (e.message);
		}

		return builder.get_object ("toolbar") as ToolBar;
	}

	private uint fadeout_event_source;

	public override bool enter_notify_event (Gdk.EventCrossing ev)
	{
		if (fadeout_event_source != 0)
			GLib.Source.remove(fadeout_event_source);
		get_style_context().add_class("abraca-toolbar-visible");
		return true;
	}

	private bool on_fadeout ()
	{
		get_style_context().remove_class("abraca-toolbar-visible");
		fadeout_event_source = 0;
		return false;
	}

	public override bool leave_notify_event (Gdk.EventCrossing ev)
	{
		if (ev.x <= 0 || ev.y <= 0 || ev.x >= get_child().get_window().get_width() || ev.y >= get_child().get_window().get_height())
			fadeout_event_source = GLib.Timeout.add(1000, on_fadeout);
		return true;
	}

	protected bool on_time_slider_press (Gdk.EventButton ev, Gtk.Widget widget)
	{
		is_seeking = true;
		time_slider.motion_notify_event.connect(on_time_slider_motion_notify);

		return false;
	}

	protected bool on_time_slider_release (Gdk.EventButton ev, Gtk.Widget widget)
	{
		double percent = (widget as Gtk.Range).get_value();
		uint pos = (uint)(duration * percent);

		client.xmms.playback_seek_ms(pos, Xmms.PlaybackSeekMode.SET);

		time_slider.motion_notify_event.connect (on_time_slider_motion_notify);

		is_seeking = false;

		return false;
	}

	protected bool on_time_slider_scroll (Gdk.EventScroll ev, Gtk.Widget widget)
	{
		if (ev.direction == Gdk.ScrollDirection.UP ||
		    ev.direction == Gdk.ScrollDirection.LEFT) {
			client.xmms.playback_seek_ms (10 * 1000, Xmms.PlaybackSeekMode.CUR);
		} else {
			client.xmms.playback_seek_ms (-10 * 1000, Xmms.PlaybackSeekMode.CUR);
		}

		return true;
	}

	protected bool on_time_slider_motion_notify (Gtk.Widget widget, Gdk.EventMotion ev)
	{
		var percent = (widget as Gtk.Range).get_value();
		position = (uint)(duration * percent);
		return false;
	}

	/*
	private bool on_coverart_tooltip (Gtk.Widget widget, int xpos, int ypos,
	                                  bool mode, Gtk.Tooltip tooltip)
	{
		tooltip.set_icon (client.current_coverart);
		return true;
	}

	private void create_cover_image ()
	{
		coverart = new Gtk.Image();
		coverart.has_tooltip = true;

		var thumbnail = client.current_coverart.scale_simple(32, 32, Gdk.InterpType.BILINEAR);
		coverart.set_from_pixbuf(thumbnail);

		coverart.query_tooltip.connect(on_coverart_tooltip);

		var eventbox = new Gtk.EventBox ();
		eventbox.button_release_event.connect (on_coverart_clicked);
		eventbox.add(coverart);
	}
	*/

	private void update_time_label ()
	{
		/* This is a HACK to circumvent a bug in XMMS2 */
		if (client.current_playback_status == Xmms.PlaybackStatus.STOP) {
			position = 0;
		}

		if (duration > 0) {
			double percent = (double) position / (double) duration;
			time_slider.set_value(percent);
			time_slider.set_sensitive(true);
		} else {
			time_slider.set_value(0);
			time_slider.set_sensitive(false);
		}

		/*
		  uint dur_min, dur_sec, pos_min, pos_sec;
		  string info;

		  dur_min = _duration / 60000;
		  dur_sec = (_duration % 60000) / 1000;

		  pos_min = _pos / 60000;
		  pos_sec = (_pos % 60000) / 1000;

		  info = GLib.Markup.printf_escaped(
		  _("%3d:%02d  of %3d:%02d"),
		  pos_min, pos_sec, dur_min, dur_sec
		  );

		  _time_label.set_markup(info);
		*/
	}

	protected bool on_coverart_clicked (Gtk.Widget w, Gdk.EventButton button)
	{
		manager.update_coverart (client.current_id);
		return false;
	}

	private void on_playback_playtime (Client c, int pos)
	{
		if (!is_seeking) {
			position = pos;
			update_time_label();
		}
	}

	private void on_playback_current_info (Xmms.Value val)
	{
		string title, info, url;

		if (!val.dict_entry_get_int("duration", out duration)) {
			duration = 0;
		}

		if (val.dict_entry_get_string("title", out title)) {
			string artist, album;
			if (!val.dict_entry_get_string("artist", out artist)) {
				artist = _("Unknown");
			}

			if (!val.dict_entry_get_string("album", out album)) {
				album = _("Unknown");
			}

			info = GLib.Markup.printf_escaped(
				"<b>%s</b>\n" + _("<span size=\"small\"><span size=\"smaller\" foreground=\"#666666\"><i>by</i></span><b> %s </b><span size=\"smaller\" foreground=\"#666666\"><i>on</i></span> <b>%s</b></span>"),
				title, artist, album
				);
		} else if (val.dict_entry_get_string("url", out url)) {
			info = GLib.Markup.printf_escaped("<b>%s</b>", url);
		} else {
			info = "%s".printf("Unknown");
		}

		track_label.set_markup(info);

		update_time_label();
	}

	private void on_playback_current_coverart (Gdk.Pixbuf? pixbuf)
	{
		var thumbnail = pixbuf.scale_simple(32, 32, Gdk.InterpType.BILINEAR);
		coverart.set_from_pixbuf(thumbnail);
	}

	protected void on_media_play (Gtk.Button button)
	{
		if (client.current_playback_status == Xmms.PlaybackStatus.PLAY) {
			client.xmms.playback_pause();
		} else {
			client.xmms.playback_start();
		}
	}

	protected void on_media_stop (Gtk.Button button)
	{
		client.xmms.playback_stop();
	}

	protected void on_media_prev (Gtk.Button button)
	{
		client.xmms.playlist_set_next_rel(-1);
		client.xmms.playback_tickle();
	}

	protected void on_media_next (Gtk.Button button)
	{
		client.xmms.playlist_set_next_rel(1);
		client.xmms.playback_tickle();
	}

	private void on_playback_status_change (Client c, int status)
	{
		switch (client.current_playback_status) {
		case Xmms.PlaybackStatus.PLAY:
			playback_button.image = playback_image_pause;
			break;
		default:
			playback_button.image = playback_image_play;
			break;
		}

		if (client.current_playback_status == Xmms.PlaybackStatus.STOP) {
			update_time_label();
		}
	}

	/**
	 * Only make the equalizer icon sensitive if we have an equalizer in the chain.
	 */
	private bool on_list_plugins (Xmms.Value value)
	{
		unowned Xmms.ListIter iter;

		equalizer_button.sensitive = false;

		for (value.get_list_iter(out iter); iter.valid(); iter.next()) {
			Xmms.Value entry;
			string name;

			if (!iter.entry(out entry)) {
				continue;
			}

			if (!entry.dict_entry_get_string("shortname", out name)) {
				continue;
			}

			if (name == "equalizer") {
				equalizer_button.sensitive = true;
			}
		}

		return true;
	}

	private void on_connection_state_changed (Client client, Client.ConnectionState state)
	{
		if (state != Client.ConnectionState.Connected) {
			return;
		}

		client.xmms.main_list_plugins(Xmms.PluginType.XFORM).notifier_set (
			on_list_plugins
		);
	}

	protected void on_equalizer_show (Gtk.Button button)
	{
		equalizer_dialog.show_all ();
		equalizer_dialog.run ();
		equalizer_dialog.hide ();
	}
}
