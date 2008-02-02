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
