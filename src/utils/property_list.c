/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008  Abraca Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <stdlib.h>
#include "property_list.h"

struct property_list_St {
	gchar **list;
	guint ref;
};

property_list_t *
property_list_new (gchar **properties) {
	property_list_t *props;
	guint length, i;

	g_return_val_if_fail(properties && properties[0], NULL);

	length = g_strv_length (properties);

	props = g_new0 (property_list_t, 1);
	props->list = g_new0 (gchar *, length + 1);

	for (i = 0; properties[i]; i++) {
		props->list[i] = g_strdup (properties[i]);
	}

	return property_list_ref (props);
}

property_list_t *
property_list_ref (property_list_t *props)
{
	g_return_val_if_fail (props, NULL);

	props->ref++;

	return props;
}

void
property_list_unref (property_list_t *props)
{
	g_return_if_fail (props);

	props->ref--;

	if (props->ref == 0) {
		g_strfreev (props->list);
		g_free (props);
		props = NULL;
	}
}

gchar **
property_list_get (property_list_t *props, gint *length)
{
	*length = property_list_get_length (props);

	return props->list;
}

gint 
property_list_get_length (property_list_t *props)
{
	return g_strv_length (props->list);
}
