/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifndef UTIL_H
#define UTIL_H

void abraca_debug (const gchar *format, ...);
gchar *str_escape (gchar *str);
void str_human_wildcards (gchar *str);
gchar *coll_query_to_str (xmmsc_coll_t *coll);
xmmsc_coll_t *str_to_coll_query (const gchar *str);

#endif /* #ifndef UTIL_H */
