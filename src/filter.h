/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef FILTER_H
#define FILTER_H

enum {
    COL_FILTER_ID = 0,
    COL_FILTER_ARTIST,
    COL_FILTER_TITLE,
    COL_FILTER_ALBUM,
    COL_FILTER_DURATION,
    COL_FILTER_URL,
    COL_FILTER_GENRE,
    COL_FILTER_COMMENT,
    NUM_FILTER_COLS
};

void filter_view_init (void);
void filter_model_insert_track (track *t, GdkPixbuf *p, gint pos);
void filter_model_clear (void);
void filter_entry_set_text (const gchar *str);
void filter_entry_focus (void);
/*
gchar *filter_entry_get_text (void);
*/

/* XMMS2 Callbacks */
void cb_coll_query_ids (xmmsc_result_t *res, void *userdata);
void sg_medialib_get_info_filter_insert (xmmsc_result_t *res, void *userdata);

/* Gtk Callbacks */
void on_filter_entry_activate (GtkEntry *entry, gpointer userdata);
gboolean on_filter_treeview_key_release_event (GtkWidget *widget,
        GdkEventKey *event, gpointer user_data);
gboolean on_filter_treeview_button_press_event (
        GtkWidget *widget, GdkEventButton *event, gpointer user_data);
void on_filter_treeview_row_activated (GtkTreeView *view, GtkTreePath *path,
        GtkTreeViewColumn *col, gpointer user_data);
void on_filter_save_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_filter_add_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_filter_context_add_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_filter_context_remove_menu_item_activate (GtkButton *button,
        gpointer user_data);
void on_filter_replace_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
void on_filter_context_replace_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);

#endif /* #ifndef FILTER_H */
