/*
 * Copyright (c) 2007 Sebastian Sareyko <smoon at nooms dot de>
 * See COPYING file for details.
 */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <xmmsclient/xmmsclient.h>
#include <glib/gprintf.h>
#include <glib.h>
#include <string.h>
#include <strings.h>

#include "util.h"

void
abraca_debug (const gchar *format, ...)
{
#ifdef DEBUG
    va_list args;

    va_start (args, format);
    g_vprintf (format, args);
    va_end (args);
#endif /* DEBUG */
}

/* FIXME: What else needs to be escaped? */
gchar *
str_escape (gchar *str)
{
    gchar *tmp;
    gint i, j = 0;

    for (i = 0; str[i] != '\0'; i++) {
        if (index (" \\\"'()", str[i]))
            j++;
        j++;
    }

    tmp = g_malloc (sizeof (gchar) * ++j);

    j = 0;
    for (i = 0; str[i] != '\0'; i++) {
        if (index (" \\\"'()", str[i])) {
            /* FIXME: wtf is wrong with this? Would be nicer than an additional
             *        loop for counting...
            tmp = g_realloc (tmp, sizeof (gchar) * (strlen (tmp) + 1));
            */
            tmp[j] = '\\';
            j++;
        }

        tmp[j] = str[i];
        j++;
    }
    tmp[j] = '\0';

    return tmp;
}

/* "Yay!" for creative function names */
void
str_human_wildcards (gchar *str)
{
    gint i;

    for (i = 0; str[i] != '\0'; i++) {
        if (str[i] == '%')
            str[i] = '*';
    }
}

/* FIXME: better complete this */
gchar *
coll_query_to_str (xmmsc_coll_t *coll)
{
    gchar *str = NULL;
    gchar *tmp1, *tmp2, *tmp3;
    xmmsc_coll_t *operand;

    switch (xmmsc_coll_get_type (coll)) {
        case XMMS_COLLECTION_TYPE_REFERENCE:
            break;
        case XMMS_COLLECTION_TYPE_UNION:
            tmp1 = g_strdup ("");
            for (xmmsc_coll_operand_list_first (coll);
                    xmmsc_coll_operand_list_entry (coll, &operand);
                    xmmsc_coll_operand_list_next (coll)) {
                tmp3 = coll_query_to_str (operand);
                tmp1 = g_strdup_printf ("%s%s, OR, ", tmp1, tmp3);
                g_free (tmp3);
            }
            str = g_malloc ((strlen (tmp1) - 5) * sizeof (gchar));
            strncpy (str, tmp1, strlen (tmp1) - 6);
            str[strlen (tmp1) - 6] = '\0';
            g_free (tmp1);
            g_strstrip (str);
            break;
        case XMMS_COLLECTION_TYPE_INTERSECTION:
            str = g_strdup ("");
            for (xmmsc_coll_operand_list_first (coll);
                    xmmsc_coll_operand_list_entry (coll, &operand);
                    xmmsc_coll_operand_list_next (coll)) {
                tmp3 = coll_query_to_str (operand);
                str = g_strdup_printf ("%s%s, ", str, tmp3);
                g_free (tmp3);
            }
            str[strlen (str) - 2] = ' ';
            g_strstrip (str);
            break;
        case XMMS_COLLECTION_TYPE_COMPLEMENT:
            break;
        case XMMS_COLLECTION_TYPE_HAS:
            break;
        case XMMS_COLLECTION_TYPE_EQUALS:
            xmmsc_coll_attribute_get (coll, "field", &tmp1);
            xmmsc_coll_attribute_get (coll, "value", &tmp2);
            str = g_strdup_printf ("%s:%s", tmp1, tmp2);
            /*
            xmmsc_coll_operand_list_first (coll);
            if (xmmsc_coll_operand_list_entry (coll, &operand)) {
                tmp3 = coll_query_to_str (operand);
                str = g_strdup_printf ("%s:%s,%s", field, value, tmp3);
                g_free (tmp3);
            }
            */
            break;
        case XMMS_COLLECTION_TYPE_MATCH:
            xmmsc_coll_attribute_get (coll, "field", &tmp1);
            xmmsc_coll_attribute_get (coll, "value", &tmp2);
            str_human_wildcards (tmp2);
            str = g_strdup_printf ("%s:%s", tmp1, tmp2);
            break;
        case XMMS_COLLECTION_TYPE_SMALLER:
            xmmsc_coll_attribute_get (coll, "field", &tmp1);
            xmmsc_coll_attribute_get (coll, "value", &tmp2);
            str = g_strdup_printf ("%s<%s", tmp1, tmp2);
            break;
        case XMMS_COLLECTION_TYPE_GREATER:
            xmmsc_coll_attribute_get (coll, "field", &tmp1);
            xmmsc_coll_attribute_get (coll, "value", &tmp2);
            str = g_strdup_printf ("%s>%s", tmp1, tmp2);
            break;
        case XMMS_COLLECTION_TYPE_IDLIST:
            break;
        case XMMS_COLLECTION_TYPE_QUEUE:
            break;
        case XMMS_COLLECTION_TYPE_PARTYSHUFFLE:
            break;
        default:
            break;
    }

    return str;
}

xmmsc_coll_t *
str_to_coll_query (const gchar *str)
{
    gchar **patternv, *tmp;
    gchar *pattern;
    xmmsc_coll_t *query;
    gint i;

    patternv = g_strsplit (str, ",", -1);
    for (i = 0; patternv[i]; i++) {
        /* FIXME: really strip this? */
        g_strstrip (patternv[i]);
        tmp = str_escape (patternv[i]);
        g_free (patternv[i]);
        patternv[i] = tmp;
    }

    pattern = g_strjoinv (" ", patternv);
    g_strfreev (patternv);

    if (!xmmsc_coll_parse (pattern, &query))
        query = NULL;

    g_free (pattern);

    return query;
}
