// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;
use time;
use unix;

// Information about a file or directory.
export type filestat = struct {
	inode: u64,
	mode: io::mode,
	uid: unix::uid,
	gid: unix::gid,
	dev: u64,
	rdev: u64,
	sz: size,
	atime: time::instant,
	mtime: time::instant,
	ctime: time::instant,
};

// Obtains file information for a given path or file descriptor.
//
// If flags includes [[AT_EMPTY_PATH]], this operation is similar to [[fstat]]
// and returns information about the file referred to by the first argument.
// Otherwise, the first argument must be a directory file descriptor and the
// path argument is used to look up a file whose status shall be interrogated.
export fn fstatat(
	dirfd: io::file,
	path: str,
	flags: int,
) (filestat | errors::error) = {
	let st = rt::st { ... };
	match (rt::fstatat(dirfd, path, &st, flags)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
	return st_to_filestat(&st);
};

// Returns file information for a given path. If the path refers to a symbolic
// link, [[stat]] returns status information about the link target.
export fn stat(path: str) (filestat | errors::error) = {
	return fstatat(AT_FDCWD, path, 0);
};

// Returns file information for a given path. If the path refers to a symbolic
// link, [[lstat]] returns status information about the link itself.
export fn lstat(path: str) (filestat | errors::error) = {
	return fstatat(AT_FDCWD, path, AT_SYMLINK_NOFOLLOW);
};

// Returns file information for an [[io::file]].
export fn fstat(fd: io::file) (filestat | errors::error) = {
	return fstatat(fd, "", AT_EMPTY_PATH);
};

fn st_to_filestat(st: *rt::st) filestat = {
	return filestat {
		inode = st.ino,
		mode = st.mode: io::mode,
		uid = st.uid,
		gid = st.gid,
		dev = st.dev,
		rdev = st.rdev,
		sz = st.sz: size,
		atime = time::instant {
			sec = st.atime.tv_sec,
			nsec = st.atime.tv_nsec,
		},
		mtime = time::instant {
			sec = st.mtime.tv_sec,
			nsec = st.mtime.tv_nsec,
		},
		ctime = time::instant {
			sec = st.ctime.tv_sec,
			nsec = st.ctime.tv_nsec,
		},
	};
};
