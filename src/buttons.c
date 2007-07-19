/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <glade/glade.h>
#include <gtk/gtk.h>

#include "abraca.h"
#include "buttons.h"
#include "misc.h"
#include "playlist.h"
#include "util.h"

static void cb_playback_status (xmmsc_result_t *res, void *userdata);
static void playlist_set_next_rel (gint pos);


static void
playlist_set_next_rel (gint pos)
{
    if (xcon)
        switch (current_track.status) {
            case XMMS_PLAYBACK_STATUS_STOP:
                xmmsc_playlist_set_next_rel (xcon, pos);
                xmmsc_playback_start (xcon);
                break;
            case XMMS_PLAYBACK_STATUS_PAUSE:
                xmmsc_playlist_set_next_rel (xcon, pos);
                xmmsc_playback_start (xcon);
                xmmsc_playback_tickle (xcon);
                break;
            case XMMS_PLAYBACK_STATUS_PLAY:
                xmmsc_playlist_set_next_rel (xcon, pos);
                xmmsc_playback_tickle (xcon);
                break;
        }
}

void
pp_button_set_image (const gchar *stock_image)
{
    static GtkWidget *img = NULL;

    if (!img)
        img = glade_xml_get_widget (glade_xml, "pp_image");

    gtk_image_set_from_stock (GTK_IMAGE (img), stock_image, 4);
}


/* XMMS2 Callbacks */

static void
cb_playback_status (xmmsc_result_t *res, void *userdata)
{
    guint status;

    if (xmmsc_result_get_uint (res, &status)) {
        abraca_debug ("cb_playback_status: %d\n", status);
        switch (status) {
            case XMMS_PLAYBACK_STATUS_PLAY:
                xmmsc_playback_pause (xcon);
                break;
            default:
                xmmsc_playback_start (xcon);
                break;
        }
    }
}


/* Gtk+ Callbacks */

void
on_ppbutton_clicked (GtkButton *button, gpointer user_data)
{
    if (xcon) {
        XMMS_CALLBACK_SET (xcon, xmmsc_playback_status,
                cb_playback_status, xcon);
    }
}

void
on_stopbutton_clicked (GtkButton *button, gpointer user_data)
{
    if (xcon)
        xmmsc_playback_stop (xcon);
}

void
on_backbutton_clicked (GtkButton *button, gpointer user_data)
{
    playlist_set_next_rel (-1);
}

void
on_fwdbutton_clicked (GtkButton *button, gpointer user_data)
{
    playlist_set_next_rel (1);
}
