// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use path;
use rt;
use rerr = rt::errors;
use rfs = rt::fs;
use strings;

type os_filesystem = struct {
	fs: fs::fs,
	cap: rt::cap,
};

export fn init_cwd() void = {
	static let cwd_fs = os_filesystem { cap = ~0, ... };
	cwd = static_dirfdopen(rt::service(rfs::FS_ID), &cwd_fs);
};

@init fn init() void = {
	init_cwd();
};

let _cwd: str = "";

@init fn init_cwd() void = {
	_cwd = rt::init_cwd;
};

// Returns the current working directory. The return value is statically
// allocated and must be duplicated (see [[strings::dup]]) before calling getcwd
// again.
export fn getcwd() str = {
	return _cwd;
};

// Change the current working directory.
export fn chdir(target: (*fs::fs | str)) (void | fs::error) = {
	const path = match (target) {
	case *fs::fs =>
		return errors::unsupported;
	case let path: str =>
		yield path;
	};

	if (_cwd != rt::init_cwd) {
		free(_cwd);
	};
	let path = path::init(path)!;
	if (!path::abs(&path)) {
		path::popprefix(&path, ".")!;
		path::prepend(&path, _cwd)!;
	};
	_cwd = strings::dup(path::string(&path));
};

// A directory entry in the IPC format.
type ipc_dirent = struct {
	mode: fs::mode,
	nameln: size,
	name: [*]u8,
};

// Size of an [[ipc_dirent]] without the name.
def DIRENT_SIZE: size = size(struct {
	mode: uint,
	nameln: size,
});

// Opens a capability as an [[fs::fs]].
export fn dirfdopen(fd: io::file) *fs::fs = {
	let ofs = alloc(os_filesystem { ... });
	return static_dirfdopen(fd, ofs);
};

fn static_dirfdopen(fd: io::file, filesystem: *os_filesystem) *fs::fs = {
	*filesystem = os_filesystem {
		fs = fs::fs {
			open = &fs_open,
			openfile = &fs_open_file,
			create = &fs_create,
			createfile = &fs_create_file,
			remove = &fs_remove,
			rename = &fs_rename,
			iter = &fs_iter,
			stat = &fs_stat,
			readlink = &fs_readlink,
			mkdir = &fs_mkdir,
			rmdir = &fs_rmdir,
			chmod = &fs_chmod,
			chown = &fs_chown,
			resolve = &fs_resolve,
			link = &fs_link,
			symlink = &fs_symlink,
			...
		},
		cap = fd,
		...
	};
	return &filesystem.fs;
};

// Returns an [[io::file]] for this filesystem. This function is not portable.
export fn dirfile(fs: *fs::fs) io::file = {
	assert(fs.open == &fs_open);
	let fs = fs: *os_filesystem;
	return fs.cap;
};

// Prepares an I/O pool buffer with the provided path.
fn mkpath(path: str) (rt::cap, uintptr, size) = {
	let path = path::init(path)!;
	if (!path::abs(&path)) {
		path::popprefix(&path, ".")!;
		path::prepend(&path, _cwd)!;
	};

	const path = path::string(&path);
	const n = len(path);
	const data = strings::toutf8(path);
	const (page, base) = rt::pool_acquire();

	assert(n <= rt::PAGESIZE);
	let buf = (base: *[*]u8)[..len(data)];
	buf[..] = data[..n];
	return (page, base, n);
};

def FLAGS_COMPAT: int =
	fs::flag::RDONLY |
	fs::flag::WRONLY |
	fs::flag::RDWR |
	fs::flag::CREATE |
	fs::flag::TRUNC |
	fs::flag::APPEND |
	fs::flag::DIRECTORY |
	fs::flag::NOFOLLOW;

fn fs_open_file(
	fs: *fs::fs,
	path: str,
	flags: fs::flag...
) (io::file | fs::error) = {
	let fs = fs: *os_filesystem;
	let oflags = fs::flag::RDONLY;
	for (let i = 0z; i < len(flags); i += 1) {
		oflags |= flags[i];
	};
	if (oflags & ~FLAGS_COMPAT != 0) {
		return errors::unsupported: fs::error;
	};

	const (page, base, n) = mkpath(path);
	defer rt::pool_release(base);

	let file: rt::cap = 0;
	const r = rfs::fs_open(fs.cap, [page], base,
		n, oflags: rfs::flags, 0, &file);
	match (r) {
	case rerr::noentry =>
		return errors::noentry;
	case rerr::wrongtype =>
		return fs::wrongtype;
	case rerr::noaccess =>
		return errors::noaccess;
	case rerr::rofs =>
		return errors::rofs;
	case void =>
		return file: io::file;
	};
};

fn fs_open(
	fs: *fs::fs,
	path: str,
	flags: fs::flag...
) (io::handle | fs::error) = fs_open_file(fs, path, flags...)?: io::handle;

fn fs_create_file(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flag...
) (io::file | fs::error) = {
	let fs = fs: *os_filesystem;
	let oflags = 0;
	if (len(flags) == 0) {
		oflags |= fs::flag::WRONLY | fs::flag::TRUNC;
	};
	for (let i = 0z; i < len(flags); i += 1z) {
		oflags |= flags[i]: int;
	};
	oflags |= fs::flag::CREATE: int;

	if (oflags & FLAGS_COMPAT != 0) {
		return errors::unsupported: fs::error;
	};

	const (page, base, n) = mkpath(path);
	defer rt::pool_release(base);

	let file: rt::cap = 0;
	const r = rfs::fs_open(fs.cap, [page], base,
		n, oflags: rfs::flags, mode, &file);
	match (r) {
	case rerr::noentry =>
		return errors::noentry;
	case rerr::wrongtype =>
		return fs::wrongtype;
	case rerr::noaccess =>
		return errors::noaccess;
	case rerr::rofs =>
		return errors::rofs;
	case void =>
		return file: io::file;
	};
};

fn fs_create(
	fs: *fs::fs,
	path: str,
	mode: fs::mode,
	flags: fs::flag...
) (io::handle | fs::error) = {
	return fs_create_file(fs, path, mode, flags...)?: io::handle;
};

fn fs_remove(fs: *fs::fs, path: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;
	const (page, base, n) = mkpath(path);
	defer rt::pool_release(base);

	match (rfs::fs_remove(fs.cap, [page], base, n)) {
	case rerr::noentry =>
		return errors::noentry;
	case rerr::wrongtype =>
		return fs::wrongtype;
	case rerr::rofs =>
		return errors::rofs;
	case void =>
		return;
	};
};

fn fs_rename(fs: *fs::fs, oldpath: str, newpath: str) (void | fs::error) = {
	let fs = fs: *os_filesystem;

	const (page, base, n) = mkpath(oldpath);
	defer rt::pool_release(base);

	let nbuf = base: *[*]u8;
	let nbuf = nbuf[n..n+len(newpath)];
	nbuf[..] = strings::toutf8(newpath);

	match (rfs::fs_rename(fs.cap, [page],
			base, len(oldpath),
			base + len(oldpath), len(newpath))) {
	case rerr::noentry =>
		return errors::noentry;
	case rerr::rofs =>
		return errors::rofs;
	case void =>
		return;
	};
};

fn fs_stat(fs: *fs::fs, path: str) (fs::filestat | fs::error) = {
	let fs = fs: *os_filesystem;

	const (page, base, n) = mkpath(path);
	defer rt::pool_release(base);
	const stat = base + n;
	match (rfs::fs_stat(fs.cap, [page], base, n, stat)) {
	case rerr::noentry =>
		return errors::noentry;
	case rerr::rofs =>
		return errors::rofs;
	case void =>
		// fs::filestat is compatible with Gaia's IPC representation
		return *(stat: *fs::filestat);
	};
};

fn fs_readlink(fs: *fs::fs, path: str) (str | fs::error) = {
	return errors::unsupported; // TODO
};

fn fs_rmdir(fs: *fs::fs, path: str) (void | fs::error) = {
	return errors::unsupported; // TODO
};

fn fs_mkdir(fs: *fs::fs, path: str, mode: fs::mode) (void | fs::error) = {
	let fs = fs: *os_filesystem;

	const (page, base, n) = mkpath(path);
	defer rt::pool_release(base);

	match (rfs::fs_mkdir(fs.cap, [page], base, n)) {
	case rerr::noentry =>
		return errors::noentry;
	case rerr::rofs =>
		return errors::rofs;
	case rerr::exists =>
		return errors::exists;
	case void =>
		return;
	};
};

fn fs_chmod(fs: *fs::fs, path: str, mode: fs::mode) (void | fs::error) = {
	return errors::unsupported; // TODO
};

fn fs_chown(fs: *fs::fs, path: str, uid: uint, gid: uint) (void | fs::error) = {
	return errors::unsupported; // TODO
};

fn fs_resolve(fs: *fs::fs, path: str) str = {
	if (path::abs(path)) {
		return path;
	};
	abort(); // TODO: Implement getcwd
};

fn fs_link(fs: *fs::fs, old: str, new: str) (void | fs::error) = {
	return errors::unsupported; // TODO
};

fn fs_symlink(fs: *fs::fs, target: str, path: str) (void | fs::error) = {
	return errors::unsupported; // TODO
};

type fs_iterator = struct {
	fs::iterator,
	dir: io::file,
	buf: [rt::PAGESIZE]u8,
	n: size,
	avail: size,
};

fn fs_iter(fs: *fs::fs, path: str) (*fs::iterator | fs::error) = {
	const dir = open(path, fs::flag::DIRECTORY)?;
	return alloc(fs_iterator {
		next = &fs_iter_next,
		finish = &fs_iter_finish,
		dir = dir,
		...
	});
};

fn fs_iter_next(iter: *fs::iterator) (fs::dirent | void) = {
	let iter = iter: *fs_iterator;
	if (iter.n >= iter.avail) {
		// XXX: Should we bubble up an I/O error here?
		const z = match (io::read(iter.dir, iter.buf)!) {
		case let z: size =>
			yield z;
		case io::EOF =>
			return;
		};
		iter.avail = z;
		iter.n = 0;
	};

	const dent = &iter.buf[iter.n]: *ipc_dirent;
	const name = strings::fromutf8(dent.name[..dent.nameln])!;
	iter.n += DIRENT_SIZE + dent.nameln;
	return fs::dirent {
		ftype = dent.mode,
		name = name,
	};
};

fn fs_iter_finish(iter: *fs::iterator) void = {
	let iter = iter: *fs_iterator;
	io::close(iter.dir)!;
	free(iter);
};
