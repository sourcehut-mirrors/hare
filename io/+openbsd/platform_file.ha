// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// This is an opaque type which encloses an OS-level file handle resource. It
// can be used as a [[handle]] in most situations, but there are some APIs which
// require a [[file]] with some OS-level handle backing it - this type is used
// for such APIs.
//
// On OpenBSD, [[file]] is a file descriptor.
export type file = int;

// Opens a Unix file descriptor as a file. This is a low-level interface, to
// open files most programs will use something like [[os::open]]. This function
// is not portable.
export fn fdopen(fd: int) file = fd;

fn fd_read(fd: file, buf: []u8) (size | EOF | error) = {
	match (sys::read(fd, buf: *[*]u8, len(buf))) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let n: size =>
		switch (n) {
		case 0 =>
			return EOF;
		case =>
			return n;
		};
	};
};

fn fd_write(fd: file, buf: const []u8) (size | error) = {
	match (sys::write(fd, buf: *const [*]u8, len(buf))) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let n: size =>
		return n;
	};
};

fn fd_close(fd: file) (void | error) = {
	match (sys::close(fd)) {
	case void => void;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

fn fd_seek(
	fd: file,
	offs: off,
	whence: whence,
) (off | error) = {
	match (sys::lseek(fd, offs: i64, whence: int)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let n: i64 =>
		return n: off;
	};
};

fn fd_copy(to: file, from: file) (size | error) = errors::unsupported;

fn fd_lock(fd: file, flags: int) (bool | error) = {
	match (sys::flock(fd: int, flags)) {
	case void => return true;
	case let e: sys::errno =>
		if (e == sys::EWOULDBLOCK: sys::errno) {
			return false;
		} else {
			return errors::errno(e);
		};
	};
};

fn fd_trunc(fd: file, ln: size) (void | error) = {
	match (sys::ftruncate(fd: int, ln: sys::off_t)) {
	case void => void;
	case let e: sys::errno => return errors::errno(e);
	};
};

// Lock operation to use with [[lock]].
export type lockop = enum int {
	// shared file lock
	SHARED    = sys::LOCK_SH,
	// exclusive file lock
	EXCLUSIVE = sys::LOCK_EX,
	// unlock file
	UNLOCK    = sys::LOCK_UN,
};

// Apply or remove an advisory lock on an open file. If block is true, the
// request will block while waiting for the lock.
export fn lock(fd: file, block: bool, op: lockop) (bool | error) = {
	let flags = op: int;
	if (!block) flags |= sys::LOCK_NB;
	return fd_lock(fd, flags);
}
