namespace Abraca {
	public interface IConfigurable {
		public abstract void set_configuration(weak GLib.KeyFile file) throws GLib.KeyFileError;
		public abstract void get_configuration(weak GLib.KeyFile file);
	}
}
