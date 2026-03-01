// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;

// Flags for [[memfd]].
export type memfd_flag = enum uint {
	NONE = 0,
	// Unsets the close-on-exec flag when creating a memfd.
	NOCLOEXEC = sys::MFD_CLOEXEC,
	// Allows sealing operations on this file.
	ALLOW_SEALING = sys::MFD_ALLOW_SEALING,
	// Create the memfd with huge pages using hugetlbfs. Linux-only.
	HUGETLB = sys::MFD_HUGETLB,
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
	flags ^= memfd_flag::NOCLOEXEC;
	match (sys::memfd_create(name, flags: uint)) {
	case let i: int =>
		return i: io::file;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};
