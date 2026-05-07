// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;

// Flags to use for the [[io::file]]s returned by [[pipe]].
// Only NOCLOEXEC and NONBLOCK are guaranteed to be available.
export type pipe_flag = enum {
	NOCLOEXEC = sys::O_CLOEXEC,
	NONBLOCK = sys::O_NONBLOCK,
};

// Create a pair of two linked [[io::file]]s, such that any data written to the
// second [[io::file]] may be read from the first.
export fn pipe(flags: pipe_flag = 0) ((io::file, io::file) | errors::error) = {
	let fds: [2]int = [0...];
	match (sys::pipe(&fds)) {
	case void => void;
	case let e: sys::errno =>
		return errors::errno(e);
	};

	if (flags & pipe_flag::NOCLOEXEC == 0) {
		match (sys::fcntl(fds[0], sys::F_SETFD, sys::FD_CLOEXEC)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
		match (sys::fcntl(fds[1], sys::F_SETFD, sys::FD_CLOEXEC)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
	};

	if (flags & pipe_flag::NONBLOCK != 0) {
		match (sys::fcntl(fds[0], sys::F_SETFL, sys::O_NONBLOCK)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
		match (sys::fcntl(fds[1], sys::F_SETFL, sys::O_NONBLOCK)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
	};

	return (fds[0], fds[1]);
};
