/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <gtk/gtk.h>

#include "abraca.h"
#include "buttons.h"
#include "misc.h"
#include "playlist.h"
#include "util.h"

#define TRACK_LABEL_FORMAT_TRACK \
    "<b><big>%s</big></b>\n<small>by</small> %s <small>from</small> %s"

void
widget_set_sensitive_by_name (const gchar *name, gboolean sensitive)
{
    GtkWidget *widget;

    widget = glade_xml_get_widget (glade_xml, name);

    if (widget)
        gtk_widget_set_sensitive (widget, sensitive);

    /*
    if (current_track.status == XMMS_PLAYBACK_STATUS_PLAY)
        gtk_widget_set_sensitive (widget, TRUE);
    else
        gtk_widget_set_sensitive (widget, FALSE);
        */
}

void
position_scale_update (guint time)
{
    static GtkWidget *scale = NULL;
    gdouble percentage;

    if (!scale)
        scale = glade_xml_get_widget (glade_xml, "position_scale");

    if (current_track.duration > 0)
        percentage = (gdouble) time / (gdouble) current_track.duration;
    else
        percentage = 0;

    gtk_range_set_value (GTK_RANGE (scale), 100 * percentage);
}

void
time_label_update (guint time)
{
    static GtkWidget *label = NULL;
    gchar *tmp;

    if (!label)
        label = glade_xml_get_widget (glade_xml, "time_label");

    tmp = g_strdup_printf ("<small>%d:%02d / %d:%02d</small>",
            time / 60000, time / 1000 - (time / 60000) * 60,
            current_track.duration_min, current_track.duration_sec);

    gtk_label_set_markup (GTK_LABEL (label), tmp);

    g_free (tmp);
}

void
track_label_update (void)
{
    static GtkWidget *tracklabel = NULL;
    gchar *title, *track;

    if (!tracklabel)
        tracklabel = glade_xml_get_widget (glade_xml, "track_label");

    if (current_track.title)
        title = g_strdup (current_track.title);
    else
        title = g_strdup ("Unknown");

    if (current_track.artist && current_track.album)
        track = g_markup_printf_escaped (TRACK_LABEL_FORMAT_TRACK,
                title, current_track.artist, current_track.album);
    else if (current_track.artist)
        track = g_markup_printf_escaped (TRACK_LABEL_FORMAT_TRACK,
                title, current_track.artist, "Unknown");
    else if (current_track.album)
        track = g_markup_printf_escaped (TRACK_LABEL_FORMAT_TRACK,
                title, "Unknown", current_track.album);
    else
        track = g_markup_printf_escaped (TRACK_LABEL_FORMAT_TRACK,
                title, "Unknown", "Unknown");
    gtk_label_set_markup (GTK_LABEL (tracklabel), track);

    g_free (title);
    g_free (track);
}

void
window_title_update (void)
{
    static GtkWidget *window = NULL;
    gchar *title;

    if (!window)
        window = glade_xml_get_widget (glade_xml, "main_window");

    if (current_track.title && current_track.artist)
        title = g_strdup_printf ("%s - %s", current_track.title,
                current_track.artist);
    else if (current_track.artist)
        title = g_strdup_printf ("Unknown - %s", current_track.artist);
    else if (current_track.title)
        title = g_strdup_printf ("%s - Unknown", current_track.title);
    else
        title = g_strdup ("Abraca");
    gtk_window_set_title (GTK_WINDOW (window), title);

    g_free (title);
}


void
playlist_treeview_focus (void)
{
    static GtkWidget *treeview = NULL;

    if (!treeview)
        treeview = glade_xml_get_widget (glade_xml, "playlist_treeview");

    gtk_widget_grab_focus (treeview);
}

GdkPixbuf *
pixbuf_from_string (const guchar *data, gint len)
{
    GdkPixbuf *p = NULL;
    GdkPixbufLoader *loader;

    if (len > 0) {
        loader = gdk_pixbuf_loader_new ();
        gdk_pixbuf_loader_write (loader, data, len, NULL);
        gdk_pixbuf_loader_close (loader, NULL);
        p = gdk_pixbuf_loader_get_pixbuf (loader);
    }

    return p;
}

void
cover_image_set_pixbuf (GdkPixbuf *p)
{
    static GtkWidget *image = NULL;
    GdkPixbuf *pix;

    if (!image)
        image = glade_xml_get_widget (glade_xml, "cover_image");

    pix = gdk_pixbuf_scale_simple (p, 32, 32, GDK_INTERP_BILINEAR);

    gtk_image_set_from_pixbuf (GTK_IMAGE (image), pix);
    g_object_unref (pix);
}

void
cover_image_set_from_icon_name (const gchar *name)
{
    static GtkWidget *image = NULL;

    if (!image)
        image = glade_xml_get_widget (glade_xml, "cover_image");

    gtk_image_set_from_icon_name (GTK_IMAGE (image), name, GTK_ICON_SIZE_DND);
}

void
menu_popup (const gchar *name, guint button)
{
    GtkWidget *menu;

    menu = glade_xml_get_widget (glade_xml, name);

    if (menu)
        gtk_menu_popup (GTK_MENU (menu), NULL, NULL, NULL, NULL, button,
                gtk_get_current_event_time ());
}


/* XMMS2 Callbacks */

void
bc_playback_current_id (xmmsc_result_t *res, void *userdata)
{
    guint id;
    xmmsc_result_t *r;

    if (xmmsc_result_get_uint (res, &id)) {
        abraca_debug ("bc_playback_current_id: %d\n", id);

        r = xmmsc_medialib_get_info (xcon, id);
        xmmsc_result_notifier_set (r, sg_medialib_get_info, xcon);
        xmmsc_result_unref (r);
    }

    XMMS_CALLBACK_SET (xcon, xmmsc_playback_playtime,
            cb_playback_playtime, NULL);
    XMMS_CALLBACK_SET (xcon, xmmsc_playback_status,
            bc_playback_status, NULL);
}

void
bc_playback_status (xmmsc_result_t *res, void *userdata)
{
    guint status;

    if (xmmsc_result_get_uint (res, &status)) {
        abraca_debug ("bc_playback_status: %d\n", status);
        current_track.status = status;
        switch (status) {
            case XMMS_PLAYBACK_STATUS_STOP:
                pp_button_set_image ("gtk-media-play");
                playlist_model_set_status (playlist_position, "gtk-media-stop");
                position_scale_update (0);
                time_label_update (0);
                widget_set_sensitive_by_name ("position_scale", FALSE);
                break;
            case XMMS_PLAYBACK_STATUS_PLAY:
                pp_button_set_image ("gtk-media-pause");
                playlist_model_set_status (playlist_position, "gtk-media-play");
                widget_set_sensitive_by_name ("position_scale", TRUE);
                break;
            default:
                pp_button_set_image ("gtk-media-play");
                playlist_model_set_status (playlist_position,
                        "gtk-media-pause");
                widget_set_sensitive_by_name ("position_scale", FALSE);
                break;
        }
    }
}

void
cb_playback_playtime (xmmsc_result_t *res, void *userdata)
{
    guint time;

    if (xmmsc_result_get_uint (res, &time)) {
        abraca_debug ("cb_playback_playtime: %d\n", time);

        position_scale_update (time);
        time_label_update (time);
    }

    xmmsc_result_unref (res);
}

void
cb_bindata_retrieve (xmmsc_result_t *res, void *userdata)
{
    guchar *data;
    guint len;

    abraca_debug ("cb_bindata_retrieve\n");
    if (xmmsc_result_get_bin (res, &data, &len)) {
        current_track.cover = pixbuf_from_string (data, len);
        cover_image_set_pixbuf (current_track.cover);
    }
    else
        cover_image_set_from_icon_name ("media-optical");
}

void
sg_medialib_get_info (xmmsc_result_t *res, void *userdata)
{
    xmmsc_result_t *r;

    track_free (&current_track);
    current_track = track_set_info (res);

    abraca_debug ("sg_medialib_get_info:\n");
    abraca_debug ("\tArtist: %s\n", current_track.artist);
    abraca_debug ("\tAlbum: %s\n", current_track.album);
    abraca_debug ("\tTitle: %s\n", current_track.title);
    abraca_debug ("\tComment: %s\n", current_track.comment);
    abraca_debug ("\tGenre: %s\n", current_track.genre);
    abraca_debug ("\tUrl: %s\n", current_track.url);
    abraca_debug ("\tPicture Front: %s\n", current_track.picture_front);
    abraca_debug ("\tID: %d\n", current_track.id);
    abraca_debug ("\tDuration: %d\n", current_track.duration);

    if (current_track.picture_front) {
        r = xmmsc_bindata_retrieve (xcon, current_track.picture_front);
        xmmsc_result_notifier_set (r, cb_bindata_retrieve, NULL);
        xmmsc_result_unref (r);
    }
    else
        cover_image_set_from_icon_name ("media-optical");

    track_label_update ();
    window_title_update ();
}


/* Gtk Callbacks */

void
on_mainwindow_destroy (GtkObject *object, gpointer user_data)
{
    gtk_main_quit ();
}

gboolean
on_position_change_value (GtkRange *range, GtkScrollType scroll,
        gdouble value, gpointer user_data)
{
    guint time;
    gdouble percentage;

    if (xcon) {
        percentage = gtk_range_get_value (range);

        if (current_track.duration > 0) {
            time = (percentage * current_track.duration) / 100;
            xmmsc_playback_seek_ms (xcon, time);
        }
    }

    return FALSE;
}

void
on_help_about_menu_item_activate (GtkMenuItem *menuitem, gpointer userdata)
{
    static GtkWidget *parent = NULL;
    static const gchar *authors[] = {
        "Sebastian Sareyko <smoon@nooms.de>",
        "Martin Salzer <stoky@gmx.net>",
        NULL
    };
    static const gchar license[] = {
"Redistribution and use in source and binary forms, with or without\n"
"modification, are permitted provided that the following conditions are met:\n"
"\n"
"  * Redistributions of source code must retain the above copyright notice,\n"
"    this list of conditions and the following disclaimer.\n"
"\n"
"  * Redistributions in binary form must reproduce the above copyright notice,\n"
"    this list of conditions and the following disclaimer in the documentation\n"
"    and/or other materials provided with the distribution.\n"
"\n"
"  * Neither the name of the project nor the names of its contributors\n"
"    may be used to endorse or promote products derived from this software\n"
"    without specific prior written permission.\n"
"\n"
"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS\n"
"\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT\n"
"LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR\n"
"A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR\n"
"CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,\n"
"EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,\n"
"PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR\n"
"PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF\n"
"LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING\n"
"NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS\n"
"SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
    };

    if (!parent)
        parent = glade_xml_get_widget (glade_xml, "main_window");

    gtk_show_about_dialog (GTK_WINDOW (parent),
                "name", "Abraca",
                "version", VERSION,
                "comments", _ ("A client for the xmms2 music player"),
                "authors", authors,
                "copyright", "Copyright \xc2\xa9 2007 Sebastian Sareyko",
                "website", "http://nooms.de/projects/abraca/",
                "license", license,
                "destroy-with-parent", TRUE,
                NULL);
}

/* aka "make the dialog stop disappearing on pressing the escape key" */
gboolean
on_dialog_delete_event (GtkWidget *widget, GdkEvent *event,
        gpointer user_data)
{
    gtk_widget_hide (widget);

    return TRUE;
}
