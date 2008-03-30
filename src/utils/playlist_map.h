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

#ifndef __PLAYLIST_MAP_H__
#define __PLAYLIST_MAP_H__

#include <gtk/gtk.h>

typedef struct playlist_map_St playlist_map_t;

playlist_map_t *playlist_map_new (void);
playlist_map_t *playlist_map_ref (playlist_map_t *map);
void playlist_map_unref (playlist_map_t *map);
void playlist_map_insert (playlist_map_t *map, guint mid, GtkTreeRowReference *row);
gboolean playlist_map_remove (playlist_map_t *map, guint mid, GtkTreePath *path);
GSList *playlist_map_lookup (playlist_map_t *map, uint mid);
GList *playlist_map_get_ids (playlist_map_t *map);
void playlist_map_clear (playlist_map_t *map);

#endif
