/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2014 Abraca Team
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

public interface Abraca.MetadataRequestor : GLib.Object
{
	public abstract void set_attributes(string[] attrs);
	public abstract void resolve(int mid);
}

public class Abraca.MetadataResolver : GLib.Object {
	public delegate void MetadataResolvedFunc(Xmms.Value value);
	public delegate void MetadataResolverEnqueueFunc(int token, int mid);

	private static Xmms.Value EMPTY_LIST = new Xmms.Value.from_list();
	private static uint LATENCY_MS = 100;

	private class MetadataRequestorImpl : GLib.Object, Abraca.MetadataRequestor
	{
		public unowned MetadataResolverEnqueueFunc enqueue;
		public unowned MetadataResolvedFunc resolved;
		public int token;
		public Xmms.Value attributes;

		public MetadataRequestorImpl(int token, MetadataResolvedFunc resolved, MetadataResolverEnqueueFunc enqueue)
		{
			this.token = token;
			this.resolved = resolved;
			this.enqueue = enqueue;
		}

		public void set_attributes(string[] attrs)
		{
			var value = new Xmms.Value.from_list();
			value.list_append_string("id");

			foreach (var attribute in attrs)
				value.list_append_string(attribute);

			attributes = value;
		}

		public void resolve(int mid)
		{
			enqueue(token, mid);
		}
	}

	private Gee.List<MetadataRequestorImpl> listeners = new Gee.ArrayList<MetadataRequestorImpl>();

	private Gee.List<int> pending = new Gee.ArrayList<int>();
	private Gee.Map<int,Xmms.Collection> pending_mids = new Gee.HashMap<int,Xmms.Collection>();

	private uint timeout_handle = 0;
	private bool in_flight = false;
	private int in_flight_token = -1;
	private int64 target = -1;

	private Client client;

	public MetadataResolver(Client client)
	{
		Object();
		this.client = client;
	}

	public MetadataRequestor register(MetadataResolvedFunc func)
	{
		var requestor = new MetadataRequestorImpl(listeners.size, func, (token, mid) => resolve(token, mid));
		listeners.add(requestor);
		return requestor;
	}

	private void resolve(int token, int mid)
		requires(0 <= token < listeners.size)
	{
		Xmms.Collection? list = pending_mids[token];
		if (list == null) {
			list = new Xmms.Collection(Xmms.CollectionType.IDLIST);
			pending_mids.set(token, list);
			pending.add(token);
		}
		list.idlist_append(mid);

		if (!in_flight)
			arm_timer();
	}

	private void arm_timer()
		requires(!pending.is_empty)
		requires(!in_flight)
	{
		target = GLib.get_monotonic_time() + LATENCY_MS;
		if (timeout_handle == 0) {
			timeout_handle = GLib.Timeout.add(LATENCY_MS, on_timeout);
		}
	}

	private bool on_timeout()
	{
		Xmms.Collection list;

		if (in_flight || GLib.get_monotonic_time() < target)
			return true;

		var token = pending.remove_at(0);
		pending_mids.unset(token, out list);

		var listener = listeners[token];

		client.xmms.coll_query_infos(list, EMPTY_LIST, 0, 0, listener.attributes, EMPTY_LIST).notifier_set(
			on_coll_query_infos
		);

		in_flight = true;
		in_flight_token = token;

		timeout_handle = 0;

		return false;
	}

	private bool on_coll_query_infos(Xmms.Value value)
		requires(0 <= in_flight_token < listeners.size)
	{
		var listener = listeners[in_flight_token];

		in_flight = false;

		if (!pending.is_empty)
			arm_timer();

		/* dispatch callback later in mainloop so the next
		 * query can be dispatched while the result is being
		 * processed
		 */
		GLib.Idle.add(() => {
			listener.resolved(value);
			return false;
		});

		return true;
	}
}
