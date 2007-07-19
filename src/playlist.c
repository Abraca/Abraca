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
#include <stdlib.h>
#include <string.h>

#include "abraca.h"
#include "collections.h"
#include "filter.h"
#include "misc.h"
#include "playlist.h"
#include "util.h"

static gint playlist_collection_model_sort_func (GtkTreeModel *model,
        GtkTreeIter *a, GtkTreeIter *b, gpointer userdata);

void
playlist_view_init (void)
{
    GtkWidget *playlist;
    GtkCellRenderer *text_renderer;
    GtkCellRenderer *image_renderer;
    GtkTreeViewColumn *column;
    GtkTreeSelection *sel;

    playlist = glade_xml_get_widget (glade_xml, "playlist_treeview");

    image_renderer = gtk_cell_renderer_pixbuf_new ();
    text_renderer = gtk_cell_renderer_text_new ();

    /* Cover */
    column = gtk_tree_view_column_new_with_attributes (
            NULL, image_renderer, "stock-id", COL_PLAYLIST_COVER, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (playlist), column);

    /* Info */
    column = gtk_tree_view_column_new_with_attributes (
            NULL, text_renderer, "markup", COL_PLAYLIST_INFO, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (playlist), column);

    sel = gtk_tree_view_get_selection (GTK_TREE_VIEW (playlist));
    gtk_tree_selection_set_mode (sel, GTK_SELECTION_MULTIPLE);
}

void
playlist_model_set_status (guint pos, const gchar *id)
{
    static GtkWidget *playlist = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeIter iter;
    gchar *p;

    if (!playlist)
        playlist = glade_xml_get_widget (glade_xml, "playlist_treeview");

    if (!store)
        store = gtk_tree_view_get_model (GTK_TREE_VIEW (playlist));

    if (store) {
        p = g_strdup_printf ("%d", pos);

        if (gtk_tree_model_get_iter_from_string (store, &iter, p))
            gtk_list_store_set (GTK_LIST_STORE (store), &iter,
                    COL_PLAYLIST_COVER, id, -1);

        g_free (p);
    }
}

void
playlist_model_insert_track (track *t, gint pos)
{
    static GtkWidget *playlist = NULL;
    static GtkListStore *store = NULL;
    static GtkTreeIter iter;
    gchar *info;
    gchar *title, *artist, *album;

    if (!playlist)
        playlist = glade_xml_get_widget (glade_xml, "playlist_treeview");

    if (!store) {
        store = gtk_list_store_new (NUM_PLAYLIST_COLS,
                G_TYPE_STRING, G_TYPE_STRING);
        gtk_tree_view_set_model (GTK_TREE_VIEW (playlist),
                GTK_TREE_MODEL (store));
    }

    if (t->title)
        title = g_strdup (t->title);
    else
       title = g_strdup ("Unknown");

    if (t->artist)
        artist = g_strdup (t->artist);
    else
        artist = g_strdup ("Unknown");

    if (t->album)
        album = g_strdup (t->album);
    else
        album = g_strdup ("Unknown");

    info = g_markup_printf_escaped ("<b>%s</b> - <small>%d:%02d</small>\n"
            "<small>by</small> %s <small>from</small> %s",
            title, t->duration_min, t->duration_sec,
            artist, album);

    g_free (title);
    g_free (artist);
    g_free (album);

    if (pos >= 0)
        gtk_list_store_insert (store, &iter, pos);
    else
        gtk_list_store_append (store, &iter);

    gtk_list_store_set (store, &iter,
            COL_PLAYLIST_COVER, NULL,
            COL_PLAYLIST_INFO, info,
            -1);

    g_free (info);
}

void
playlist_model_remove_track (gint pos)
{
    static GtkWidget *playlist = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeIter iter;
    gchar *p;

    if (!playlist)
        playlist = glade_xml_get_widget (glade_xml, "playlist_treeview");

    if (!store)
        store = gtk_tree_view_get_model (GTK_TREE_VIEW (playlist));

    if (store) {
        p = g_strdup_printf ("%d", pos);

        if (gtk_tree_model_get_iter_from_string (store, &iter, p))
            gtk_list_store_remove (GTK_LIST_STORE (store), &iter);

        g_free (p);
    }
}

void
playlist_model_move_track (gint old, gint new)
{
    static GtkWidget *playlist = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeIter *iter_old, iter_new;
    gint i = 0, size;

    if (!playlist)
        playlist = glade_xml_get_widget (glade_xml, "playlist_treeview");

    if (!store)
        store = gtk_tree_view_get_model (GTK_TREE_VIEW (playlist));

    size = gtk_tree_model_iter_n_children (store, NULL);

    if (gtk_tree_model_get_iter_first (store, &iter_new)) {
        iter_old = gtk_tree_iter_copy (&iter_new);

        do {
            if (i < old)
                gtk_tree_model_iter_next (store, iter_old);
            if (i < new)
                gtk_tree_model_iter_next (store, &iter_new);

            if ((i >= old) && (i >= new))
                break;

            i++;
        } while (i < size);

        gtk_list_store_move_before (GTK_LIST_STORE (store),
                iter_old, &iter_new);

        gtk_tree_iter_free (iter_old);
    }
}

void
playlist_model_clear (void)
{
    static GtkWidget *playlist = NULL;
    static GtkTreeModel *store = NULL;

    if (!playlist)
        playlist = glade_xml_get_widget (glade_xml, "playlist_treeview");

    if (!store)
        store = gtk_tree_view_get_model (GTK_TREE_VIEW (playlist));

    if (store)
        gtk_list_store_clear (GTK_LIST_STORE (store));
}

static gint
playlist_collection_model_sort_func (GtkTreeModel *model, GtkTreeIter *a,
        GtkTreeIter *b, gpointer userdata)
{
    gchar *name1 = NULL;
    gchar *name2 = NULL;
    gint ret = 0;

    gtk_tree_model_get (model, a, COL_PLAYLIST_COLLECTION_NAME, &name1, -1);
    gtk_tree_model_get (model, b, COL_PLAYLIST_COLLECTION_NAME, &name2, -1);

    if (!name1 || !name2) {
        if (!name1 && !name2)
            ret = 0;

        ret = !name1 ? -1 : 1;
    }
    else
        ret = g_utf8_collate (name1, name2);

    g_free (name1);
    g_free (name2);

    return ret;
}

void
playlist_collection_model_insert_collection (const gchar *name, gint pos)
{
    static GtkWidget *combobox = NULL;
    static GtkListStore *store = NULL;
    static GtkTreeSortable *sortable;
    static GtkTreeIter iter;

    if (!combobox)
        combobox = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_source_combobox");

    if (!store) {
        store = gtk_list_store_new (NUM_PLAYLIST_COLLECTION_COLS,
                G_TYPE_STRING);
        gtk_combo_box_set_model (GTK_COMBO_BOX (combobox),
                GTK_TREE_MODEL (store));

        sortable = GTK_TREE_SORTABLE (store);
        gtk_tree_sortable_set_sort_func (sortable, COL_PLAYLIST_COLLECTION_NAME,
                playlist_collection_model_sort_func, NULL, NULL);
    }

    if (pos >= 0)
        gtk_list_store_insert (store, &iter, pos);
    else
        gtk_list_store_append (store, &iter);

    gtk_list_store_set (store, &iter,
            COL_PLAYLIST_COLLECTION_NAME, name,
            -1);

    gtk_tree_sortable_set_sort_column_id (sortable,
            COL_PLAYLIST_COLLECTION_NAME, GTK_SORT_ASCENDING);
}

void
playlist_collection_model_remove_collection (const gchar *name)
{
    static GtkWidget *combobox = NULL;
    static GtkTreeStore *store = NULL;
    GtkTreeIter iter;
    gchar *n;

    if (!combobox)
        combobox = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_source_combobox");

    if (!store)
        store = GTK_TREE_STORE (
                gtk_combo_box_get_model (GTK_COMBO_BOX (combobox)));

    if (store) {
        if (gtk_tree_model_get_iter_first (GTK_TREE_MODEL (store), &iter))
            do {
                gtk_tree_model_get (GTK_TREE_MODEL (store), &iter,
                        COL_PLAYLIST_COLLECTION_NAME, &n,
                        -1);

                if (!strcmp (name, n))
                    gtk_tree_store_remove (store, &iter);

                g_free (n);
            } while (gtk_tree_model_iter_next (GTK_TREE_MODEL (store), &iter));
    }
}

void
playlist_remove_selected_rows (void)
{
    static GtkWidget *playlist = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeSelection *sel;
    gchar *p;
    GList *s;
    gint index = 0;

    if (xcon) {
        if (!playlist)
            playlist = glade_xml_get_widget (glade_xml, "playlist_treeview");

        if (!store)
            store = gtk_tree_view_get_model (GTK_TREE_VIEW (playlist));

        sel = gtk_tree_view_get_selection (GTK_TREE_VIEW (playlist));

        for (s = g_list_last (gtk_tree_selection_get_selected_rows (
                        sel, &store)); s; s = g_list_previous (s)) {
            p = gtk_tree_path_to_string ((GtkTreePath *) s->data);
            index = atoi (p);

            xmmsc_playlist_remove_entry (xcon, XMMS_ACTIVE_PLAYLIST, index);

            g_free (p);
        }

        g_list_free (s);
    }
}

void
playlist_label_set (const gchar *name)
{
    static GtkWidget *label = NULL;
    gchar *tmp;

    if (!label)
        label = glade_xml_get_widget (glade_xml, "playlist_label");

    tmp = g_markup_printf_escaped (_ ("Playlist: <b>%s</b>"), name);

    gtk_label_set_markup (GTK_LABEL (label), tmp);

    g_free (tmp);
}


/* XMMS2 Callbacks */

void
bc_playlist_current_pos (xmmsc_result_t *res, void *userdata)
{
    guint pos;

    if (xmmsc_result_get_uint (res, &pos)) {
        abraca_debug ("bc_playlist_current_pos: %d\n", pos);

        playlist_model_set_status (playlist_position, NULL);
        playlist_model_set_status (pos, "gtk-media-play");
        playlist_position = pos;
    }
}

/* FIXME: sooo much indendation */
void
bc_playlist_changed (xmmsc_result_t *res, void *userdata)
{
    xmmsc_result_t *r;
    gint sig, pos, newpos;
    guint id;
    gchar *pl;

    if (xmmsc_result_get_dict_entry_int (res, "type", &sig) &&
            xmmsc_result_get_dict_entry_string (res, "name", &pl) &&
            !strcmp (active_playlist, pl)) {
        abraca_debug ("bc_playlist_changed: %d\n", sig);

        switch (sig) {
            case XMMS_PLAYLIST_CHANGED_ADD:
                if (xmmsc_result_get_dict_entry_uint (res, "id", &id)) {
                    r = xmmsc_medialib_get_info (xcon, id);
                    xmmsc_result_notifier_set (
                            r, sg_medialib_get_info_playlist_insert,
                            (gpointer) -1);
                    xmmsc_result_unref (r);
                }
                break;
            case XMMS_PLAYLIST_CHANGED_INSERT:
                if (xmmsc_result_get_dict_entry_uint (res, "id", &id) &&
                        xmmsc_result_get_dict_entry_int (
                            res, "position", &pos)) {
                    r = xmmsc_medialib_get_info (xcon, id);
                    xmmsc_result_notifier_set (
                            r, sg_medialib_get_info_playlist_insert,
                            (gpointer) pos);
                    xmmsc_result_unref (r);
                }
                break;
            case XMMS_PLAYLIST_CHANGED_SHUFFLE:
                playlist_model_clear ();
                r = xmmsc_playlist_list_entries (xcon, XMMS_ACTIVE_PLAYLIST);
                xmmsc_result_notifier_set (r, cb_playlist_list_entries, NULL);
                xmmsc_result_unref (r);
                break;
            case XMMS_PLAYLIST_CHANGED_REMOVE:
                if (xmmsc_result_get_dict_entry_int (res, "position", &pos))
                    playlist_model_remove_track (pos);
                break;
            case XMMS_PLAYLIST_CHANGED_CLEAR:
                playlist_model_clear ();
                break;
            case XMMS_PLAYLIST_CHANGED_MOVE:
                if (xmmsc_result_get_dict_entry_int (res, "position", &pos) &&
                        xmmsc_result_get_dict_entry_int (
                            res, "newposition", &newpos))
                    playlist_model_move_track (pos, newpos);
                break;
            case XMMS_PLAYLIST_CHANGED_SORT:
                playlist_model_clear ();
                r = xmmsc_playlist_list_entries (xcon, XMMS_ACTIVE_PLAYLIST);
                xmmsc_result_notifier_set (r, cb_playlist_list_entries, NULL);
                xmmsc_result_unref (r);
                break;
            case XMMS_PLAYLIST_CHANGED_UPDATE:
                /* FIXME: What is this signal good for? */
                break;
            default:
                break;
        }
    }
}

void
bc_playlist_loaded (xmmsc_result_t *res, void *userdata)
{
    xmmsc_result_t *r;
    gchar *pl;

    if (xmmsc_result_get_string (res, &pl)) {
        abraca_debug ("bc_playlist_loaded: %s\n", pl);

        if (active_playlist)
            g_free (active_playlist);

        active_playlist = g_strdup (pl);

        playlist_label_set (pl);
        playlist_model_clear ();
        r = xmmsc_playlist_list_entries (xcon, XMMS_ACTIVE_PLAYLIST);
        xmmsc_result_notifier_set (r, cb_playlist_list_entries, NULL);
        xmmsc_result_unref (r);
    }
}

void
cb_playlist_list_entries (xmmsc_result_t *res, void *userdata)
{
    guint id;
    xmmsc_result_t *r;

    abraca_debug ("cb_playlist_list_entries:\n");
    while (xmmsc_result_list_valid (res)) {
        if (xmmsc_result_get_uint (res, &id)) {
            abraca_debug ("\t%d\n", id);

            r = xmmsc_medialib_get_info (xcon, id);
            xmmsc_result_notifier_set (
                    r, sg_medialib_get_info_playlist_insert, (gpointer) -1);
            xmmsc_result_unref (r);
        }

        xmmsc_result_list_next (res);
    }

    r = xmmsc_playlist_current_pos (xcon, XMMS_ACTIVE_PLAYLIST);
    xmmsc_result_notifier_set (r, bc_playlist_current_pos, NULL);
    xmmsc_result_unref (r);

    XMMS_CALLBACK_SET (xcon, xmmsc_playback_status,
            bc_playback_status, NULL);
}

void
cb_playlist_current_active (xmmsc_result_t *res, void *userdata)
{
    gchar *pl;

    if (xmmsc_result_get_string (res, &pl)) {
        abraca_debug ("cb_playlist_current_active: %s\n", pl);

        xmmsc_playlist_load (xcon, pl);
    }
}

void
sg_medialib_get_info_playlist_insert (xmmsc_result_t *res, void *userdata)
{
    track t;

    t = track_set_info (res);

    abraca_debug ("sg_medialib_get_info_playlist_insert:\n");
    abraca_debug ("\tArtist: %s\n", t.artist);
    abraca_debug ("\tAlbum: %s\n", t.album);
    abraca_debug ("\tTitle: %s\n", t.title);
    abraca_debug ("\tComment: %s\n", t.comment);
    abraca_debug ("\tGenre: %s\n", t.genre);
    abraca_debug ("\tUrl: %s\n", t.url);
    abraca_debug ("\tPicture Front: %s\n", t.picture_front);
    abraca_debug ("\tID: %d\n", t.id);
    abraca_debug ("\tDuration: %d\n", t.duration);

    playlist_model_insert_track (&t, (gint) userdata);
    track_free (&t);
}


/* Gtk Callbacks */

/* FIXME: do more shortcuts? Configurability!? */
gboolean
on_playlist_treeview_key_release_event (GtkWidget *widget,
        GdkEventKey *event, gpointer user_data)
{
    abraca_debug ("on_playlist_treeview_key_release_event: %d\n",
            event->keyval);

    switch (event->keyval) {
        case GDK_j:
            filter_entry_focus ();
            break;
        case GDK_Delete:
            playlist_remove_selected_rows ();
            break;
        default:
            break;
    }

    return FALSE;
}

void
on_playlist_treeview_row_activated (GtkTreeView *treeview, GtkTreePath *path,
            GtkTreeViewColumn *col, gpointer userdata)
{
    gchar *p;
    gint index = 0;

    if (xcon) {
        p = gtk_tree_path_to_string (path);
        index = atoi (p);
        g_free (p);

        /* FIXME: Tricks */
        switch (current_track.status) {
            case XMMS_PLAYBACK_STATUS_STOP:
                xmmsc_playlist_set_next (xcon, index);
                xmmsc_playback_start (xcon);
                break;
            case XMMS_PLAYBACK_STATUS_PAUSE:
                xmmsc_playlist_set_next (xcon, index);
                xmmsc_playback_start (xcon);
                xmmsc_playback_tickle (xcon);
                break;
            case XMMS_PLAYBACK_STATUS_PLAY:
                xmmsc_playlist_set_next (xcon, index);
                xmmsc_playback_tickle (xcon);
                break;
        }
    }
}

gboolean
on_playlist_treeview_button_press_event (
        GtkWidget *widget, GdkEventButton *event, gpointer user_data)
{
    static GtkTreeModel *model = NULL;

    if (!model)
        model = gtk_tree_view_get_model (GTK_TREE_VIEW (widget));

    if (model && (gtk_tree_model_iter_n_children (model, NULL) > 0) &&
            (event->button == 3)) {
        menu_popup ("playlist_menu", event->button);

        return TRUE;
    }

    return FALSE;
}

void
on_playlist_shuffle_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata)
{
    if (xcon)
        xmmsc_playlist_shuffle (xcon, XMMS_ACTIVE_PLAYLIST);
}

void
on_playlist_clear_menu_item_activate (GtkMenuItem *menuitem, gpointer userdata)
{
    if (xcon)
        xmmsc_playlist_clear (xcon, XMMS_ACTIVE_PLAYLIST);
}

void
on_playlist_new_menu_item_activate (GtkMenuItem *menuitem, gpointer userdata)
{
    static GtkWidget *dialog = NULL;
    static GtkWidget *type_combobox = NULL;
    static GtkWidget *source_combobox = NULL;
    static GtkWidget *collections_treeview = NULL;

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "playlist_new_dialog");

    if (!type_combobox)
        type_combobox = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_type_combobox");
    gtk_combo_box_set_active (GTK_COMBO_BOX (type_combobox), 0);
 
    if (!source_combobox)
	source_combobox = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_source_combobox");

    if (!collections_treeview)
        collections_treeview = glade_xml_get_widget (glade_xml,
                "collections_treeview");

    gtk_combo_box_set_active (GTK_COMBO_BOX (source_combobox), 0);

    gtk_widget_show (dialog);
}

void
on_playlist_context_remove_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata)
{
    playlist_remove_selected_rows ();
}

void
on_playlist_new_dialog_cancel_button_clicked (
        GtkButton *button, gpointer user_data)
{
    static GtkWidget *dialog = NULL;
    static GtkWidget *entry = NULL;

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "playlist_new_dialog");

    if (!entry)
        entry = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_name_entry");

    gtk_widget_hide (dialog);
    gtk_widget_grab_focus (entry);
    gtk_entry_set_text (GTK_ENTRY (entry), "");
}

/* FIXME: better use a GtkListStore for the type combobox? */
void
on_playlist_new_dialog_new_button_clicked (
        GtkButton *button, gpointer user_data)
{
    static GtkWidget *dialog = NULL;
    static GtkWidget *entry = NULL;
    static GtkWidget *type_combobox = NULL;
    static GtkWidget *source_combobox = NULL;
    gchar *name, *source;
    gint type;
    xmmsc_coll_t *refcoll, *newcoll;

    /* Heh, advanced max-indendation-avoidance tricks */
    if (!xcon)
        return;

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "playlist_new_dialog");

    if (!entry)
        entry = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_name_entry");

    if (!source_combobox)
        source_combobox = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_source_combobox");

    if (!type_combobox)
        type_combobox = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_type_combobox");

    name = g_strdup (gtk_entry_get_text (GTK_ENTRY (entry)));
    g_strstrip (name);

    if (strlen (name)) {
        type = gtk_combo_box_get_active (GTK_COMBO_BOX (type_combobox));

        source = g_strdup (gtk_combo_box_get_active_text (
                    GTK_COMBO_BOX (source_combobox)));
        g_strstrip (source);

        switch (type) {
            case 0: /* Normal */
                newcoll = xmmsc_coll_new (XMMS_COLLECTION_TYPE_IDLIST);
                break;

            case 1: /* Queue */
                /* FIXME: having queue working with a reference-collection,
                 * too */
                newcoll = xmmsc_coll_new (XMMS_COLLECTION_TYPE_QUEUE);
                break;

            case 2: /* PartyShuffle */
                newcoll = xmmsc_coll_new (XMMS_COLLECTION_TYPE_PARTYSHUFFLE);
                refcoll = xmmsc_coll_new (XMMS_COLLECTION_TYPE_REFERENCE);
                xmmsc_coll_attribute_set (refcoll, "reference", source);
                xmmsc_coll_attribute_set (refcoll, "namespace",
                        XMMS_COLLECTION_NS_COLLECTIONS);
                xmmsc_coll_add_operand (newcoll, refcoll);
                xmmsc_coll_unref (refcoll);
                break;

            default:
                newcoll = xmmsc_coll_new (XMMS_COLLECTION_TYPE_IDLIST);
        }
        xmmsc_coll_save (xcon, newcoll, name, XMMS_COLLECTION_NS_PLAYLISTS);

        gtk_widget_hide (dialog);
        gtk_widget_grab_focus (entry);
        gtk_entry_set_text (GTK_ENTRY (entry), "");

        g_free (source);
    }

    g_free (name);
}

void
on_playlist_new_dialog_name_entry_activate (GtkEntry *entry, gpointer user_data)
{
    on_playlist_new_dialog_new_button_clicked (NULL, NULL);
}

void
on_playlist_new_dialog_type_combobox_changed (GtkComboBox *combobox,
        gpointer userdata)
{
    static GtkWidget *source_combobox = NULL;
    static GtkWidget *label = NULL;
    static GtkWidget *dialog = NULL;

    if (!source_combobox)
        source_combobox = glade_xml_get_widget (glade_xml,
                "playlist_new_dialog_source_combobox");

    if (!label)
        label = glade_xml_get_widget (glade_xml, "source_label");

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "playlist_new_dialog");

    if (gtk_combo_box_get_active (combobox) == 2) {
        gtk_widget_show (source_combobox);
        gtk_widget_show (label);
    }
    else {
        gtk_widget_hide (source_combobox);
        gtk_widget_hide (label);
    }

    gtk_window_resize (GTK_WINDOW (dialog), 1, 1);
}
