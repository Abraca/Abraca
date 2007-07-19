/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef COLLECTIONS_H
#define COLLECTIONS_H

enum {
    COL_COLLECTIONS_TYPE = 0,
    COL_COLLECTIONS_ICON,
    COL_COLLECTIONS_NAME,
    NUM_COLLECTIONS_COLS
};

enum e_colt {
    COLT_PARENT = 0,
    COLT_COLLECTION,
    COLT_PLAYLIST
};

void collections_view_init (void);
void collections_view_expand_all (void);
void collections_model_insert_collection (const gchar *name, gint pos);
void collections_model_insert_playlist (const gchar *name, gint pos);
void collections_model_remove_collection (const gchar *name);
void collections_model_remove_playlist (const gchar *name);
void collections_model_clear (void);

/* XMMS2 Callbacks */
void bc_collection_changed (xmmsc_result_t *res, void *userdata);
void cb_coll_list (xmmsc_result_t *res, void *userdata);
void cb_coll_get (xmmsc_result_t *res, void *userdata);

/* Gtk Callbacks */
void on_collections_treeview_row_activated (
        GtkTreeView *treeview, GtkTreePath *path,
            GtkTreeViewColumn *col, gpointer userdata);
void on_collection_new_dialog_cancel_button_clicked (
        GtkButton *button, gpointer user_data);
void on_collection_new_dialog_new_button_clicked (
        GtkButton *button, gpointer user_data);
void on_collection_new_dialog_name_entry_activate (
        GtkEntry *entry, gpointer user_data);
gboolean on_collections_treeview_key_release_event (GtkWidget *widget,
        GdkEventKey *event, gpointer user_data);
gboolean on_collections_treeview_button_press_event (
        GtkWidget *widget, GdkEventButton *event, gpointer user_data);
void on_collections_context_rename_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_collections_context_delete_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);

#endif /* #ifndef COLLECTIONS_H */
