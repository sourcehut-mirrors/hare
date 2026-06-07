// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use sys;
use types::c;
use io;

export type setxattr_flag = enum int {
	NONE = 0,
	XATTR_CREATE = 0x1,
	XATTR_REPLACE = 0x2,
};

@init fn init_cwd() void = {
	static let cwd_fs = os_filesystem { ... };
	cwd = static_dirfdopen(sys::AT_FDCWD, &cwd_fs);
};

// Returns the current working directory. The return value is statically
// allocated and must be duplicated (see [[strings::dup]]) before calling getcwd
// again.
export fn getcwd() str = c::tostr(sys::getcwd() as *const u8: *const c::char)!;

// Change the current working directory.
export fn chdir(target: (*fs::fs | str)) (void | fs::error) = {
	const path: str = match (target) {
	case let fs: *fs::fs =>
		assert(fs.open == &fs_open);
		let fs = fs: *os_filesystem;
		match (sys::fchdir(fs.dirfd)) {
		case let err: sys::errno =>
			return errno_to_fs(err);
		case void =>
			return;
		};
	case let s: str =>
		yield s;
	};
	match (sys::chdir(path)) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Changes the root directory of the process. Generally requires the caller to
// have root or otherwise elevated permissions.
//
// This function is not appropriate for sandboxing.
export fn chroot(target: str) (void | fs::error) = {
	match (sys::chroot(target)) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a FIFO node. This function is only available on Unix systems.
export fn mkfifo(path: str, mode: fs::mode) (void | fs::error) = {
	match (sys::mknodat(sys::AT_FDCWD, path,
			mode: sys::mode_t | sys::S_IFIFO, 0)) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a block device node. This function is only available on Unix-like
// systems.
export fn mkblk(
	path: str,
	mode: fs::mode,
	major: uint,
	minor: uint,
) (void | fs::error) = {
	match (sys::mknodat(sys::AT_FDCWD, path,
			mode: sys::mode_t | sys::S_IFBLK,
			sys::mkdev(major: u32, minor: u32))) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a character device node. This function is only available on Unix-like
// systems.
export fn mkchr(
	path: str,
	mode: fs::mode,
	major: uint,
	minor: uint,
) (void | fs::error) = {
	match (sys::mknodat(sys::AT_FDCWD, path, mode: sys::mode_t | sys::S_IFCHR,
			sys::mkdev(major: u32, minor: u32))) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

// Makes a regular file. This function is only available on Unix-like systems.
// This function should only be used if you have a special reason; most of the
// time you should use [[create]] instead.
export fn mkfile(path: str, mode: fs::mode) (void | fs::error) = {
	match (sys::mknodat(sys::AT_FDCWD, path,
			mode: sys::mode_t | sys::S_IFREG, 0)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Access modes for [[access]].
export type amode = enum int {
	F_OK = sys::F_OK,
	R_OK = sys::R_OK,
	W_OK = sys::W_OK,
	X_OK = sys::X_OK,
};

// Returns true if the given mode of access is permissible. The use of this
// function is discouraged as it can allow for a race condition to occur betwen
// testing for the desired access mode and actually using the file should the
// permissions of the file change between these operations. It is recommended
// instead to attempt to use the file directly and to handle any errors that
// should occur at that time.
export fn access(path: str, mode: amode) (bool | fs::error) = {
	match (sys::access(path, mode)) {
	case let b: bool =>
		return b;
	case let err: sys::errno =>
		return errno_to_fs(err);
	};
};

// Sets an extended file attribute.
export fn setxattr(
	path: str,
	name: str,
	value: []u8,
	flags: setxattr_flag = setxattr_flag::NONE,
) (void | fs::error) = {
	match (sys::setxattr(path, name, value, flags)) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case void =>
		return void;
	};
};

// Gets an extended file attribute.
// The caller is responsible for freeing the returned slice.
export fn getxattr(path: str, name: str) ([]u8 | fs::error) = {
	let empty: []u8 = [];
	let attr_size = match (sys::getxattr(path, name, empty)) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case let s: u64 =>
		yield s;
	};

	let buf: []u8 = alloc([0...], attr_size)!;
	match (sys::getxattr(path, name, buf)) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case let s: u64 =>
		return buf;
	};
};

// Removes an extended file attribute.
export fn removexattr(path: str, name: str) (void | fs::error) = {
	match (sys::removexattr(path, name)) {
	case let err: sys::errno =>
		return errno_to_fs(err);
	case void =>
		return void;
	};
};

export type fsblkcnt = sys::fsblkcnt_t;
export type fsfilcnt = sys::fsfilcnt_t;

export type vfsstat = struct {
	_: u64,
	bsize: u64,
	blocks: fsblkcnt,
	bfree: fsblkcnt,
	bavail: fsblkcnt,
	files: fsfilcnt,
	ffree: fsfilcnt,
	fsid: u64,
	namemax: u64,
	frsize: u64,
	flag: u64,
	favail: fsfilcnt,
	_: [3]u64,
};

// Queries file system information mounted at the given path.
//
// The returned value is statically allocated and will be overwritten on
// subsequent calls.
export fn statvfs(path: str) (vfsstat | sys::errno) = {
	static let buf = sys::fsstat { ... };
	sys::statfs(path, &buf)?;
	if (buf.frsize == 0)
		buf.frsize = buf.bsize;
	return *(&buf: *vfsstat);
};

// Like [[statvfs]], but accepts a file descriptor.
//
// The returned value is statically allocated and will be overwritten on
// subsequent calls.
export fn fstatvfs(fd: io::file) (vfsstat | sys::errno) = {
	static let buf = sys::fsstat { ... };
	sys::fstatfs(fd, &buf)?;
	if (buf.frsize == 0)
		buf.frsize = buf.bsize;
	return *(&buf: *vfsstat);
};

@test fn vfsstat() void = {
	assert(size(vfsstat) == size(sys::fsstat));
};
