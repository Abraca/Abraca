/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 *                    Martin Salzer <stoky at gmx dot net>
 * See COPYING file for details.
 */

#include <sys/stat.h>    /* LINUX/UNIX */
#include <sys/types.h>   /* LINUX/UNIX */

#include <gtk/gtk.h>
#include <string.h>

#include "abraca.h"
#include "medialib.h"
#include "filter.h"

void
on_add_menu_item_activate (GtkMenuItem *menuitem, gpointer userdata)
{
    static GtkWidget *dialog = NULL;

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "add_dialog");

    gtk_widget_show (dialog);
}

void
on_add_dialog_cancel_button_clicked (GtkButton *button, gpointer user_data)
{
    static GtkWidget *dialog = NULL;

    if (!dialog)
        dialog = glade_xml_get_widget (glade_xml, "add_dialog");

    gtk_widget_hide (dialog);
}

void
on_add_dialog_add_button_clicked (GtkButton *button, gpointer user_data)
{
    static GtkWidget *dialog = NULL;
    struct stat attribute;
    GSList *filenames, *current;
    gchar *filename, *url;

    if (xcon) {
        if (!dialog)
            dialog = glade_xml_get_widget (glade_xml, "add_dialog");

        filenames = gtk_file_chooser_get_filenames  (GTK_FILE_CHOOSER (dialog));

        current = filenames;
        for (current = filenames; current; current = current->next) {
            filename = (gchar *) current->data;
            stat (filename, &attribute);

            /* FIXME: do we need to url encode the filename first? */
            url = g_strdup_printf ("file://%s", filename);
            if (attribute.st_mode & S_IFDIR) {
                xmmsc_medialib_path_import (xcon, url );
            }
            else {
                xmmsc_medialib_add_entry (xcon, url);
            }

            g_free (url);
        }

        g_slist_free (filenames);
        gtk_widget_hide (dialog);
        /* FIXME: reload filter on broadcast_medialib_entry_added
         * (not yet done because on big changes this will suck
         *  and because the mlib-bc are 'inconsistent'
         *  (broadcast_medialib_entry_removed is missing)) */
    }
}
