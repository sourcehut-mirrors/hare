// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use errors;
use fs;
use io;
use path;
use rt;
use strings;
use time;
use types::c;

@init fn init_cwd() void = {
	static let cwd_fs = os_filesystem { ... };
	cwd = static_dirfdopen(rt::AT_FDCWD, &cwd_fs);
};

// Controls how symlinks are followed (or not) in a dirfd filesystem. Support
// for this feature varies, you should gate usage of this enum behind a build
// tag.
//
// Note that on Linux, specifying BENEATH or IN_ROOT will also disable magic
// symlinks.
export type resolve_flag = enum u64 {
	NORMAL = 0,

	// Does not allow symlink resolution to occur for any symlinks which
	// would refer to any anscestor of the fd directory. This disables all
	// absolute symlinks, and any call to open or create with an absolute
	// path.
	BENEATH = rt::RESOLVE_BENEATH | rt::RESOLVE_NO_MAGICLINKS,

	// Treat the directory fd as the root directory. This affects
	// open/create for absolute paths, as well as absolute path resolution
	// of symlinks. The effects are similar to chroot.
	IN_ROOT = rt::RESOLVE_IN_ROOT | rt::RESOLVE_NO_MAGICLINKS,

	// Disables symlink resolution entirely.
	NO_SYMLINKS = rt::RESOLVE_NO_SYMLINKS,

	// Disallows traversal of mountpoints during path resolution. This is
	// not recommended for general use, as bind mounts are extensively used
	// on many systems.
	NO_XDEV = rt::RESOLVE_NO_XDEV,
};

type os_filesystem = struct {
	fs: fs::fs,
	dirfd: int,
	resolve: resolve_flag,
	getdents_bufsz: size,
};

// Opens a file descriptor as an [[fs::fs]]. This file descriptor must be a
// directory file. The file will be closed when the fs is closed.
export fn dirfdopen(
	fd: io::file,
	resolve_flags: resolve_flag = resolve_flag::NORMAL,
) *fs::fs = {
	let ofs = alloc(os_filesystem { resolve = resolve_flags, ... });
	let fs = static_dirfdopen(fd, ofs);
	fs.close = &fs_close;
	return fs;
};

fn static_dirfdopen(fd: io::file, filesystem: *os_filesystem) *fs::fs = {
	*filesystem = os_filesystem {
		fs = fs::fs {
			mkdir = &fs_mkdir,
			...
		},
		dirfd = fd,
		getdents_bufsz = 32768, // 32 KiB
		...
	};
	return &filesystem.fs;
};

// Clones a dirfd filesystem, optionally adding additional [[resolve_flag]]
// constraints.
export fn dirfs_clone(
	fs: *fs::fs,
	resolve_flags: resolve_flag = resolve_flag::NORMAL,
) *fs::fs = {
	let fs = fs: *os_filesystem;
	let new = alloc(*fs);
	fs.resolve |= resolve_flags;
	new.dirfd = rt::fcntl(new.dirfd, rt::F_DUPFD_CLOEXEC, 0) as int;
	return &new.fs;
};

// Sets the buffer size to use with the getdents(2) system call, for use with
// [[fs::iter]]. A larger buffer requires a larger runtime allocation, but can
// scan large directories faster. The default buffer size is 32 KiB.
//
// This function is not portable.
export fn dirfdfs_set_getdents_bufsz(fs: *fs::fs, sz: size) void = {
	let fs = fs: *os_filesystem;
	fs.getdents_bufsz = sz;
};

// Returns an [[io::file]] for this filesystem. This function is not portable.
export fn dirfile(fs: *fs::fs) io::file = {
	let fs = fs: *os_filesystem;
	return fs.dirfd;
};

fn errno_to_fs(err: rt::errno) fs::error = {
	switch (err) {
	case rt::ENOENT =>
		return errors::noentry;
	case rt::EEXIST =>
		return errors::exists;
	case rt::EACCES =>
		return errors::noaccess;
	case rt::EBUSY =>
		return errors::busy;
	case rt::ENOTDIR =>
		return fs::wrongtype;
	case rt::EOPNOTSUPP, rt::ENOSYS =>
		return errors::unsupported;
	case rt::EXDEV =>
		return fs::cannotrename;
	case =>
		return errors::errno(err);
	};
};

fn fs_mkdir(fs: *fs::fs, path: str, mode: io::mode) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	match (rt::mkdirat(fs.dirfd, path, mode: uint)) {
	case let err: rt::errno =>
		return errno_to_fs(err);
	case void => void;
	};
};

fn fs_close(fs: *fs::fs) void = {
	let fs = fs: *os_filesystem;
	rt::close(fs.dirfd)!;
	free(fs);
};
