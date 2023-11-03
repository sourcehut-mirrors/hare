use errors;
use rt;

// Duplicates a file descriptor.
export fn dup(old: file) (file | error) = {
	match (rt::dup2(old, -1)) {
	case let fd: int =>
		let flags = rt::fcntl(fd, rt::F_GETFD, 0)!;
		rt::fcntl(fd, rt::F_SETFD, flags | rt::FD_CLOEXEC)!;
		return fd;
	case let e: rt::errno =>
		return errors::errno(e);
	};
};

// Duplicates a file descriptor and stores the new file at a specific file
// descriptor number. If the file indicated by "new" already refers to an open
// file, this file will be closed before the file descriptor is reused.
export fn dup2(old: file, new: file) (file | error) = {
	match (rt::dup2(old, new)) {
	case let fd: int =>
		let flags = rt::fcntl(fd, rt::F_GETFD, 0)!;
		rt::fcntl(fd, rt::F_SETFD, flags | rt::FD_CLOEXEC)!;
		return fd;
	case let e: rt::errno =>
		return errors::errno(e);
	};
};
