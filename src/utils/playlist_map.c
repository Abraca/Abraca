#include <stdlib.h>
#include "playlist_map.h"

struct playlist_map_St {
	GHashTable *hash;
	guint ref;
};

static void
_delete_list (GSList *lst)
{
	GtkTreeRowReference *row = (GtkTreeRowReference *) lst->data;

	if (lst->next != NULL) {
		_delete_list (lst->next);
	}

	gtk_tree_row_reference_free (row);
	g_slist_free_1 (lst);
}

static gboolean
_delete_content (gpointer key, gpointer value, gpointer udata)
{
	GSList *lst = (GSList *) value;

	_delete_list (lst);

	return TRUE;
}

playlist_map_t *
playlist_map_new (void)
{
	playlist_map_t *map;

	map = g_new0 (playlist_map_t, 1);
	map->hash = g_hash_table_new (NULL, NULL);

	playlist_map_ref (map);

	return map;
}

playlist_map_t *
playlist_map_ref (playlist_map_t *map)
{
	g_return_val_if_fail (map, NULL);

	map->ref++;

	return map;
}

void
playlist_map_unref (playlist_map_t *map)
{
	g_return_if_fail (map);

	map->ref--;

	if (map->ref == 0) {
		g_hash_table_foreach_remove (map->hash, _delete_content, NULL);
		g_hash_table_destroy (map->hash);
		g_free (map);
		map = NULL;
	}
}

void
playlist_map_insert (playlist_map_t *map, guint mid, GtkTreeRowReference *row)
{
	GtkTreeRowReference *copy;
	GSList *lst;

	g_return_if_fail (map);
	g_return_if_fail (row);

	copy = gtk_tree_row_reference_copy (row);

	lst = g_hash_table_lookup (map->hash, GUINT_TO_POINTER (mid));
	lst = g_slist_prepend (lst, copy);

	g_hash_table_insert (map->hash, GUINT_TO_POINTER (mid), lst);
}

gboolean
playlist_map_remove (playlist_map_t *map, guint mid, GtkTreePath *path)
{
	GSList *lst, *n;

	g_return_val_if_fail (map, FALSE);
	g_return_val_if_fail (path, FALSE);

	lst = g_hash_table_lookup (map->hash, GUINT_TO_POINTER (mid));
	if (lst == NULL) {
		return FALSE;
	}

	for (n = lst; n; n = n->next) {
		GtkTreeRowReference *row = (GtkTreeRowReference *) n->data;
		GtkTreePath *rpath = gtk_tree_row_reference_get_path (row);

		if (gtk_tree_path_compare (rpath, path) != 0) {
			continue;
		}

		lst = g_slist_remove_link(lst, n);
		gtk_tree_row_reference_free (row);
		g_slist_free_1 (n);

		if (lst == NULL) {
			g_hash_table_remove (map->hash, GUINT_TO_POINTER (mid));
		} else {
			g_hash_table_insert(map->hash, GUINT_TO_POINTER (mid), lst);
		}

		return TRUE;
	}

	return FALSE;
}

void
playlist_map_clear (playlist_map_t *map)
{
	g_return_if_fail (map);

	g_hash_table_foreach_remove (map->hash, _delete_content, NULL);
}

GSList *
playlist_map_lookup (playlist_map_t *map, uint mid)
{
	g_return_val_if_fail (map, NULL);

	return g_hash_table_lookup (map->hash, GUINT_TO_POINTER (mid));
}

GList *
playlist_map_get_ids (playlist_map_t *map)
{
	g_return_val_if_fail (map, NULL);

	return g_hash_table_get_keys (map->hash);
}
