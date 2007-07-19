/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <xmmsclient/xmmsclient-glib.h>
#include <glade/glade.h>
#include <gtk/gtk.h>
#include <stdlib.h>
#include <unistd.h>

#include "abraca.h"
#include "collections.h"
#include "filter.h"
#include "medialib.h"
#include "misc.h"
#include "playlist.h"

/* YAY for global variables! */
GladeXML *glade_xml = NULL;
xmmsc_connection_t *xcon = NULL;
track current_track;
gchar *active_playlist = NULL;
guint playlist_position = 0;

/* FIXME: creating some parent containers and list them here would be
 * nicer, but unfortunately Glade looses signal handler names and other
 * stuff on copy/pasting. bleh */
static const gchar *widgets[] = {
    "toolbar_hbox",
    /*
    "track_label",
    "cover_image",
    "time_label",
    "position_scale",
    "fwd_button",
    "back_button",
    "stop_button",
    */
    "playlist_treeview",
    "collections_treeview",
    "filter_treeview",
    "filter_entry",
    "playlist_label",
    "filter_label",
    "playlist_menu_item",
    "add_menu_item",
    "filter_save_menu_item",
    NULL
};

static gboolean xmmscom_poll_playback_playtime (gpointer data);
static xmmsc_connection_t *xmmscom_connect (void);
static void disconnect_callback (void *user_data);
static void setup_callbacks (void);


static gboolean
xmmscom_poll_playback_playtime (gpointer data)
{
    if (xcon) {
        XMMS_CALLBACK_SET (xcon, xmmsc_signal_playback_playtime,
                cb_playback_playtime, NULL);
    }
    else {
        xcon = xmmscom_connect ();
        setup_callbacks ();
    }

    return TRUE;
}

static xmmsc_connection_t
*xmmscom_connect (void)
{
    xmmsc_connection_t *con;
    gint i;

    con = xmmsc_init ("abraca");
    if (!con) {
        for (i = 0; widgets[i]; i++)
            widget_set_sensitive_by_name (widgets[i], FALSE);

        return NULL;
    }

    if (!xmmsc_connect (con, getenv ("XMMS_PATH"))) {
        for (i = 0; widgets[i]; i++)
            widget_set_sensitive_by_name (widgets[i], FALSE);

        con = NULL;
    }
    else {
        for (i = 0; widgets[i]; i++)
            widget_set_sensitive_by_name (widgets[i], TRUE);

        xmmsc_mainloop_gmain_init (con);
    }

    return con;
}

static void
disconnect_callback (void *user_data)
{
    gint i;

    xcon = NULL;

    for (i = 0; widgets[i]; i++)
        widget_set_sensitive_by_name (widgets[i], FALSE);

    playlist_model_clear ();
    filter_model_clear ();
    collections_model_clear ();
}

static void
setup_callbacks (void)
{
    xmmsc_result_t *r;

    if (xcon) {
        XMMS_CALLBACK_SET (xcon, xmmsc_broadcast_playback_current_id,
                bc_playback_current_id, xcon);
        XMMS_CALLBACK_SET (xcon, xmmsc_broadcast_playback_status,
                bc_playback_status, xcon);
        XMMS_CALLBACK_SET (xcon, xmmsc_broadcast_playlist_current_pos,
                bc_playlist_current_pos, xcon);
        XMMS_CALLBACK_SET (xcon, xmmsc_broadcast_playlist_changed,
                bc_playlist_changed, xcon);
        XMMS_CALLBACK_SET (xcon, xmmsc_broadcast_playlist_loaded,
                bc_playlist_loaded, xcon);
        XMMS_CALLBACK_SET (xcon, xmmsc_broadcast_collection_changed,
                bc_collection_changed, xcon);

        xmmsc_disconnect_callback_set (xcon, disconnect_callback, NULL);

        XMMS_CALLBACK_SET (xcon, xmmsc_playback_current_id,
                bc_playback_current_id, xcon);
        r = xmmsc_coll_list (xcon, XMMS_COLLECTION_NS_COLLECTIONS);
        xmmsc_result_notifier_set (r, cb_coll_list,
                XMMS_COLLECTION_NS_COLLECTIONS);
        xmmsc_result_unref (r);
        r = xmmsc_coll_list (xcon, XMMS_COLLECTION_NS_PLAYLISTS);
        xmmsc_result_notifier_set (r, cb_coll_list,
                XMMS_COLLECTION_NS_PLAYLISTS);
        xmmsc_result_unref (r);
        XMMS_CALLBACK_SET (xcon, xmmsc_playlist_current_active,
                cb_playlist_current_active, xcon);
    }
}

gint
main (gint argc, gchar **argv)
{
    gchar *tmp, cwd[1024];
    GtkWidget *mainwin;

#ifdef ENABLE_NLS
    setlocale (LC_ALL, "");
    bindtextdomain ("abraca", LOCALE_DIR);
    textdomain ("abraca");
#endif

    track_nullify (&current_track);

    gtk_init (&argc, &argv);

    /* Glade/GTK+ init stuff */
    tmp = g_build_path (PATHSEP, PACKAGE_DATA_DIR, "abraca.glade", NULL);
    glade_xml = glade_xml_new (tmp, NULL, NULL);
    g_free (tmp);
    /* yay, glade filesearching schmoo */
    if (!glade_xml) {
        getcwd (cwd, sizeof (cwd));
        tmp = g_build_path (PATHSEP, cwd, "data", "abraca.glade",
                NULL);
        glade_xml = glade_xml_new (tmp, NULL, NULL);
        g_free (tmp);

        if (!glade_xml) {
            g_error (_("Failed to load glade file!\n"));
            return (EXIT_FAILURE);
        }
    }

    mainwin = glade_xml_get_widget (glade_xml, "main_window");
    gtk_widget_show (mainwin);

    playlist_view_init ();
    filter_view_init ();
    collections_view_init ();

    glade_xml_signal_autoconnect (glade_xml);

    /* initialize xmms2 */
    xcon = xmmscom_connect ();

    /* xmms2 callbacks */
    setup_callbacks ();

    /* FIXME: use this instead with glib 2.14
       g_timeout_add_seconds (1, poll_playback_playtime, xcon);
    */
    g_timeout_add (1000, xmmscom_poll_playback_playtime, xcon);

    gtk_main ();

    if (xcon)
        xmmsc_unref (xcon);

    return (EXIT_SUCCESS);
}
