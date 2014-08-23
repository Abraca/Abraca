[CCode(cheader_filename="sys/socket.h")]
public class Platform.Socket {
	[CCode(cname="SOL_SOCKET")]
	public const int SOL_SOCKET;
	[CCode(cname="SO_REUSEPORT")]
	public const int SO_REUSEPORT;
}
