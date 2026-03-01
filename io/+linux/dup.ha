// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// Flags for [[dup]] and [[dup2]] operations.
export type dupflag = enum {
	NONE = 0,

	// Causes [[dup]] and [[dup2]] not to set the CLOEXEC flag on the
	// duplicated file descriptor. By default, CLOEXEC is set.
	NOCLOEXEC = sys::FD_CLOEXEC,
};

// Duplicates a file descriptor.
export fn dup(old: file, flags: dupflag = dupflag::NONE) (file | error) = {
	flags ^= dupflag::NOCLOEXEC; // Invert CLOEXEC

	match (sys::dup(old)) {
	case let fd: int =>
		const fl = sys::fcntl(fd, sys::F_GETFD, 0)!;
		sys::fcntl(fd, sys::F_SETFD, fl | flags)!;
		return fd;
	case let e: sys::errno =>
		return errors::errno(e);
	};
};

// Duplicates a file descriptor and stores the new file at a specific file
// descriptor number. If the file indicated by "new" already refers to an open
// file, this file will be closed before the file descriptor is reused.
export fn dup2(
	old: file,
	new: file,
	flags: dupflag = dupflag::NONE,
) (file | error) = {
	let flags = flags: int;
	flags ^= sys::FD_CLOEXEC; // Invert CLOEXEC
	if (flags & sys::FD_CLOEXEC != 0) {
		// dup3 has different flags from dup
		flags &= ~sys::FD_CLOEXEC;
		flags |= sys::O_CLOEXEC;
	};

	match (sys::dup3(old, new, flags)) {
	case let fd: int =>
		return fd;
	case let e: sys::errno =>
		return errors::errno(e);
	};
};
