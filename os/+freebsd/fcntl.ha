// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;

// Opens a file relative to a directory file descriptor.
//
// The mode argument is only used if [[io::flag::CREATE]] is specified in flags.
export fn openat(
	dirfd: io::file,
	path: str,
	flags: io::flag,
	mode: io::mode = 0,
) (io::file | errors::error) = {
	flags ^= io::flag::CTTY | io::flag::NOCLOEXEC; // invert NOCTTY/CLOEXEC

	if ((flags & io::flag::DIRECTORY) == io::flag::DIRECTORY) {
		// This is arch-specific
		flags &= ~io::flag::DIRECTORY;
		flags |= rt::O_DIRECTORY: io::flag;
	};

	match (rt::openat(dirfd, path, flags, mode)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let fd: int =>
		return fd;
	};
};

// Opens a file.
//
// It is a programming error to use io::flag::CREATE to this function; see
// [[create]] instead.
export fn open(
	path: str,
	flags: io::flag = io::flag::RDONLY,
) (io::file | errors::error) = {
	assert(flags & io::flag::CREATE == 0,
		"os::open used with io::flag::CREATE; use os::create instead");
	return openat(AT_FDCWD, path, flags);
};

// Creates a new file with the given mode if it doesn't already exist and opens
// it for writing.
//
// Only the permission bits of the mode are used. If other bits are set, they
// are discarded.
//
// To create a file without opening it, see [[mkfile]].
export fn create(
	path: str,
	mode: io::mode,
	flags: io::flag = io::flag::WRONLY | io::flag::TRUNC,
) (io::file | errors::error) = {
	return openat(AT_FDCWD, path, flags | io::flag::CREATE, mode);
};
