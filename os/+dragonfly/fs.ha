// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fs;
use sys;
use types::c;

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

export type vfsstat = struct {
	bsize: u64,
	frsize: u64,
	blocks: fsblkcnt_t,
	bfree: fsblkcnt_t,
	bavail: fsblkcnt_t,
	files: fsfilcnt_t,
	ffree: fsfilcnt_t,
	favail: fsfilcnt_t,
	fsid: u64,
	flag: u64,
	namemax: u64,
	_: [5]u64,
	_: [32]u8,
};

// Queries file system information mounted at the given path.
//
// The returned value is statically allocated and will be overwritten on
// subsequent calls.
export fn statvfs(path: str) (vfsstat | sys::errno) = {
	static let buf = sys::vfsstat { ... };
	sys::statvfs(path, &buf)?;
	return *(&buf: *vfsstat);
};

// Like [[statvfs]], but accepts a file descriptor.
//
// The returned value is statically allocated and will be overwritten on
// subsequent calls.
export fn fstatvfs(fd: io::file) (vfsstat | sys::errno) = {
	static let buf = sys::vfsstat { ... };
	sys::fstatvfs(fd, &buf)?;
	return *(&buf: *vfsstat);
};

@test fn vfsstat() void = {
	assert(size(vfsstat) == size(sys::vfsstat));
};

// TODO: DragonFly
// export fn mkfifo(path: str, mode: fs::mode) (void | fs::error) = {
// export fn mkblk(
// export fn mkchr(
// export fn mkfile(
