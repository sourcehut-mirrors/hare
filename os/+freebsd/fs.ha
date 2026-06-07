// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fs;
use sys;
use types::c;
use io;

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

export type fsblkcnt = u64;
export type fsfilcnt = u64;

export type vfsstat = struct {
	_: [4]u64,
	blocks: fsblkcnt,
	bfree: fsblkcnt,
	bavail: fsblkcnt,
	files: fsfilcnt,
	ffree: fsfilcnt,
	_: [4+10+1]u64,
	fsid: u64,
	_: [10+2+128*2-5]u64,
	favail: fsfilcnt,
	bsize: u64,
	frsize: u64,
	flag: u64,
	namemax: u64,
};

// Queries file system information mounted at the given path.
//
// The returned value is statically allocated and will be overwritten on
// subsequent calls.
export fn statvfs(path: str) (vfsstat | sys::errno) = {
	static let buf = sys::fsstat { ... };
	sys::statfs(path, &buf)?;
	let vfs = *(&buf: *vfsstat);
	if (buf.flags & sys::ST_RDONLY > 0) {
		vfs.flag |= sys::ST_RDONLY;
	};
	if (buf.flags & sys::ST_NOSUID > 0) {
		vfs.flag |= sys::ST_NOSUID;
	};
	vfs.favail = vfs.ffree;
	vfs.bsize = buf.iosize;
	vfs.frsize = buf.bsize;
	vfs.namemax = match(sys::pathconf(path, sys::PC_NAME_MAX)) {
	case sys::errno =>
		yield ~0u64;
	case let pcval: int =>
		yield pcval: u64;
	};
	return vfs;
};

// Like [[statvfs]], but accepts a file descriptor.
//
// The returned value is statically allocated and will be overwritten on
// subsequent calls.
export fn fstatvfs(fd: io::file) (vfsstat | sys::errno) = {
	static let buf = sys::fsstat { ... };
	sys::fstatfs(fd, &buf)?;
	let vfs = *(&buf: *vfsstat);
	if (buf.flags & sys::ST_RDONLY > 0) {
		vfs.flag |= sys::ST_RDONLY;
	};
	if (buf.flags & sys::ST_NOSUID > 0) {
		vfs.flag |= sys::ST_NOSUID;
	};
	vfs.favail = vfs.ffree;
	vfs.bsize = buf.iosize;
	vfs.frsize = buf.bsize;
	vfs.namemax = match(sys::fpathconf(fd, sys::PC_NAME_MAX)) {
	case sys::errno =>
		yield ~0u64;
	case let pcval: int =>
		yield pcval: u64;
	};
	return *(&buf: *vfsstat);
};

@test fn vfsstat() void = {
	assert(size(vfsstat) == size(sys::fsstat));
};

// TODO: FreeBSD
// export fn mkfifo(path: str, mode: fs::mode) (void | fs::error) = {
// export fn mkblk(
// export fn mkchr(
// export fn mkfile(
