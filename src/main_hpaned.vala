/*
 * vim:noexpandtab:sw=4:sts=0:ts=4:syn=cs
 */
using GLib;

namespace Abraca {
	public class MainHPaned : Gtk.HPaned {
		private CollectionsTree _coll_tree;
		private RightHPaned right_hpaned;

		public CollectionsTree collections_tree {
			get {
				return _coll_tree;
			}
		}

		construct {
			position = 120;
			position_set = false;

			create_widgets();
		}

		public void eval_config() {
			int pos = Abraca.instance().config.panes_pos1;

			position = pos.clamp(120, 800);

			/* other widgets */
			right_hpaned.eval_config();
		}

		private void create_widgets() {
			Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow(
				null, null
			);

			scrolled.set_policy(Gtk.PolicyType.AUTOMATIC,
			                    Gtk.PolicyType.AUTOMATIC);

			_coll_tree = new CollectionsTree();
			scrolled.add_with_viewport(_coll_tree);

			pack1(scrolled, false, true);

			right_hpaned = new RightHPaned();
			pack2(right_hpaned, true, true);
		}
	}
}
