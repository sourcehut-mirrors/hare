// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// This is an opaque type which encloses an OS-level file handle resource. It
// can be used as a [[handle]] in most situations, but there are some APIs which
// require a [[file]] with some OS-level handle backing it - this type is used
// for such APIs.
//
// On NetBSD, [[file]] is a file descriptor.
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
	if (let err: sys::errno = sys::close(fd)) {
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
	if (let err: sys::errno = sys::flock(fd: int, flags)) {
		if (err == sys::EWOULDBLOCK) {
			return false;
		} else {
			return errors::errno(err);
		};
	};
	return true;
};

fn fd_trunc(fd: file, ln: size) (void | error) = {
	if (let err: sys::errno = sys::ftruncate(fd: int, ln: sys::off_t)) {
		return errors::errno(err);
	};
};
