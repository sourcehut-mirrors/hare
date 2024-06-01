// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Functions that manipulate inodes.

use errors;
use io;
use rt;
use time;
use unix;

// Changes the mode bits of a file relative to a directory file descriptor. Type
// bits are discarded.
export fn fchmodat(
	dirfd: io::file,
	path: str,
	mode: io::mode,
	flags: int,
) (void | errors::error) = {
	match (rt::fchmodat(dirfd, path, mode, flags)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Changes mode flags on a file or directory. Type bits are discared.
export fn chmod(path: str, mode: io::mode) (void | errors::error) = {
	return fchmodat(AT_FDCWD, path, mode, 0);
};

// Changes mode flags on a [[io::file]]. Type bits are discared.
export fn fchmod(fd: io::file, mode: io::mode) (void | errors::error) = {
	return fchmodat(fd, "", mode, AT_EMPTY_PATH);
};

// Changes the ownership of a file relative to a directory file descriptor.
export fn fchownat(
	dirfd: io::file,
	path: str,
	uid: unix::uid,
	gid: unix::gid,
	flags: int,
) (void | errors::error) = {
	match (rt::fchownat(dirfd, path, uid, gid, flags)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Changes ownership of a file.
export fn chown(
	path: str,
	uid: unix::uid,
	gid: unix::gid,
) (void | errors::error) = {
	return fchownat(AT_FDCWD, path, uid, gid, 0);
};

// Changes ownership of an [[io::file]].
export fn fchown(
	fd: io::file,
	uid: uint,
	gid: uint,
) (void | errors::error) = {
	return fchownat(fd, "", uid, gid, AT_EMPTY_PATH);
};

// Change the time values for the given file relative to a directory file
// descriptor. Provide void for atime or mtime to leave the respective timestamp
// unchanged.
export fn utimensat(
	dirfd: int,
	path: str,
	atime: (time::instant | void),
	mtime: (time::instant | void),
	flags: int,
) (void | errors::error) = {
	let utimes: [2]rt::timespec = [
		instant_to_timespec(atime),
		instant_to_timespec(mtime),
	];
	match (rt::utimensat(dirfd, path, &utimes, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Change the time values for the given file. Provide void for atime or mtime to
// leave the respective timestamp unchanged.
export fn chtimes(
	path: str,
	atime: (time::instant | void),
	mtime: (time::instant | void),
) (void | errors::error) = {
	return utimensat(AT_FDCWD, path, atime, mtime, 0);
};

// Change the time values for the given file descriptor. Provide void for atime
// or mtime to leave the respective timestamp unchanged.
export fn fchtimes(
	fd: io::file,
	atime: (time::instant | void),
	mtime: (time::instant | void),
) (void | errors::error) = {
	return utimensat(fd, "", atime, mtime, AT_EMPTY_PATH);
};

fn instant_to_timespec(time: (time::instant | void)) rt::timespec = {
	match (time) {
	case let t: time::instant =>
		return time::instant_to_timespec(t);
	case void =>
		return rt::timespec {
			tv_sec = rt::UTIME_OMIT,
			tv_nsec = rt::UTIME_OMIT
		};
	};
};
