/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>
#include <string.h>

#include "abraca.h"
#include "collections.h"
#include "filter.h"
#include "misc.h"
#include "playlist.h"
#include "util.h"

static void on_collections_name_cell_renderer_edited (
        GtkCellRendererText *renderer, gchar *path, gchar *new_text,
        gpointer user_data);
static gchar *collections_model_get_name (GtkTreePath *path);
static gint collections_model_get_type (GtkTreePath *path);
static void collections_start_editing (void);
static void collections_delete (void);

void
collections_view_init (void)
{
    GtkWidget *collections;
    GtkCellRenderer *text_renderer;
    GtkCellRenderer *image_renderer;
    GtkTreeViewColumn *column;
    GtkTreeStore *store;
    GtkTreeIter iter;

    collections = glade_xml_get_widget (glade_xml, "collections_treeview");

    image_renderer = gtk_cell_renderer_pixbuf_new ();
    text_renderer = gtk_cell_renderer_text_new ();

    g_signal_connect (G_OBJECT (text_renderer), "edited",
            G_CALLBACK (on_collections_name_cell_renderer_edited), NULL);

    /* Icon */
    /* FIXME: pixbufs anyone? */
    column = gtk_tree_view_column_new_with_attributes (
            NULL, image_renderer, "stock-id", COL_COLLECTIONS_ICON, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (collections), column);

    /* Name */
    column = gtk_tree_view_column_new_with_attributes (
            NULL, text_renderer, "markup", COL_COLLECTIONS_NAME, NULL);
    gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_AUTOSIZE);
    gtk_tree_view_column_set_resizable (column, TRUE);
    gtk_tree_view_append_column (GTK_TREE_VIEW (collections), column);

    /* create a store with parents for playlists and collections */
    store = gtk_tree_store_new (NUM_COLLECTIONS_COLS,
            G_TYPE_INT, G_TYPE_STRING, G_TYPE_STRING);

    gtk_tree_store_append (store, &iter, NULL);
    gtk_tree_store_set (store, &iter,
            COL_COLLECTIONS_TYPE, COLT_PARENT,
            COL_COLLECTIONS_ICON, NULL,
            COL_COLLECTIONS_NAME, _ ("<b>Collections</b>"),
            -1);
    g_object_set_data (G_OBJECT (store), "collections_parent",
            (gpointer) gtk_tree_model_get_path (GTK_TREE_MODEL (store), &iter));

    gtk_tree_store_append (store, &iter, NULL);
    gtk_tree_store_set (store, &iter,
            COL_COLLECTIONS_TYPE, COLT_PARENT,
            COL_COLLECTIONS_ICON, NULL,
            COL_COLLECTIONS_NAME, _ ("<b>Playlists</b>"),
            -1);
    g_object_set_data (G_OBJECT (store), "playlists_parent",
            (gpointer) gtk_tree_model_get_path (GTK_TREE_MODEL (store), &iter));

    gtk_tree_view_set_model (GTK_TREE_VIEW (collections),
            GTK_TREE_MODEL (store));
}

void
collections_view_expand_all (void)
{
    static GtkWidget *collections = NULL;

    if (!collections)
        collections = glade_xml_get_widget (glade_xml, "collections_treeview");

    gtk_tree_view_expand_all (GTK_TREE_VIEW (collections));
}

void
collections_model_insert_collection (const gchar *name, gint pos)
{
    static GtkWidget *collections = NULL;
    static GtkTreeStore *store = NULL;
    static GtkTreePath *p = NULL;
    static GtkTreeIter iter;
    static GtkTreeIter parent;

    if (!collections)
        collections = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!store)
        store = GTK_TREE_STORE (
                gtk_tree_view_get_model (GTK_TREE_VIEW (collections)));
    if (!p) {
        p = (GtkTreePath *) g_object_get_data (G_OBJECT (store),
                "collections_parent");
        gtk_tree_model_get_iter (GTK_TREE_MODEL (store), &parent, p);
    }

    if (pos >= 0)
        gtk_tree_store_insert (store, &iter, &parent, pos);
    else
        gtk_tree_store_append (store, &iter, &parent);
    gtk_tree_store_set (store, &iter,
            COL_COLLECTIONS_TYPE, COLT_COLLECTION,
            COL_COLLECTIONS_ICON, NULL,
            COL_COLLECTIONS_NAME, name,
            -1);
}

void
collections_model_insert_playlist (const gchar *name, gint pos)
{
    static GtkWidget *collections = NULL;
    static GtkTreeStore *store = NULL;
    static GtkTreePath *p = NULL;
    static GtkTreeIter iter;
    static GtkTreeIter parent;

    if (!collections)
        collections = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!store)
        store = GTK_TREE_STORE (
                gtk_tree_view_get_model (GTK_TREE_VIEW (collections)));
    if (!p) {
        p = (GtkTreePath *) g_object_get_data (G_OBJECT (store),
                "playlists_parent");
        gtk_tree_model_get_iter (GTK_TREE_MODEL (store), &parent, p);
    }

    if (pos >= 0)
        gtk_tree_store_insert (store, &iter, &parent, pos);
    else
        gtk_tree_store_append (store, &iter, &parent);
    gtk_tree_store_set (store, &iter,
            COL_COLLECTIONS_TYPE, COLT_PLAYLIST,
            COL_COLLECTIONS_ICON, NULL,
            COL_COLLECTIONS_NAME, name,
            -1);
}

static void
collections_model_remove (const gchar *name, enum e_colt type)
{
    static GtkWidget *treeview = NULL;
    static GtkTreeStore *store = NULL;
    GtkTreePath *path;
    GtkTreeIter iter, p;
    gchar *n;
    gint t;

    if (!treeview)
        treeview = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!store)
        store = GTK_TREE_STORE (
                gtk_tree_view_get_model (GTK_TREE_VIEW (treeview)));

    if (store) {
        switch (type) {
            case COLT_COLLECTION:
                path = g_object_get_data (G_OBJECT (store),
                        "collections_parent");
                break;
            case COLT_PLAYLIST:
                path = g_object_get_data (G_OBJECT (store),
                        "playlists_parent");
                break;
            default:
                return;
                break;
        }
        gtk_tree_model_get_iter (GTK_TREE_MODEL (store), &p, path);

        if (gtk_tree_model_iter_children (GTK_TREE_MODEL (store), &iter, &p))
            do {
                gtk_tree_model_get (GTK_TREE_MODEL (store), &iter,
                        COL_COLLECTIONS_TYPE, &t,
                        COL_COLLECTIONS_NAME, &n,
                        -1);

                if ((t == type) && !strcmp (name, n))
                    gtk_tree_store_remove (store, &iter);

                g_free (n);
            } while (gtk_tree_model_iter_next (GTK_TREE_MODEL (store), &iter));
    }
}

void
collections_model_remove_collection (const gchar *name)
{
    collections_model_remove (name, COLT_COLLECTION);
}

void
collections_model_remove_playlist (const gchar *name)
{
    collections_model_remove (name, COLT_PLAYLIST);
}

void
collections_model_clear (void)
{
    static GtkWidget *treeview = NULL;
    static GtkTreeStore *store = NULL;
    GtkTreePath *ppath, *cpath;
    GtkTreeIter iter, p;

    if (!treeview)
        treeview = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!store)
        store = GTK_TREE_STORE (
                gtk_tree_view_get_model (GTK_TREE_VIEW (treeview)));

    cpath = g_object_get_data (G_OBJECT (store), "collections_parent");
    ppath = g_object_get_data (G_OBJECT (store), "playlists_parent");

    gtk_tree_model_get_iter (GTK_TREE_MODEL (store), &p, cpath);

    while (gtk_tree_model_iter_children (GTK_TREE_MODEL (store), &iter, &p))
        gtk_tree_store_remove (store, &iter);

    gtk_tree_model_get_iter (GTK_TREE_MODEL (store), &p, ppath);

    while (gtk_tree_model_iter_children (GTK_TREE_MODEL (store), &iter, &p))
        gtk_tree_store_remove (store, &iter);
}

/* FIXME: only make playlists and collections editable */
static void
collections_start_editing (void)
{
    static GtkWidget *view = NULL;
    static GtkTreeModel *store = NULL;
    GtkTreeSelection *sel;
    GtkTreeIter iter;
    GtkTreePath *path;
    GtkTreeViewColumn *col;
    GList *r;

    if (!view)
        view = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!store)
        store = gtk_tree_view_get_model (GTK_TREE_VIEW (view));

    sel = gtk_tree_view_get_selection (GTK_TREE_VIEW (view));
    if (gtk_tree_selection_get_selected (
                GTK_TREE_SELECTION (sel), NULL, &iter)) {

        path = gtk_tree_model_get_path (store, &iter);
        col = gtk_tree_view_get_column (GTK_TREE_VIEW (view), 1);
        r = gtk_tree_view_column_get_cell_renderers (col);

        g_object_set (G_OBJECT (r->data), "editable", TRUE, NULL);
        gtk_tree_view_set_cursor_on_cell (GTK_TREE_VIEW (view), path, col,
                GTK_CELL_RENDERER (r->data), TRUE);
        g_object_set (G_OBJECT (r->data), "editable", FALSE, NULL);

        gtk_tree_path_free (path);
        g_list_free (r);
    }
}

/* FIXME: Ewwww */
static void
collections_delete (void)
{
    static GtkWidget *view = NULL;
    static GtkTreeModel *store = NULL;
    static GtkWidget *parent = NULL;
    GtkWidget *dialog;
    GtkTreeSelection *sel;
    GtkTreePath *path;
    GtkTreeIter iter;
    gchar *tmp = NULL;
    gchar *name = NULL;
    gint type;

    if (!view)
        view = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!store)
        store = gtk_tree_view_get_model (GTK_TREE_VIEW (view));

    if (!parent)
        parent = glade_xml_get_widget (glade_xml, "main_window");

    sel = gtk_tree_view_get_selection (GTK_TREE_VIEW (view));
    if (gtk_tree_selection_get_selected (
                GTK_TREE_SELECTION (sel), NULL, &iter)) {
        path = gtk_tree_model_get_path (store, &iter);

        type = collections_model_get_type (path);
        name = collections_model_get_name (path);

        gtk_tree_path_free (path);

        switch (type) {
            case COLT_COLLECTION:
                tmp = g_strdup_printf (
                        _ ("Are you sure you want to delete the following "
                         "Collection:\n<b>%s</b>"), name);
                break;
            case COLT_PLAYLIST:
                tmp = g_strdup_printf (
                        _ ("Are you sure you want to delete the following "
                         "Playlist:\n<b>%s</b>"), name);
                break;
            default:
                return;
                break;
        }

        dialog = gtk_message_dialog_new_with_markup (GTK_WINDOW (parent),
                GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                GTK_MESSAGE_QUESTION,
                GTK_BUTTONS_YES_NO,
                tmp);

        gtk_dialog_set_default_response (GTK_DIALOG (dialog),
                GTK_RESPONSE_REJECT);

        if (xcon && (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_YES))
            switch (type) {
                case COLT_COLLECTION:
                    xmmsc_coll_remove (xcon, name,
                            XMMS_COLLECTION_NS_COLLECTIONS);
                    break;
                case COLT_PLAYLIST:
                    xmmsc_coll_remove (xcon, name,
                            XMMS_COLLECTION_NS_PLAYLISTS);
                    break;
                default:
                    break;
            }

        gtk_widget_destroy (dialog);

        if (tmp)
            g_free (tmp);

        if (name)
            g_free (name);
    }
}

static gchar *
collections_model_get_name (GtkTreePath *path)
{
    static GtkWidget *treeview = NULL;
    static GtkTreeModel *model = NULL;
    GtkTreeIter iter;
    gchar *name;

    if (!treeview)
        treeview = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!model)
        model = gtk_tree_view_get_model (GTK_TREE_VIEW (treeview));

    gtk_tree_model_get_iter (model, &iter, path);
    gtk_tree_model_get (model, &iter, COL_COLLECTIONS_NAME, &name, -1);

    return name;
}

static gint
collections_model_get_type (GtkTreePath *path)
{
    static GtkWidget *treeview = NULL;
    static GtkTreeModel *model = NULL;
    GtkTreeIter iter;
    gint type;

    if (!treeview)
        treeview = glade_xml_get_widget (glade_xml, "collections_treeview");

    if (!model)
        model = gtk_tree_view_get_model (GTK_TREE_VIEW (treeview));

    gtk_tree_model_get_iter (model, &iter, path);
    gtk_tree_model_get (model, &iter, COL_COLLECTIONS_TYPE, &type, -1);

    return type;
}


/* XMMS2 Callbacks */

void
bc_collection_changed (xmmsc_result_t *res, void *userdata)
{
    gint sig;
    gchar *name, *ns;


    if (xmmsc_result_get_dict_entry_int (res, "type", &sig) &&
            xmmsc_result_get_dict_entry_string (res, "name", &name) &&
            xmmsc_result_get_dict_entry_string (res, "namespace", &ns)) {

        abraca_debug ("bc_collection_changed:\n");
        abraca_debug ("\tsig: %d\n", sig);
        abraca_debug ("\tname: %s\n", name);
        abraca_debug ("\tnamespace: %s\n", ns);

        switch (sig) {
            case XMMS_COLLECTION_CHANGED_ADD:
                if (!strcasecmp (ns, XMMS_COLLECTION_NS_COLLECTIONS)) {
                    collections_model_insert_collection (name, 0);
                    playlist_collection_model_insert_collection (name, 0);
                }
                else
                    collections_model_insert_playlist (name, 0);
                break;
            case XMMS_COLLECTION_CHANGED_UPDATE:
                /* FIXME: what's this? */
                break;
            case XMMS_COLLECTION_CHANGED_RENAME:
                if (!strcasecmp (ns, XMMS_COLLECTION_NS_COLLECTIONS)) {
                    collections_model_remove_collection (name);
                    playlist_collection_model_remove_collection (name);
                    xmmsc_result_get_dict_entry_string (res, "newname", &name);
                    collections_model_insert_collection (name, 0);
                    playlist_collection_model_insert_collection (name, 0);
                }
                else {
                    collections_model_remove_playlist (name);
                    xmmsc_result_get_dict_entry_string (res, "newname", &name);
                    collections_model_insert_playlist (name, 0);
                }
                break;
            case XMMS_COLLECTION_CHANGED_REMOVE:
                if (!strcasecmp (ns, XMMS_COLLECTION_NS_COLLECTIONS)) {
                    collections_model_remove_collection (name);
                    playlist_collection_model_remove_collection (name);
                }
                else
                    collections_model_remove_playlist (name);
                break;
            default:
                break;
        }
    }
}

void
cb_coll_list (xmmsc_result_t *res, void *userdata)
{
    gchar *name;

    abraca_debug ("cb_coll_list:\n");
    while (xmmsc_result_list_valid (res)) {
        if (xmmsc_result_get_string (res, &name)) {
            abraca_debug ("\t%s\n", name);

            if (name[0] != '_') {
                if (!strcasecmp ((gchar *) userdata,
                            XMMS_COLLECTION_NS_COLLECTIONS)) {
                    collections_model_insert_collection (name, -1);
                    playlist_collection_model_insert_collection (name, -1);
                }
                else if (!strcasecmp ((gchar *) userdata,
                            XMMS_COLLECTION_NS_PLAYLISTS))
                    collections_model_insert_playlist (name, -1);
            }
        }

        xmmsc_result_list_next (res);
    }

    collections_view_expand_all ();
}

void
cb_coll_get (xmmsc_result_t *res, void *userdata)
{
    xmmsc_coll_t *coll;
    gchar *str = NULL;

    xmmsc_result_get_collection (res, &coll);
    str = coll_query_to_str (coll);
    if (str) {
        filter_entry_set_text (str);
        g_free (str);
    }
}


/* Gtk Callbacks */

void
on_collections_treeview_row_activated (GtkTreeView *treeview, GtkTreePath *path,
            GtkTreeViewColumn *col, gpointer userdata)
{
    xmmsc_result_t *r;
    gchar *name = NULL;
    gint type;

    if (xcon) {
        type = collections_model_get_type (path);
        name = collections_model_get_name (path);

        switch (type) {
            case COLT_COLLECTION:
                r = xmmsc_coll_get (xcon, name, XMMS_COLLECTION_NS_COLLECTIONS);
                xmmsc_result_notifier_set (r, cb_coll_get, xcon);
                xmmsc_result_unref (r);
                break;
            case COLT_PLAYLIST:
                xmmsc_playlist_load (xcon, name);
                break;
            default:
                break;
        }

        if (name)
            g_free (name);
    }
}

void
on_collection_new_dialog_cancel_button_clicked (
        GtkButton *button, gpointer user_data)
{
    static GtkWidget *dialog = NULL;
    static GtkWidget *entry = NULL;

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "collection_new_dialog");

    if (!entry)
        entry = glade_xml_get_widget (glade_xml,
                "collection_new_dialog_name_entry");

    gtk_widget_hide (dialog);
    gtk_widget_grab_focus (entry);
    gtk_entry_set_text (GTK_ENTRY (entry), "");
}

void
on_collection_new_dialog_new_button_clicked (
        GtkButton *button, gpointer user_data)
{
    static GtkWidget *dialog = NULL;
    static GtkWidget *entry = NULL;
    static GtkWidget *view = NULL;
    gchar *name;
    xmmsc_coll_t *query;

    if (xcon) {
        if (!dialog)
            dialog = glade_xml_get_widget (glade_xml, "collection_new_dialog");

        if (!entry)
            entry = glade_xml_get_widget (glade_xml,
                    "collection_new_dialog_name_entry");

        if (!view)
            view = glade_xml_get_widget (glade_xml, "filter_treeview");

        name = g_strdup (gtk_entry_get_text (GTK_ENTRY (entry)));
        g_strstrip (name);

        if (strlen (name)) {
            query = (xmmsc_coll_t *) g_object_get_data (G_OBJECT (view),
                    "query");
            xmmsc_coll_save (xcon, query, name, XMMS_COLLECTION_NS_COLLECTIONS);

            gtk_widget_hide (dialog);
            gtk_widget_grab_focus (entry);
            gtk_entry_set_text (GTK_ENTRY (entry), "");
        }

        g_free (name);
    }
}

void
on_collection_new_dialog_name_entry_activate (
        GtkEntry *entry, gpointer user_data)
{
    on_collection_new_dialog_new_button_clicked (NULL, NULL);
}

gboolean
on_collections_treeview_key_release_event (GtkWidget *widget,
        GdkEventKey *event, gpointer user_data)
{
    abraca_debug ("on_collections_treeview_key_release_event: %d\n",
            event->keyval);

    switch (event->keyval) {
        case GDK_F2:
            collections_start_editing ();
            break;
        case GDK_Delete:
            collections_delete ();
            break;
        default:
            break;
    }

    return FALSE;
}

static void
on_collections_name_cell_renderer_edited (
        GtkCellRendererText *renderer, gchar *path, gchar *new_text,
        gpointer user_data)
{
    GtkTreePath *p;
    gchar *name = NULL;
    gchar *tmp;
    gint type;

    if (xcon) {
        p = gtk_tree_path_new_from_string (path);
        name = collections_model_get_name (p);
        type = collections_model_get_type (p);
        gtk_tree_path_free (p);

        tmp = g_strdup (new_text);
        g_strstrip (tmp);

        if (strcmp (name, tmp))
            switch (type) {
                case COLT_COLLECTION:
                    xmmsc_coll_rename (xcon, name, tmp,
                            XMMS_COLLECTION_NS_COLLECTIONS);
                    break;
                case COLT_PLAYLIST:
                    xmmsc_coll_rename (xcon, name, tmp,
                            XMMS_COLLECTION_NS_PLAYLISTS);
                    break;
                default:
                    break;
            }

        g_free (tmp);

        if (name)
            g_free (name);
    }
}

gboolean
on_collections_treeview_button_press_event (
        GtkWidget *widget, GdkEventButton *event, gpointer user_data)
{
    static GtkTreeModel *model = NULL;

    if (!model)
        model = gtk_tree_view_get_model (GTK_TREE_VIEW (widget));

    if (model && (gtk_tree_model_iter_n_children (model, NULL) > 0) &&
            (event->button == 3)) {
        menu_popup ("collections_menu", event->button);

        return TRUE;
    }

    return FALSE;
}

void
on_collections_context_rename_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata)
{
    collections_start_editing ();
}

void
on_collections_context_delete_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata)
{
    collections_delete ();
}
