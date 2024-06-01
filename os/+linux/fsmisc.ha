// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;
use types::c;

// Returns the current working directory. The return value is statically
// allocated and must be duplicated (see [[strings::dup]]) before calling getcwd
// again.
export fn getcwd() str = {
	return c::tostr(rt::getcwd()!: *const c::char)!;
};

// Change the current working directory to the directory reprensented by the
// given file descriptor.
export fn fchdir(dirfd: io::file) (void | errors::error) = {
	match (rt::fchdir(dirfd)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Change the current working directory.
export fn chdir(path: str) (void | errors::error) = {
	match (rt::chdir(path)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Changes the root directory of the process. Generally requires the caller to
// have root or otherwise elevated permissions.
//
// This function is not appropriate for sandboxing.
export fn chroot(target: str) (void | errors::error) = {
	match (rt::chroot(target)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Returns true if a node exists at the given path, or false if not.
//
// Note that testing for file existence before using the file can often lead to
// race conditions. If possible, prefer to simply attempt to use the file (e.g.
// via "open"), and handle the resulting error should the file not exist.
export fn exists(path: str) bool = {
	match (rt::access(path, rt::F_OK)) {
	case let b: bool =>
		return b;
	case let err: rt::errno =>
		switch (err) {
		case rt::EACCES, rt::ENOENT, rt::ENOTDIR =>
			return false;
		case =>
			// Implementation error
			abort();
		};
	};
};

// Access modes for [[access]].
export type amode = enum int {
	F_OK = rt::F_OK,
	R_OK = rt::R_OK,
	W_OK = rt::W_OK,
	X_OK = rt::X_OK,
};

// Returns true if the given mode of access is permissible. The use of this
// function is discouraged as it can allow for a race condition to occur betwen
// testing for the desired access mode and actually using the file should the
// permissions of the file change between these operations. It is recommended
// instead to attempt to use the file directly and to handle any errors that
// should occur at that time.
export fn access(path: str, mode: amode) (bool | errors::error) = {
	match (rt::access(path, mode)) {
	case let b: bool =>
		return b;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Makes a FIFO node. This function is only available on Unix systems.
export fn mkfifo(path: str, mode: io::mode) (void | errors::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path,
			mode: rt::mode_t | rt::S_IFIFO, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Makes a block device node. This function is only available on Unix-like
// systems.
export fn mkblk(
	path: str,
	mode: io::mode,
	major: uint,
	minor: uint,
) (void | errors::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path,
			mode: rt::mode_t | rt::S_IFBLK,
			rt::mkdev(major: u32, minor: u32))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Makes a character device node. This function is only available on Unix-like
// systems.
export fn mkchr(
	path: str,
	mode: io::mode,
	major: uint,
	minor: uint,
) (void | errors::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path, mode: rt::mode_t | rt::S_IFCHR,
			rt::mkdev(major: u32, minor: u32))) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Makes a regular file. This function is only available on Unix-like systems.
// This function should only be used if you have a special reason; most of the
// time you should use [[create]] instead.
export fn mkfile(path: str, mode: io::mode) (void | errors::error) = {
	match (rt::mknodat(rt::AT_FDCWD, path,
			mode: rt::mode_t | rt::S_IFREG, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};
