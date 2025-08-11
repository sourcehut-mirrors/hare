// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Represents an error returned from the Sortix host.
export type errno = !int;

// Obtains a human-friendly reading of an [[errno]] (e.g. "Operation not
// permitted").
export fn strerror(err: errno) str = {
	switch (err) {
	case ENOTBLK =>
		return "Block device required";
	case ENODEV =>
		return "No such device";
	case EBADF =>
		return "Bad file descriptor";
	case EOVERFLOW =>
		return "Value too large to be stored in data type";
	case ENOENT =>
		return "No such file or directory";
	case ENOSPC =>
		return "No space left on device";
	case EEXIST =>
		return "File exists";
	case EROFS =>
		return "Read-only file system";
	case EINVAL =>
		return "Invalid argument";
	case ENOTDIR =>
		return "Not a directory";
	case ENOMEM =>
		return "Not enough memory";
	case ERANGE =>
		return "Result too large";
	case EISDIR =>
		return "Is a directory";
	case EPERM =>
		return "Operation not permitted";
	case EIO =>
		return "Input/output error";
	case ENOEXEC =>
		return "Exec format error";
	case EACCES =>
		return "Permission denied";
	case ESRCH =>
		return "No such process";
	case ENOTTY =>
		return "Not a tty";
	case ECHILD =>
		return "No child processes";
	case ENOSYS =>
		return "Function not implemented";
	case ENOTSUP =>
		return "Operation not supported";
	case EBLOCKING =>
		return "Operation is blocking";
	case EINTR =>
		return "Interrupted function call";
	case ENOTEMPTY =>
		return "Directory not empty";
	case EBUSY =>
		return "Device or resource busy";
	case EPIPE =>
		return "Broken pipe";
	case EILSEQ =>
		return "Invalid byte sequence";
	case ELAKE =>
		return "Sit by a lake";
	case EMFILE =>
		return "Too many open files";
	case EAGAIN =>
		return "Resource temporarily unavailable";
	case EEOF =>
		return "End of file";
	case EBOUND =>
		return "Out of bounds";
	case EINIT =>
		return "Not initialized";
	case ENODRV =>
		return "No such driver";
	case E2BIG =>
		return "Argument list too long";
	case EFBIG =>
		return "File too large";
	case EXDEV =>
		return "Improper link";
	case ESPIPE =>
		return "Cannot seek on stream";
	case ENAMETOOLONG =>
		return "Filename too long";
	case ELOOP =>
		return "Too many levels of symbolic links";
	case EMLINK =>
		return "Too many links";
	case ENXIO =>
		return "No such device or address";
	case EPROTONOSUPPORT =>
		return "Protocol not supported";
	case EAFNOSUPPORT =>
		return "Address family not supported";
	case ENOTSOCK =>
		return "Not a socket";
	case EADDRINUSE =>
		return "Address already in use";
	case ETIMEDOUT =>
		return "Connection timed out";
	case ECONNREFUSED =>
		return "Connection refused";
	case EDOM =>
		return "Mathematics argument out of domain of function";
	case EINPROGRESS =>
		return "Operation in progress";
	case EALREADY =>
		return "Connection already in progress";
	case ESHUTDOWN =>
		return "Cannot send after transport endpoint shutdown";
	case ECONNABORTED =>
		return "Connection aborted";
	case ECONNRESET =>
		return "Connection reset";
	case EADDRNOTAVAIL =>
		return "Address not available";
	case EISCONN =>
		return "Socket is connected";
	case EFAULT =>
		return "Bad address";
	case EDESTADDRREQ =>
		return "Destination address required";
	case EHOSTUNREACH =>
		return "Host is unreachable";
	case EMSGSIZE =>
		return "Message too long";
	case ENETDOWN =>
		return "Network is down";
	case ENETRESET =>
		return "Connection aborted by network";
	case ENETUNREACH =>
		return "Network is unreachable";
	case ENOBUFS =>
		return "No buffer space available";
	case ENOMSG =>
		return "No message of the desired type";
	case ENOPROTOOPT =>
		return "Protocol not available";
	case ENOTCONN =>
		return "Socket is not connected";
	case EDEADLK =>
		return "Resource deadlock avoided";
	case ENFILE =>
		return "Too many open files in system";
	case EPROTOTYPE =>
		return "Wrong protocol type for socket";
	case ENOLCK =>
		return "No locks available";
	case ESIGPENDING =>
		return "Signal is already pending";
	case ESTALE =>
		return "Stale file handle";
	case EBADMSG =>
		return "Bad message";
	case ECANCELED =>
		return "Operation canceled";
	case EDQUOT =>
		return "Disk quota exceeded";
	case EIDRM =>
		return "Identifier removed";
	case EMULTIHOP =>
		return "Multihop attempted";
	case ENOLINK =>
		return "Link has been severed";
	case ENOTRECOVERABLE =>
		return "State not recoverable";
	case EOWNERDEAD =>
		return "Previous owner died";
	case EPROTO =>
		return "Protocol error";
	case ETXTBSY =>
		return "Text file busy";
	case ENOMOUNT =>
		return "No such mountpoint";
	case ENOMEDIUM =>
		return "No medium found";
	case EHOSTDOWN =>
		return "Host is down";
	case ESOCKTNOSUPPORT =>
		return "Socket type is not supported";
	case =>
		return unknown_errno(err);
	};
};

// Gets the programmer-friendly name for an [[errno]] (e.g. EPERM).
export fn errname(err: errno) str = {
	switch (err) {
	case ENOTBLK =>
		return "ENOTBLK";
	case ENODEV =>
		return "ENODEV";
	case EBADF =>
		return "EBADF";
	case EOVERFLOW =>
		return "EOVERFLOW";
	case ENOENT =>
		return "ENOENT";
	case ENOSPC =>
		return "ENOSPC";
	case EEXIST =>
		return "EEXIST";
	case EROFS =>
		return "EROFS";
	case EINVAL =>
		return "=";
	case ENOTDIR =>
		return "ENOTDIR";
	case ENOMEM =>
		return "ENOMEM";
	case ERANGE =>
		return "ERANGE";
	case EISDIR =>
		return "EISDIR";
	case EPERM =>
		return "EPERM";
	case EIO =>
		return "EIO";
	case ENOEXEC =>
		return "ENOEXEC";
	case EACCES =>
		return "EACCES";
	case ESRCH =>
		return "ESRCH";
	case ENOTTY =>
		return "ENOTTY";
	case ECHILD =>
		return "ECHILD";
	case ENOSYS =>
		return "ENOSYS";
	case ENOTSUP =>
		return "ENOTSUP";
	case EBLOCKING =>
		return "EBLOCKING";
	case EINTR =>
		return "EINTR";
	case ENOTEMPTY =>
		return "ENOTEMPTY";
	case EBUSY =>
		return "EBUSY";
	case EPIPE =>
		return "EPIPE";
	case EILSEQ =>
		return "EILSEQ";
	case ELAKE =>
		return "ELAKE";
	case EMFILE =>
		return "EMFILE";
	case EAGAIN =>
		return "EAGAIN";
	case EEOF =>
		return "EEOF";
	case EBOUND =>
		return "EBOUND";
	case EINIT =>
		return "EINIT";
	case ENODRV =>
		return "ENODRV";
	case E2BIG =>
		return "E2BIG";
	case EFBIG =>
		return "EFBIG";
	case EXDEV =>
		return "EXDEV";
	case ESPIPE =>
		return "ESPIPE";
	case ENAMETOOLONG =>
		return "ENAMETOOLONG";
	case ELOOP =>
		return "ELOOP";
	case EMLINK =>
		return "EMLINK";
	case ENXIO =>
		return "ENXIO";
	case EPROTONOSUPPORT =>
		return "EPROTONOSUPPORT";
	case EAFNOSUPPORT =>
		return "EAFNOSUPPORT";
	case ENOTSOCK =>
		return "ENOTSOCK";
	case EADDRINUSE =>
		return "EADDRINUSE";
	case ETIMEDOUT =>
		return "ETIMEDOUT";
	case ECONNREFUSED =>
		return "ECONNREFUSED";
	case EDOM =>
		return "EDOM";
	case EINPROGRESS =>
		return "EINPROGRESS";
	case EALREADY =>
		return "EALREADY";
	case ESHUTDOWN =>
		return "ESHUTDOWN";
	case ECONNABORTED =>
		return "ECONNABORTED";
	case ECONNRESET =>
		return "ECONNRESET";
	case EADDRNOTAVAIL =>
		return "EADDRNOTAVAIL";
	case EISCONN =>
		return "EISCONN";
	case EFAULT =>
		return "EFAULT";
	case EDESTADDRREQ =>
		return "EDESTADDRREQ";
	case EHOSTUNREACH =>
		return "EHOSTUNREACH";
	case EMSGSIZE =>
		return "EMSGSIZE";
	case ENETDOWN =>
		return "ENETDOWN";
	case ENETRESET =>
		return "ENETRESET";
	case ENETUNREACH =>
		return "ENETUNREACH";
	case ENOBUFS =>
		return "ENOBUFS";
	case ENOMSG =>
		return "ENOMSG";
	case ENOPROTOOPT =>
		return "ENOPROTOOPT";
	case ENOTCONN =>
		return "ENOTCONN";
	case EDEADLK =>
		return "EDEADLK";
	case ENFILE =>
		return "ENFILE";
	case EPROTOTYPE =>
		return "EPROTOTYPE";
	case ENOLCK =>
		return "ENOLCK";
	case ESIGPENDING =>
		return "ESIGPENDING";
	case ESTALE =>
		return "ESTALE";
	case EBADMSG =>
		return "EBADMSG";
	case ECANCELED =>
		return "ECANCELED";
	case EDQUOT =>
		return "EDQUOT";
	case EIDRM =>
		return "EIDRM";
	case EMULTIHOP =>
		return "EMULTIHOP";
	case ENOLINK =>
		return "ENOLINK";
	case ENOTRECOVERABLE =>
		return "ENOTRECOVERABLE";
	case EOWNERDEAD =>
		return "EOWNERDEAD";
	case EPROTO =>
		return "EPROTO";
	case ETXTBSY =>
		return "ETXTBSY";
	case ENOMOUNT =>
		return "ENOMOUNT";
	case ENOMEDIUM =>
		return "ENOMEDIUM";
	case EHOSTDOWN =>
		return "EHOSTDOWN";
	case ESOCKTNOSUPPORT =>
		return "ESOCKTNOSUPPORT";
	case =>
		return unknown_errno(err);
	};
};

export def ENOTBLK: errno = 12;
export def ENODEV: errno = 13;
export def EBADF: errno = 15;
export def EOVERFLOW: errno = 16;
export def ENOENT: errno = 17;
export def ENOSPC: errno = 18;
export def EEXIST: errno = 19;
export def EROFS: errno = 20;
export def EINVAL: errno = 21;
export def ENOTDIR: errno = 22;
export def ENOMEM: errno = 23;
export def ERANGE: errno = 24;
export def EISDIR: errno = 25;
export def EPERM: errno = 26;
export def EIO: errno = 27;
export def ENOEXEC: errno = 28;
export def EACCES: errno = 29;
export def ESRCH: errno = 30;
export def ENOTTY: errno = 31;
export def ECHILD: errno = 32;
export def ENOSYS: errno = 33;
export def ENOTSUP: errno = 34;
export def EBLOCKING: errno = 35;
export def EINTR: errno = 36;
export def ENOTEMPTY: errno = 37;
export def EBUSY: errno = 38;
export def EPIPE: errno = 39;
export def EILSEQ: errno = 40;
export def ELAKE: errno = 41;
export def EMFILE: errno = 42;
export def EAGAIN: errno = 43;
export def EEOF: errno = 44;
export def EBOUND: errno = 45;
export def EINIT: errno = 46;
export def ENODRV: errno = 47;
export def E2BIG: errno = 48;
export def EFBIG: errno = 49;
export def EXDEV: errno = 50;
export def ESPIPE: errno = 51;
export def ENAMETOOLONG: errno = 52;
export def ELOOP: errno = 53;
export def EMLINK: errno = 54;
export def ENXIO: errno = 55;
export def EPROTONOSUPPORT: errno = 56;
export def EAFNOSUPPORT: errno = 57;
export def ENOTSOCK: errno = 58;
export def EADDRINUSE: errno = 59;
export def ETIMEDOUT: errno = 60;
export def ECONNREFUSED: errno = 61;
export def EDOM: errno = 62;
export def EINPROGRESS: errno = 63;
export def EALREADY: errno = 64;
export def ESHUTDOWN: errno = 65;
export def ECONNABORTED: errno = 66;
export def ECONNRESET: errno = 67;
export def EADDRNOTAVAIL: errno = 68;
export def EISCONN: errno = 69;
export def EFAULT: errno = 70;
export def EDESTADDRREQ: errno = 71;
export def EHOSTUNREACH: errno = 72;
export def EMSGSIZE: errno = 73;
export def ENETDOWN: errno = 74;
export def ENETRESET: errno = 75;
export def ENETUNREACH: errno = 76;
export def ENOBUFS: errno = 77;
export def ENOMSG: errno = 78;
export def ENOPROTOOPT: errno = 79;
export def ENOTCONN: errno = 80;
export def EDEADLK: errno = 81;
export def ENFILE: errno = 82;
export def EPROTOTYPE: errno = 83;
export def ENOLCK: errno = 84;
export def ESIGPENDING: errno = 87;
export def ESTALE: errno = 88;
export def EBADMSG: errno = 89;
export def ECANCELED: errno = 90;
export def EDQUOT: errno = 91;
export def EIDRM: errno = 92;
export def EMULTIHOP: errno = 93;
export def ENOLINK: errno = 94;
export def ENOTRECOVERABLE: errno = 95;
export def EOWNERDEAD: errno = 96;
export def EPROTO: errno = 97;
export def ETXTBSY: errno = 98;
export def ENOMOUNT: errno = 99;
export def ENOMEDIUM: errno = 100;
export def EHOSTDOWN: errno = 101;
export def ESOCKTNOSUPPORT: errno = 102;
export def EOPNOTSUPP = ENOTSUP;
export def EWOULDBLOCK = EAGAIN;
