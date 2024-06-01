// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Functions for managing hard links and symbolic links and related
// functionality.

use errors;
use rt;
use strings;
use io;

// Reads the contents of a symbolic link relative to a directory file
// descriptor. The return value is statically allocated and will be overwritten
// on the next call to [[readlink]] or [[readlinkat]].
export fn readlinkat(dirfd: io::file, path: str) (str | errors::error) = {
	static let buf: [rt::PATH_MAX]u8 = [0...];
	let z = match (rt::readlinkat(dirfd, path, buf[..])) {
	case let err: rt::errno =>
		switch (err) {
		case rt::EINVAL =>
			return errors::wrongtype;
		case =>
			return errors::errno(err);
		};
	case let z: size =>
		yield z;
	};
	return strings::fromutf8(buf[..z])!;
};

// Reads the contents of a symbolic link. The return value is statically
// allocated and will be overwritten on the next call to [[readlink]] or
// [[readlinkat]].
export fn readlink(path: str) (str | errors::error) = {
	return readlinkat(AT_FDCWD, path);
};

// Creates a hard link from an old path to a new path, relative to their
// respective directory file descriptors.
export fn linkat(
	old_dirfd: io::file,
	old_path: str,
	new_dirfd: io::file,
	new_path: str,
	flags: int,
) (void | errors::error) = {
	match (rt::linkat(old_dirfd, old_path, new_dirfd, new_path, flags)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Creates a new (hard) link at 'new' for the file at 'old'.
export fn link(old: str, new: str) (void | errors::error) = {
	return linkat(AT_FDCWD, old, AT_FDCWD, new, 0);
};

// Removes a file name from the filesystem relative to a directory file
// descriptor.
export fn unlinkat(
	dirfd: io::file,
	path: str,
	flags: int,
) (void | errors::error) = {
	match (rt::unlinkat(dirfd, path, flags)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Removes a file name from the filesystem.
export fn unlink(path: str) (void | errors::error) = {
	return unlinkat(AT_FDCWD, path, 0);
};

// Creates a new symbolic link from "path" (relative to a directory file
// descriptor) to "target" (relative to the link).
export fn symlinkat(
	target: str,
	dirfd: io::file,
	path: str,
) (void | errors::error) = {
	match (rt::symlinkat(target, dirfd, path)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Creates a new symbolic link from "path" to "target".
export fn symlink(target: str, path: str) (void | errors::error) = {
	return symlinkat(target, AT_FDCWD, path);
};

// Moves a node on the filesystem from one path to another, relative to two
// respective directory file descriptors.
//
// Note that this will not move a node from one underlying filesystem to
// another; [[renameat]] returns [[errors::xdev]] in this case. See [[move]] for
// a high-level API that falls back to a file copy in this situation.
export fn renameat(
	old_dirfd: io::file,
	old_path: str,
	new_dirfd: io::file,
	new_path: str,
) (void | errors::error) = {
	match (rt::renameat(old_dirfd, old_path, new_dirfd, new_path, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Moves a node on the filesystem from one path to another.
//
// Note that this will not move a node from one underlying filesystem to
// another; [[rename]] returns [[errors::xdev]] in this case. See [[move]] for a
// high-level API that falls back to a file copy in this situation.
export fn rename(old: str, new: str) (void | errors::error) = {
	return renameat(AT_FDCWD, old, AT_FDCWD, new);
};
