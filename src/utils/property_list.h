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

#ifndef __PROPERTY_LIST_H__
#define __PROPERTY_LIST_H__

#include <glib.h>

typedef struct property_list_St property_list_t;

property_list_t *property_list_new (gchar **properties);
property_list_t *property_list_ref (property_list_t *props);
void property_list_unref (property_list_t *props);
gchar **property_list_get (property_list_t *props, gint *length);
gint property_list_get_length (property_list_t *props);

#endif
