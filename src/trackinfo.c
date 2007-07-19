/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#include "trackinfo.h"

void
track_nullify (track *t)
{
    t->artist = NULL;
    t->album = NULL;
    t->title = NULL;
    t->comment = NULL;
    t->genre = NULL;
    t->url = NULL;
    t->picture_front = NULL;
    t->cover = NULL;
    t->id = 0;
    t->duration = 0;
    t->duration_min = 0;
    t->duration_sec = 0;
}

void
track_free (track *t)
{
    if (t->artist)
        g_free (t->artist);
    if (t->album)
        g_free (t->album);
    if (t->title)
        g_free (t->title);
    if (t->comment)
        g_free (t->comment);
    if (t->genre)
        g_free (t->genre);
    if (t->url)
        g_free (t->url);
    if (t->picture_front)
        g_free (t->picture_front);
    if (t->cover)
        g_object_unref (t->cover);

    track_nullify (t);
}

track
track_set_info (xmmsc_result_t *res)
{
    gchar *artist, *album, *title;
    gchar *comment, *genre, *url;
    gchar *pf;
    gint id;
    gint duration;
    track t;

    track_nullify (&t);

    if (xmmsc_result_get_dict_entry_string (res, "artist", &artist))
        t.artist = g_strdup (artist);

    if (xmmsc_result_get_dict_entry_string (res, "album", &album))
        t.album = g_strdup (album);

    if (xmmsc_result_get_dict_entry_string (res, "title", &title))
        t.title = g_strdup (title);

    if (xmmsc_result_get_dict_entry_string (res, "comment", &comment))
        t.comment = g_strdup (comment);

    if (xmmsc_result_get_dict_entry_string (res, "genre", &genre))
        t.genre = g_strdup (genre);

    if (xmmsc_result_get_dict_entry_string (res, "url", &url))
        t.url = g_strdup (url);

    if (xmmsc_result_get_dict_entry_string (res, "picture_front", &pf))
        t.picture_front = g_strdup (pf);

    if (xmmsc_result_get_dict_entry_int (res, "id", &id))
        t.id = id;

    if (xmmsc_result_get_dict_entry_int (res, "duration", &duration)) {
        t.duration = duration;
        t.duration_min = duration / 60000;
        t.duration_sec = duration / 1000 - t.duration_min * 60;
    }

    return t;
}
