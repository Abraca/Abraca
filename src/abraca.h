/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef ABRACA_H
#define ABRACA_H

#include <glade/glade.h>
#include <libintl.h>
#include <locale.h>

#include "trackinfo.h"

#ifdef ENABLE_NLS
#  define _(string) gettext (string)
#else
#  define _(string) string
#endif

extern GladeXML *glade_xml;
extern xmmsc_connection_t *xcon;
extern track current_track;
extern gchar *active_playlist;
guint playlist_position;

#endif /* #ifndef ABRACA_H */
