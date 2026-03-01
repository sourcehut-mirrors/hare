// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;

// Flags for [[memfd]].
export type memfd_flag = enum uint {
	NONE = 0,
	// Unsets the close-on-exec flag when creating a memfd.
	NOCLOEXEC = 1,
	// Allows sealing operations on this file.
	ALLOW_SEALING = 2,
};

// Creates a new anonymous [[io::file]] backed by memory.
//
// The initial file size is zero. It can be written to normally, or the size can
// be set manually with [[io::trunc]].
//
// This function is available on Linux and FreeBSD.
export fn memfd(
	name: str,
	flags: memfd_flag = memfd_flag::NONE,
) (io::file | errors::error) = {
	let oflag = sys::O_RDWR | sys::O_CLOEXEC;
	let shm_flag = sys::SHM_GROW_ON_WRITE;
	if (flags & memfd_flag::NOCLOEXEC != 0) {
		oflag &= ~sys::O_CLOEXEC;
	};
	if (flags & memfd_flag::ALLOW_SEALING != 0) {
		shm_flag |= sys::SHM_ALLOW_SEALING;
	};

	match (sys::shm_open(sys::SHM_ANON, oflag, 0, shm_flag, name)) {
	case let fd: int =>
		return fd: io::file;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};
