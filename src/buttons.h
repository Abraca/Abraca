/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef BUTTONS_H
#define BUTTONS_H

void pp_button_set_image (const gchar *stock_image);

/* XMMS2 Callbacks */

/* Gtk+ Callbacks */
void on_ppbutton_clicked (GtkButton *button, gpointer user_data);
void on_stopbutton_clicked (GtkButton *button, gpointer user_data);
void on_backbutton_clicked (GtkButton *button, gpointer user_data);
void on_fwdbutton_clicked (GtkButton *button, gpointer user_data);

#endif /* #ifndef BUTTONS_H */
