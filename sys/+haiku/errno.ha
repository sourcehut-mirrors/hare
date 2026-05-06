// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Represents an error returned from the OpenBSD kernel.
export type errno = !int;

// /system/develop/headers/posix/errno.h: #define errno (*_errnop())
@symbol("_errnop") fn _errnop() *int;

fn get_errno() errno = {
	return *_errnop(): errno;
};

fn check_error(cond: bool) (void | errno) = {
	if (cond) {
		return *_errnop(): errno;
	};
};

// Obtains a human-friendly reading of an [[errno]] (e.g. "Operation not
// permitted").
export fn strerror(err: errno) str = {
	switch (err) {
	case E2BIG =>
		return "Argument too big";
	case ECHILD =>
		return "No child process";
	case EDEADLK =>
		return "Resource deadlock";
	case EFBIG =>
		return "File too large";
	case EMLINK =>
		return "Too many links";
	case ENFILE =>
		return "File table overflow";
	case ENODEV =>
		return "No such device";
	case ENOLCK =>
		return "No record locks available";
	case ENOSYS =>
		return "Function not implemented";
	case ENOTTY =>
		return "Not a tty";
	case ENXIO =>
		return "Device not accessible";
	case ESPIPE =>
		return "Seek not allowed on file descriptor";
	case ESRCH =>
		return "No such process";
	case EFPOS =>
		return "File Position Error";
	case ESIGPARM =>
		return "Signal Error";
	case EDOM =>
		return "Numerical argument out of range";
	case ERANGE =>
		return "Range Error";
	case EPROTOTYPE =>
		return "Protocol wrong type for socket";
	case EPROTONOSUPPORT =>
		return "Protocol not supported";
	case EPFNOSUPPORT =>
		return "Protocol family not supported";
	case EAFNOSUPPORT =>
		return "Address family not supported by protocol family";
	case EADDRINUSE =>
		return "Address already in use";
	case EADDRNOTAVAIL =>
		return "Can't assign requested address";
	case ENETDOWN =>
		return "Network is down";
	case ENETUNREACH =>
		return "Network is unreachable";
	case ENETRESET =>
		return "Network dropped connection on reset";
	case ECONNABORTED =>
		return "Software caused connection abort";
	case ECONNRESET =>
		return "Connection reset by peer";
	case EISCONN =>
		return "Socket is already connected";
	case ENOTCONN =>
		return "Socket is not connected";
	case ESHUTDOWN =>
		return "Can't send after socket shutdown";
	case ECONNREFUSED =>
		return "Connection refused";
	case EHOSTUNREACH =>
		return "No route to host";
	case ENOPROTOOPT =>
		return "Protocol option not available";
	case ENOBUFS =>
		return "No buffer space available";
	case EINPROGRESS =>
		return "Operation now in progress";
	case EALREADY =>
		return "Operation already in progress";
	case EILSEQ =>
		return "Illegal byte sequence";
	case ENOMSG =>
		return "No message of desired type";
	case ESTALE =>
		return "Stale file handle";
	case EOVERFLOW =>
		return "Value too large for defined type";
	case EMSGSIZE =>
		return "Message too long";
	case EOPNOTSUPP =>
		return "Operation not supported";
	case ENOTSOCK =>
		return "Socket operation on non-socket";
	case EHOSTDOWN =>
		return "Host is down";
	case EBADMSG =>
		return "Bad message";
	case ECANCELED =>
		return "Operation canceled";
	case EDESTADDRREQ =>
		return "Destination address required";
	case EDQUOT =>
		return "Reserved";
	case EIDRM =>
		return "Identifier removed";
	case EMULTIHOP =>
		return "Reserved";
	case ENODATA =>
		return "No message available";
	case ENOLINK =>
		return "Reserved";
	case ENOSR =>
		return "No STREAM resources";
	case ENOSTR =>
		return "Not a STREAM";
	case ENOTSUP =>
		return "Not supported";
	case EPROTO =>
		return "Protocol error";
	case ETIME =>
		return "STREAM ioctl() timeout";
	case ETXTBSY =>
		return "Text file busy";
	case ENOATTR =>
		return "No such attribute";
	case ENOTRECOVERABLE =>
		return "State not recoverable";
	case EOWNERDEAD =>
		return "Previous owner died";
	case ENOMEM =>
		return "Out of memory";
	case EACCES =>
		return "Permission denied";
	case EINTR =>
		return "Interrupted system call";
	case EIO =>
		return "I/O error";
	case EBUSY =>
		return "Device/File/Resource busy";
	case EFAULT =>
		return "Bad address";
	case ETIMEDOUT =>
		return "Operation timed out";
	case EAGAIN =>
		return "Operation would block";
	case EBADF =>
		return "Bad file descriptor";
	case EEXIST =>
		return "File or Directory already exists";
	case EINVAL =>
		return "Invalid Argument";
	case ENAMETOOLONG =>
		return "File name too long";
	case ENOENT =>
		return "No such file or directory";
	case EPERM =>
		return "Operation not allowed";
	case ENOTDIR =>
		return "Not a directory";
	case EISDIR =>
		return "Is a directory";
	case ENOTEMPTY =>
		return "Directory not empty";
	case ENOSPC =>
		return "No space left on device";
	case EROFS =>
		return "Read-only file system";
	case EMFILE =>
		return "Too many open files";
	case EXDEV =>
		return "Cross-device link";
	case ELOOP =>
		return "Too many symbolic links";
	case ENOEXEC =>
		return "Not an executable";
	case EPIPE =>
		return "Broken pipe";
	case =>
		return "Unknown error";
	};
};

// Gets the programmer-friendly name for an [[errno]] (e.g. EPERM).
export fn errname(err: errno) str = {
	switch (err) {
	case E2BIG =>
		return "E2BIG";
	case ECHILD =>
		return "ECHILD";
	case EDEADLK =>
		return "EDEADLK";
	case EFBIG =>
		return "EFBIG";
	case EMLINK =>
		return "EMLINK";
	case ENFILE =>
		return "ENFILE";
	case ENODEV =>
		return "ENODEV";
	case ENOLCK =>
		return "ENOLCK";
	case ENOSYS =>
		return "ENOSYS";
	case ENOTTY =>
		return "ENOTTY";
	case ENXIO =>
		return "ENXIO";
	case ESPIPE =>
		return "ESPIPE";
	case ESRCH =>
		return "ESRCH";
	case EFPOS =>
		return "EFPOS";
	case ESIGPARM =>
		return "ESIGPARM";
	case EDOM =>
		return "EDOM";
	case ERANGE =>
		return "ERANGE";
	case EPROTOTYPE =>
		return "EPROTOTYPE";
	case EPROTONOSUPPORT =>
		return "EPROTONOSUPPORT";
	case EPFNOSUPPORT =>
		return "EPFNOSUPPORT";
	case EAFNOSUPPORT =>
		return "EAFNOSUPPORT";
	case EADDRINUSE =>
		return "EADDRINUSE";
	case EADDRNOTAVAIL =>
		return "EADDRNOTAVAIL";
	case ENETDOWN =>
		return "ENETDOWn ";
	case ENETUNREACH =>
		return "ENETUNREACH";
	case ENETRESET =>
		return "ENETRESET";
	case ECONNABORTED =>
		return "ECONNABORTED";
	case ECONNRESET =>
		return "ECONNRESET";
	case EISCONN =>
		return "EISCONn ";
	case ENOTCONN =>
		return "ENOTCONn ";
	case ESHUTDOWN =>
		return "ESHUTDOWn ";
	case ECONNREFUSED =>
		return "ECONNREFUSED";
	case EHOSTUNREACH =>
		return "EHOSTUNREACH";
	case ENOPROTOOPT =>
		return "ENOPROTOOPT";
	case ENOBUFS =>
		return "ENOBUFS";
	case EINPROGRESS =>
		return "EINPROGRESS";
	case EALREADY =>
		return "EALREADY";
	case EILSEQ =>
		return "EILSEQ";
	case ENOMSG =>
		return "ENOMSG";
	case ESTALE =>
		return "ESTALE";
	case EOVERFLOW =>
		return "EOVERFLOW";
	case EMSGSIZE =>
		return "EMSGSIZE";
	case EOPNOTSUPP =>
		return "EOPNOTSUPP";
	case ENOTSOCK =>
		return "ENOTSOCK";
	case EHOSTDOWN =>
		return "EHOSTDOWn ";
	case EBADMSG =>
		return "EBADMSG";
	case ECANCELED =>
		return "ECANCELED";
	case EDESTADDRREQ =>
		return "EDESTADDRREQ";
	case EDQUOT =>
		return "EDQUOT";
	case EIDRM =>
		return "EIDRM";
	case EMULTIHOP =>
		return "EMULTIHOP";
	case ENODATA =>
		return "ENODATA";
	case ENOLINK =>
		return "ENOLINK";
	case ENOSR =>
		return "ENOSR";
	case ENOSTR =>
		return "ENOSTR";
	case ENOTSUP =>
		return "ENOTSUP";
	case EPROTO =>
		return "EPROTO";
	case ETIME =>
		return "ETIME";
	case ETXTBSY =>
		return "ETXTBSY";
	case ENOATTR =>
		return "ENOATTR";
	case ENOTRECOVERABLE =>
		return "ENOTRECOVERABLE";
	case EOWNERDEAD =>
		return "EOWNERDEAD";
	case ENOMEM =>
		return "ENOMEM";
	case EACCES =>
		return "EACCES";
	case EINTR =>
		return "EINTR";
	case EIO =>
		return "EIO";
	case EBUSY =>
		return "EBUSY";
	case EFAULT =>
		return "EFAULT";
	case ETIMEDOUT =>
		return "ETIMEDOUT";
	case EAGAIN =>
		return "EAGAIn ";
	case EBADF =>
		return "EBADF";
	case EEXIST =>
		return "EEXIST";
	case EINVAL =>
		return "EINVAL";
	case ENAMETOOLONG =>
		return "ENAMETOOLONG";
	case ENOENT =>
		return "ENOENT";
	case EPERM =>
		return "EPERM";
	case ENOTDIR =>
		return "ENOTDIR";
	case EISDIR =>
		return "EISDIR";
	case ENOTEMPTY =>
		return "ENOTEMPTY";
	case ENOSPC =>
		return "ENOSPC";
	case EROFS =>
		return "EROFS";
	case EMFILE =>
		return "EMFILE";
	case EXDEV =>
		return "EXDEV";
	case ELOOP =>
		return "ELOOP";
	case ENOEXEC =>
		return "ENOEXEC";
	case EPIPE =>
		return "EPIPE";
	case =>
		return "EUNKNOWN";
	};
};

export def E2BIG: errno = -2147454975;
export def ECHILD: errno = -2147454974;
export def EDEADLK: errno = -2147454973;
export def EFBIG: errno = -2147454972;
export def EMLINK: errno = -2147454971;
export def ENFILE: errno = -2147454970;
export def ENODEV: errno = -2147454969;
export def ENOLCK: errno = -2147454968;
export def ENOSYS: errno = -2147454967;
export def ENOTTY: errno = -2147454966;
export def ENXIO: errno = -2147454965;
export def ESPIPE: errno = -2147454964;
export def ESRCH: errno = -2147454963;
export def EFPOS: errno = -2147454962;
export def ESIGPARM: errno = -2147454961;
export def EDOM: errno = -2147454960;
export def ERANGE: errno = -2147454959;
export def EPROTOTYPE: errno = -2147454958;
export def EPROTONOSUPPORT: errno = -2147454957;
export def EPFNOSUPPORT: errno = -2147454956;
export def EAFNOSUPPORT: errno = -2147454955;
export def EADDRINUSE: errno = -2147454954;
export def EADDRNOTAVAIL: errno = -2147454953;
export def ENETDOWN: errno = -2147454952;
export def ENETUNREACH: errno = -2147454951;
export def ENETRESET: errno = -2147454950;
export def ECONNABORTED: errno = -2147454949;
export def ECONNRESET: errno = -2147454948;
export def EISCONN: errno = -2147454947;
export def ENOTCONN: errno = -2147454946;
export def ESHUTDOWN: errno = -2147454945;
export def ECONNREFUSED: errno = -2147454944;
export def EHOSTUNREACH: errno = -2147454943;
export def ENOPROTOOPT: errno = -2147454942;
export def ENOBUFS: errno = -2147454941;
export def EINPROGRESS: errno = -2147454940;
export def EALREADY: errno = -2147454939;
export def EILSEQ: errno = -2147454938;
export def ENOMSG: errno = -2147454937;
export def ESTALE: errno = -2147454936;
export def EOVERFLOW: errno = -2147454935;
export def EMSGSIZE: errno = -2147454934;
export def EOPNOTSUPP: errno = -2147454933;
export def ENOTSOCK: errno = -2147454932;
export def EHOSTDOWN: errno = -2147454931;
export def EBADMSG: errno = -2147454930;
export def ECANCELED: errno = -2147454929;
export def EDESTADDRREQ: errno = -2147454928;
export def EDQUOT: errno = -2147454927;
export def EIDRM: errno = -2147454926;
export def EMULTIHOP: errno = -2147454925;
export def ENODATA: errno = -2147454924;
export def ENOLINK: errno = -2147454923;
export def ENOSR: errno = -2147454922;
export def ENOSTR: errno = -2147454921;
export def ENOTSUP: errno = -2147454920;
export def EPROTO: errno = -2147454919;
export def ETIME: errno = -2147454918;
export def ETXTBSY: errno = -2147454917;
export def ENOATTR: errno = -2147454916;
export def ENOTRECOVERABLE: errno = -2147454915;
export def EOWNERDEAD: errno = -2147454914;
export def ENOMEM: errno = -2147483648;
export def EACCES: errno = -2147483646;
export def EINTR: errno = -2147483638;
export def EIO: errno = -2147483647;
export def EBUSY: errno = -2147483634;
export def EFAULT: errno = -2147478783;
export def ETIMEDOUT: errno = -2147483639;
export def EAGAIN: errno = -2147483637;
export def EWOULDBLOCK: errno = EAGAIN;
export def EBADF: errno = -2147459072;
export def EEXIST: errno = -2147459070;
export def EINVAL: errno = -2147483643;
export def ENAMETOOLONG: errno = -2147459068;
export def ENOENT: errno = -2147459069;
export def EPERM: errno = -2147483633;
export def ENOTDIR: errno = -2147459067;
export def EISDIR: errno = -2147459063;
export def ENOTEMPTY: errno = -2147459066;
export def ENOSPC: errno = -2147459065;
export def EROFS: errno = -2147459064;
export def EMFILE: errno = -2147459062;
export def EXDEV: errno = -2147459061;
export def ELOOP: errno = -2147459060;
export def ENOEXEC: errno = -2147478782;
export def EPIPE: errno = -2147459059;
