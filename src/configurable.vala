namespace Abraca {
	public interface IConfigurable : GLib.Object {
		public abstract void set_configuration(GLib.KeyFile file) throws GLib.KeyFileError;
		public abstract void get_configuration(GLib.KeyFile file);
	}
}
