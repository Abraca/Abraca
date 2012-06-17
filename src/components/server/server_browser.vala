/**
 * Abraca, an XMMS2 client.
 * Copyright (C) 2008-2012 Abraca Team
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

namespace Abraca {
	public class ServerBrowser : Gtk.Dialog, Gtk.Buildable
	{
		public enum Action {
			Cancel,
			Connect
		}

		private Gtk.TreeView _view;
		private Gtk.Button _button_add;
		private Gtk.Button _button_launch;
		private Gtk.Entry _entry_host;
		private Gtk.SpinButton _spin_button_port;
		private Gtk.Dialog _launcher_error_dialog;
		private Gtk.Expander _launcher_error_details_expander;
		private Gtk.TextView  _launcher_error_text_view;
		private string _launcher_prog;
		private string _launcher_logfile;

		public string? selected_host { get; private set; }

		public static ServerBrowser build (Gtk.Window parent)
		{
			var builder = new Gtk.Builder();
			try {
				builder.add_from_string(Resources.XML.server_browser,
				                        Resources.XML.server_browser.length);
			} catch (GLib.Error e) {
				GLib.error(e.message);
			}

			var browser = (ServerBrowser) builder.get_object("dialog1");
			browser.transient_for = parent;
			return browser;
		}

		public void parser_finished (Gtk.Builder builder)
		{
			unowned Gtk.TreeSelection selection;

			_view = (Gtk.TreeView) builder.get_object("treeview1");
			_button_add = (Gtk.Button) builder.get_object("button_add");
			_button_launch = (Gtk.Button) builder.get_object("button_launch");
			_entry_host = (Gtk.Entry) builder.get_object("entry_host");
			_spin_button_port = (Gtk.SpinButton) builder.get_object("spinbutton_port");
			_launcher_error_dialog = (Gtk.Dialog) builder.get_object("messagedialog1");
			_launcher_error_details_expander = (Gtk.Expander) builder.get_object("expander1");
			_launcher_error_text_view = (Gtk.TextView) builder.get_object("textview1");

			selection = _view.get_selection();
			selection.set_mode(Gtk.SelectionMode.BROWSE);
			selection.changed.connect(on_treeview_selection_changed);
			selection.select_path(new Gtk.TreePath.first());

			/* Set the value of the Gtk.SpinButton to xmms2's default tcp port. */
			_spin_button_port.value = Xmms.DEFAULT_TCP_PORT;

			/* If xmms2-launcher is not installed, hide the launch button. Note
			 * that on windows the .exe suffix is added by find_program_in_path().
			 * On operating systems other than unix-like and windows starting
			 * xmms2d is not supported, et all. */
#if G_OS_UNIX || G_OS_WIN32
			_launcher_prog = GLib.Environment.find_program_in_path("xmms2-launcher");
			if (_launcher_prog == null) {
#else
			if (true) {
#endif
				_button_launch.hide();
			}

			builder.connect_signals(this);
		}

		[CCode(instance_pos=-1)]
		public void on_add_clicked (Gtk.Button button)
		{
			var model = (ServerModel) _view.model;

			model.add_server_from_address(_entry_host.text, (uint16) _spin_button_port.value);
		}

		[CCode(instance_pos=-1)]
		public void on_connect_clicked (Gtk.Button button)
		{
			destroy();
		}

		[CCode(instance_pos=-1)]
		public void on_cancel_clicked (Gtk.Button button)
		{
			destroy();
		}

		[CCode(instance_pos=-1)]
		public void on_launch_clicked (Gtk.Button button)
		{
#if G_OS_UNIX || G_OS_WIN32
			int standard_output;
			int standard_error;
			GLib.Pid pid;
			var channels = new GLib.IOChannel[2];

			_launcher_error_text_view.set_buffer(new Gtk.TextBuffer(null));
			_launcher_error_details_expander.expanded = false;
			_launcher_error_details_expander.show();
			_launcher_logfile = null;

			try {
				GLib.Process.spawn_async_with_pipes(null,
				                                    {_launcher_prog},
				                                    null,
				                                    GLib.SpawnFlags.DO_NOT_REAP_CHILD,
				                                    null,
				                                    out pid,
				                                    null,
				                                    out standard_output,
				                                    out standard_error);
			} catch (GLib.SpawnError e) {
				var buffer = _launcher_error_text_view.get_buffer();
				buffer.insert_at_cursor(e.message, -1);

				_launcher_error_dialog.show();

				return;
			}

			button.sensitive = false;

#if G_OS_WIN32
			channels[0] = new GLib.IOChannel.win32_new_fd(standard_output);
			channels[1] = new GLib.IOChannel.win32_new_fd(standard_error);
#else
			channels[0] = new GLib.IOChannel.unix_new(standard_output);
			channels[1] = new GLib.IOChannel.unix_new(standard_error);
#endif

			for (int i = 0; i < channels.length; i++) {
				channels[i].add_watch(GLib.IOCondition.IN, (channel, cond) => {
					string s;

					if (_launcher_logfile != null) {
						return false;
					}

					try {
						channel.read_line(out s, null, null);
					} catch (GLib.Error e) {
						GLib.warning(e.message);
						return true;
					}

					if (s.has_prefix("Log output will be stored in")) {
						_launcher_logfile = s.substring(28).strip();
						return false;
					}

					return true;
				});
			}

			GLib.ChildWatch.add(pid, (pid, status) => {
				GLib.Process.close_pid(pid);

				/* Parse the tail of the log file and get the url xmms2d is
				 * listening on, when xmms2-launcher has finished successful.
				 * Otherwise insert the logi messages from the last run into
				 * the Gtk.TextView of the launcher error dialog. */
				if (_launcher_logfile != null) {
					try {
						var channel = new GLib.IOChannel.file(_launcher_logfile, "r");

						for (int64 pos = -27; ; pos--) {
							char[] buf = new char[27];
							size_t len;

							channel.seek_position(pos, GLib.SeekType.END);
							channel.read_chars(buf, out len);

							if (((string) buf).substring(0, (long) len) == "--- Starting new xmms2d ---") {
								string s;

								if (status == 0) {
									var regex = new GLib.Regex(": IPC listening on '([^']+)'");

									while (channel.read_line(out s, null, null) == GLib.IOStatus.NORMAL) {
										GLib.MatchInfo match;

										if (regex.match(s, 0, out match)) {
											((ServerModel) _view.model).add_server(null, match.fetch(1));

											return;
										}
									}

									channel.seek_position(pos + len, GLib.SeekType.END);
								}

								channel.read_to_end(out s, null);

								var buffer = _launcher_error_text_view.get_buffer();
								buffer.insert_at_cursor(s.strip(), -1);

								break;
							}
						}
					} catch (GLib.Error e) {
						/* If the log file is corrupted, was deleted after
						 * xmms2d has started up or something else really
						 * strange is happened, we are going to show the
						 * error dialog, but without details and log the
						 * error message. */
						GLib.warning(e.message);
						_launcher_error_details_expander.hide();
					}
				} else {
					_launcher_error_details_expander.hide();
				}

				_launcher_error_dialog.show();
				_button_launch.sensitive = true;
			});
#else
			GLib.assert_not_reached();
#endif
		}


		[CCode(instance_pos=-1)]
		public void on_treeview_selection_changed (Gtk.TreeSelection selection)
		{
			var view = selection.get_tree_view();
			var model = (ServerModel) view.model;
			var rows = selection.get_selected_rows(null);
			unowned GLib.List<Gtk.TreePath> row = rows.first();

			if (row != null) {
				selected_host = model.get_host_at_path(row.data);
			}
		}

		[CCode(instance_pos=-1)]
		public void on_treeview_row_activated (Gtk.TreeView view, Gtk.TreePath path,
		                                       Gtk.TreeViewColumn colunm)
		{
			var model = (ServerModel) view.model;
			selected_host = model.get_host_at_path(path);
			response(Action.Connect);

			destroy();
		}

		[CCode(instance_pos=-1)]
		public void on_favorite_toggled (CellRendererTogglePixbuf renderer, string updated)
		{
			var store = (Gtk.ListStore) _view.model;
			Gtk.TreeIter iter;
			bool favorite;

			store.get_iter(out iter, new Gtk.TreePath.from_string(updated));
			store.get(iter, ServerModel.Column.FAVORITE, out favorite);
			store.set(iter, ServerModel.Column.FAVORITE, !favorite);
		}

		[CCode(instance_pos=-1)]
		public void on_entry_host_changed (Gtk.Entry entry)
		{
			_button_add.sensitive = entry.text.strip() != "";
		}
	}
}
