/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef PLAYLIST_H
#define PLAYLIST_H

#include <gtk/gtk.h>

enum e_playlist_column {
    COL_PLAYLIST_COVER = 0,
    COL_PLAYLIST_INFO,
    NUM_PLAYLIST_COLS
};

enum {
    COL_PLAYLIST_COLLECTION_NAME = 0,
    NUM_PLAYLIST_COLLECTION_COLS
};

typedef enum e_playlist_column playlist_column;

void playlist_view_init (void);
void playlist_model_set_status (guint pos, const gchar *id);
void playlist_model_insert_track (track *t, gint pos);
void playlist_model_remove_track (gint pos);
void playlist_model_move_track (gint old, gint new);
void playlist_model_clear (void);
void playlist_collection_model_insert_collection (const gchar *name, gint pos);
void playlist_collection_model_remove_collection (const gchar *name);
void playlist_remove_selected_rows (void);
void playlist_label_set (const gchar *name);

/* XMMS2 Callbacks */
void bc_playlist_current_pos (xmmsc_result_t *res, void *userdata);
void bc_playlist_changed (xmmsc_result_t *res, void *userdata);
void bc_playlist_loaded (xmmsc_result_t *res, void *userdata);
void cb_playlist_list_entries (xmmsc_result_t *res, void *userdata);
void cb_playlist_current_active (xmmsc_result_t *res, void *userdata);
void sg_medialib_get_info_playlist_insert (xmmsc_result_t *res, void *userdata);

/* Gtk Callbacks */
gboolean on_playlist_treeview_key_release_event (GtkWidget *widget,
        GdkEventKey *event, gpointer user_data);
void on_playlist_treeview_row_activated (
        GtkTreeView *treeview, GtkTreePath *path,
            GtkTreeViewColumn *col, gpointer userdata);
gboolean on_playlist_treeview_button_press_event (
        GtkWidget *widget, GdkEventButton *event, gpointer user_data);
void on_playlist_shuffle_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_playlist_clear_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_playlist_new_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_playlist_context_remove_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_playlist_new_dialog_cancel_button_clicked (
        GtkButton *button, gpointer user_data);
void on_playlist_new_dialog_new_button_clicked (
        GtkButton *button, gpointer user_data);
void on_playlist_new_dialog_name_entry_activate (
        GtkEntry *entry, gpointer user_data);
void on_playlist_new_dialog_type_combobox_changed (GtkComboBox *combobox,
        gpointer userdata);

#endif /* #ifndef PLAYLIST_H */
