/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 *                    Martin Salzer <stoky at gmx dot net>
 * See COPYING file for details.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>
#include <string.h>

#include "abraca.h"
#include "filter.h"
#include "misc.h"
#include "playlist.h"
#include "util.h"

void
filter_view_init (void)
{
    GtkWidget *filter;
    GtkCellRenderer *text_renderer;
    GtkCellRenderer *image_renderer;
    GtkTreeViewColumn *column;
    GtkTreeSelection *sel;

    filter = glade_xml_get_widget (glade_xml, "filter_treeview");

    image_renderer = gtk_cell_renderer_pixbuf_new ();
    text_renderer = gtk_cell_renderer_text_new ();

    /* ID */
    column = gtk_tree_view_column_new_with_attributes (
            _ ("ID"), text_renderer, "text", COL_FILTER_ID, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_ID);

    /* Artist */
    column = gtk_tree_view_column_new_with_attributes (
            _ ("Artist"), text_renderer, "text", COL_FILTER_ARTIST, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_ARTIST);

    /* Title */
    column = gtk_tree_view_column_new_with_attributes (
            _ ("Title"), text_renderer, "text", COL_FILTER_TITLE, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_TITLE);

    /* Album */
    column = gtk_tree_view_column_new_with_attributes (
            _ ("Album"), text_renderer, "text", COL_FILTER_ALBUM, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_ALBUM);

    /* Duration */
    /* FIXME: alignment */
    column = gtk_tree_view_column_new_with_attributes (
            _ ("Duration"), text_renderer, "text", COL_FILTER_DURATION, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_DURATION);

    /* URL */
    /*
    column = gtk_tree_view_column_new_with_attributes (
            _ ("URL"), text_renderer, "text", COL_FILTER_URL, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_URL);
    */

    /* Genre */
    column = gtk_tree_view_column_new_with_attributes (
            _ ("Genre"), text_renderer, "text", COL_FILTER_GENRE, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_GENRE);

    /* Comment */
    /*
    column = gtk_tree_view_column_new_with_attributes (
            _ ("Comment"), text_renderer, "text", COL_FILTER_COMMENT, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (filter), column);
    gtk_tree_view_column_set_sort_column_id (column, COL_FILTER_COMMENT);
    */

    sel = gtk_tree_view_get_selection (GTK_TREE_VIEW (filter));
    gtk_tree_selection_set_mode (sel, GTK_SELECTION_MULTIPLE);
}

void
filter_model_insert_track (track *t, GdkPixbuf *p, gint pos)
{
    static GtkWidget *filter = NULL;
    static GtkListStore *store = NULL;
    static GtkTreeIter iter;
    gchar *dur;

    if (!filter)
        filter = glade_xml_get_widget (glade_xml, "filter_treeview");

    if (!store)
        store = gtk_list_store_new (NUM_FILTER_COLS,
                G_TYPE_INT, G_TYPE_STRING, G_TYPE_STRING,
                G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING,
                G_TYPE_STRING, G_TYPE_STRING);

    dur = g_strdup_printf ("%d:%02d", t->duration_min, t->duration_sec);
    if (pos >= 0)
        gtk_list_store_insert (store, &iter, pos);
    else
        gtk_list_store_append (store, &iter);
    gtk_list_store_set (store, &iter,
            COL_FILTER_ID, t->id,
            COL_FILTER_ARTIST, t->artist,
            COL_FILTER_TITLE, t->title,
            COL_FILTER_ALBUM, t->album,
            COL_FILTER_DURATION, dur,
            COL_FILTER_URL, t->url,
            COL_FILTER_GENRE, t->genre,
            COL_FILTER_COMMENT, t->comment,
            -1);
    g_free (dur);

    gtk_tree_view_set_model (GTK_TREE_VIEW (filter), GTK_TREE_MODEL (store));
}

void
filter_model_clear (void)
{
    static GtkWidget *filter = NULL;
    static GtkTreeModel *store = NULL;

    if (!filter)
        filter = glade_xml_get_widget (glade_xml, "filter_treeview");

    if (!store)
        store = gtk_tree_view_get_model (GTK_TREE_VIEW (filter));

    if (store)
        gtk_list_store_clear (GTK_LIST_STORE (store));
}

void
filter_entry_set_text (const gchar *str)
{
    static GtkWidget *entry = NULL;

    if (!entry)
        entry = glade_xml_get_widget (glade_xml, "filter_entry");

    gtk_entry_set_text (GTK_ENTRY (entry), str);
    g_signal_emit_by_name (entry, "activate");
}

void
filter_entry_focus (void)
{
    static GtkWidget *entry = NULL;

    if (!entry)
        entry = glade_xml_get_widget (glade_xml, "filter_entry");

    gtk_widget_grab_focus (entry);
}

/*
gchar *
filter_entry_get_text (void)
{
    static GtkWidget *entry = NULL;
    gchar *text;

    if (!entry)
        entry = glade_xml_get_widget (glade_xml, "filter_entry");

    text = g_strdup (gtk_entry_get_text (GTK_ENTRY (entry)));

    return text;
}
*/


/* XMMS2 Callbacks */

void
cb_coll_query_ids (xmmsc_result_t *res, void *userdata)
{
    guint id;
    xmmsc_result_t *r;

    abraca_debug ("cb_coll_query_ids:\n");
    filter_model_clear ();
    while (xmmsc_result_list_valid (res)) {
        if (xmmsc_result_get_uint (res, &id)) {
            abraca_debug ("\t%d\n", id);

            r = xmmsc_medialib_get_info (xcon, id);
            xmmsc_result_notifier_set (
                    r, sg_medialib_get_info_filter_insert, (gpointer) -1);
            xmmsc_result_unref (r);
        }

        xmmsc_result_list_next (res);
    }
}

void
sg_medialib_get_info_filter_insert (xmmsc_result_t *res, void *userdata)
{
    track t;

    t = track_set_info (res);

    abraca_debug ("sg_medialib_get_info_filter_insert:\n");
    abraca_debug ("\tArtist: %s\n", t.artist);
    abraca_debug ("\tAlbum: %s\n", t.album);
    abraca_debug ("\tTitle: %s\n", t.title);
    abraca_debug ("\tComment: %s\n", t.comment);
    abraca_debug ("\tGenre: %s\n", t.genre);
    abraca_debug ("\tUrl: %s\n", t.url);
    abraca_debug ("\tPicture Front: %s\n", t.picture_front);
    abraca_debug ("\tID: %d\n", t.id);
    abraca_debug ("\tDuration: %d\n", t.duration);

    filter_model_insert_track (&t, NULL, (gint) userdata);
    track_free (&t);
}


/* Gtk Callbacks */

void
on_filter_entry_activate (GtkEntry *entry, gpointer userdata)
{
    static GtkWidget *view = NULL;
    gchar *entry_text;
    xmmsc_coll_t *query;
    xmmsc_result_t *r;

    if (xcon) {
        if (!view)
            view = glade_xml_get_widget (glade_xml, "filter_treeview");

        entry_text = g_strdup (gtk_entry_get_text (entry));
        g_strstrip (entry_text);

        if (strlen (entry_text) && (query = str_to_coll_query (entry_text))) {
            r = xmmsc_coll_query_ids (xcon, query, NULL, 0, 0);
            xmmsc_result_notifier_set (r, cb_coll_query_ids, xcon);
            xmmsc_result_unref (r);

            g_object_set_data (G_OBJECT (view), "query", (gpointer) query);
        }

        g_free (entry_text);
    }
}

gboolean
on_filter_treeview_key_release_event (GtkWidget *widget,
        GdkEventKey *event, gpointer user_data)
{
    abraca_debug ("on_filter_treeview_key_release_event: %d\n",
            event->keyval);

    switch (event->keyval) {
        case GDK_Delete:
            on_filter_context_remove_menu_item_activate (NULL, NULL);
            break;
        default:
            break;
    }

    return FALSE;
}

gboolean
on_filter_treeview_button_press_event (GtkWidget *widget, GdkEventButton *event,
        gpointer user_data)
{
    static GtkTreeModel *model = NULL;

    if (!model)
        model = gtk_tree_view_get_model (GTK_TREE_VIEW (widget));

    if (model && (gtk_tree_model_iter_n_children (model, NULL) > 0) &&
            (event->button == 3)) {
        menu_popup ("filter_menu", event->button);

        return TRUE;
    }

    return FALSE;
}

void
on_filter_treeview_row_activated (GtkTreeView *view, GtkTreePath *path,
        GtkTreeViewColumn *col, gpointer user_data)
{
    static GtkTreeModel *model = NULL;
    GtkTreeIter iter;
    gint id = 0;

    if (xcon) {
        if (!model)
            model = gtk_tree_view_get_model (view);

        gtk_tree_model_get_iter (model, &iter, path);
        gtk_tree_model_get (model, &iter, COL_FILTER_ID, &id, -1);

        xmmsc_playlist_add_id (xcon, XMMS_ACTIVE_PLAYLIST, id);
    }
}

void
on_filter_save_menu_item_activate (GtkMenuItem *menuitem, gpointer userdata)
{
    static GtkWidget *dialog = NULL;

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "collection_new_dialog");

    gtk_widget_show (dialog);
}

void
on_filter_add_menu_item_activate (GtkMenuItem *menuitem, gpointer userdata)
{
    static GtkWidget *view = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeIter iter;
    guint id;

    if (xcon) {
        if (!view)
            view = glade_xml_get_widget (glade_xml, "filter_treeview");

        if (!store)
            store = gtk_tree_view_get_model (GTK_TREE_VIEW (view));

        if (store) {
            if (gtk_tree_model_get_iter_first (store, &iter))
                do {
                    gtk_tree_model_get (store, &iter, COL_FILTER_ID, &id, -1);
                    xmmsc_playlist_add_id (xcon, XMMS_ACTIVE_PLAYLIST, id);
                } while (gtk_tree_model_iter_next (store, &iter));
        }
    }
}

void
on_filter_context_add_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata)
{
    static GtkWidget *view = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeSelection *sel;
    GtkTreeIter iter;
    GList *s;
    guint id;

    if (xcon) {
        if (!view)
            view = glade_xml_get_widget (glade_xml, "filter_treeview");

        if (!store)
            store = gtk_tree_view_get_model (GTK_TREE_VIEW (view));

        sel = gtk_tree_view_get_selection (GTK_TREE_VIEW (view));

        for (s = g_list_first (gtk_tree_selection_get_selected_rows (
                        sel, &store)); s; s = g_list_next (s)) {
            gtk_tree_model_get_iter (store, &iter, (GtkTreePath *) s->data);
            gtk_tree_model_get (store, &iter, COL_FILTER_ID, &id, -1);
            xmmsc_playlist_add_id (xcon, XMMS_ACTIVE_PLAYLIST, id);
        }

        g_list_free (s);
    }
}

void
on_filter_context_remove_menu_item_activate (GtkButton *button,
        gpointer user_data)
{
    static GtkWidget *entry = NULL;
    static GtkWidget *view = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeSelection *sel;
    GtkTreeIter iter;
    GList *s;
    guint id;

    if (xcon) {
        if (!view)
            view = glade_xml_get_widget (glade_xml, "filter_treeview");

        if (!store)
            store = gtk_tree_view_get_model (GTK_TREE_VIEW (view));

        sel = gtk_tree_view_get_selection (GTK_TREE_VIEW (view));

        for (s = g_list_last (gtk_tree_selection_get_selected_rows (
                        sel, &store)); s; s = g_list_previous (s)) {
            gtk_tree_model_get_iter (store, &iter, (GtkTreePath *) s->data);
            gtk_tree_model_get (store, &iter, COL_FILTER_ID, &id, -1);
            xmmsc_medialib_remove_entry (xcon, id);
        }

        g_list_free (s);

        /* reloading the collection
         * FIXME: do this with broadcasts when broadcast_medialib_entry_removed
         * (http://bugs.xmms2.xmms.se/view.php?id=1538) is solved */

        if (!entry)
            entry = glade_xml_get_widget (glade_xml, "filter_entry" );

        /* FIXME: Uh, the text there may have changed in the meanwhile... */
        on_filter_entry_activate (GTK_ENTRY (entry), NULL);
    }
}

void
on_filter_replace_menu_item_activate (GtkMenuItem *menuitem, gpointer userdata)
{
    on_playlist_clear_menu_item_activate (menuitem, userdata);
    on_filter_add_menu_item_activate (menuitem, userdata);
}

void on_filter_context_replace_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata)
{
    on_playlist_clear_menu_item_activate (menuitem, userdata);
    on_filter_context_add_menu_item_activate (menuitem, userdata);
}
