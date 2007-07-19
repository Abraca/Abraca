/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef MISC_H
#define MISC_H

void widget_set_sensitive_by_name (const gchar *name, gboolean sensitive);
void position_scale_update (guint time);
void time_label_update (guint time);
void track_label_update (void);
void window_title_update (void);
void create_playlist_model (void);
void playlist_treeview_focus (void);
GdkPixbuf *pixbuf_from_string (const guchar *data, gint len);
void cover_image_set_pixbuf (GdkPixbuf *p);
void cover_image_set_from_icon_name (const gchar *name);
void menu_popup (const gchar *name, guint button);
void notify_current_song (const gchar *title);

/* XMMS2 Callbacks */
void bc_playback_current_id (xmmsc_result_t *res, void *userdata);
void bc_playback_status (xmmsc_result_t *res, void *userdata);
void cb_playback_playtime (xmmsc_result_t *res, void *userdata);
void cb_bindata_retrieve (xmmsc_result_t *res, void *userdata);
void sg_medialib_get_info (xmmsc_result_t *res, void *userdata);

/* Gtk Callbacks */
void on_mainwindow_destroy (GtkObject *object, gpointer user_data);
gboolean on_position_change_value (GtkRange *range, GtkScrollType scroll,
        gdouble value, gpointer user_data);
void on_help_about_menu_item_activate (
        GtkMenuItem *menuitem, gpointer userdata);
gboolean on_dialog_delete_event (GtkWidget *widget, GdkEvent *event,
        gpointer user_data);

#endif /* #ifndef MISC_H */
