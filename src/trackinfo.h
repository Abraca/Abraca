/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef TRACKINFO_H
#define TRACKINFO_H

#include <xmmsclient/xmmsclient.h>
#include <glib.h>
#include <gdk/gdk.h>

struct st_track {
    gchar *artist;
    gchar *album;
    gchar *title;
    gchar *comment;
    gchar *genre;
    gchar *url;
    gchar *picture_front;
    GdkPixbuf *cover;
    gint id;
    gint duration;
    gint duration_min;
    gint duration_sec;
    xmms_playback_status_t status;
};

typedef struct st_track track;

void track_nullify (track *t);
void track_free (track *t);
track track_set_info (xmmsc_result_t *res);

#endif /* #ifndef TRACKINFO_H */
