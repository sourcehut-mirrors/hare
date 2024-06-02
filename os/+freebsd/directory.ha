// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;
use strings;
use types::c;

// Makes a new directory at a path relative to a directory file descriptor.
export fn mkdirat(
	dirfd: io::file,
	path: str,
	mode: io::mode,
) (void | errors::error) = {
	match (rt::mkdirat(dirfd, path, mode: uint)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Makes a directory.
export fn mkdir(path: str, mode: io::mode) (void | errors::error) = {
	return mkdirat(AT_FDCWD, path, mode);
};

def GETDENTS_BUFSZ: size = 32768;

// An entry in a directory.
export type dirent = struct {
	// The name of this entry. Not fully qualified: for example,
	// "foo/bar/baz.txt" would store "baz.txt" here.
	name: str,

	// The type of this entry. The permission bits may be unset.
	ftype: io::mode,
};

// Duplicates a [[dirent]] object. Call [[dirent_finish]] to free resources
// associated with the dirent.
export fn dirent_dup(e: *dirent) dirent = {
	let new = *e;
	new.name = strings::dup(e.name);
	return new;
};

// Frees resources associated with a [[dirent]].
export fn dirent_finish(e: *dirent) void = {
	free(e.name);
};

export type iterator = struct {
	dirfd: int,
	buf_pos: size,
	buf_end: size,
	buf: []u8,
};

// Returns an iterator for a path which yields the contents of a directory.
// The order in which entries are returned is undefined. The return value must
// be finished with [[finish]].
export fn iter(path: str) (iterator | errors::error) = {
	const dirfd = open(path, io::flag::RDONLY | io::flag::DIRECTORY)?;
	return iterator {
		dirfd = dirfd,
		buf = alloc([0...], GETDENTS_BUFSZ),
		...
	};
};

// Returns the next directory entry from an [[iterator]]. The return value is
// borrowed from the iterator and is invalidated on the next call to [[next]].
export fn next(iter: *iterator) (dirent | done | errors::error) = {
	if (iter.buf_pos >= iter.buf_end) {
		let n = match (rt::getdents(iter.dirfd,
			iter.buf: *[*]u8, len(iter.buf))) {
		case let err: rt::errno =>
			return errors::errno(err);
		case let n: size =>
			yield n;
		};
		if (n == 0) {
			return done;
		};
		iter.buf_end = n;
		iter.buf_pos = 0;
	};

	let de = &iter.buf[iter.buf_pos]: *rt::freebsd11_dirent;
	iter.buf_pos += de.d_reclen;
	let name = c::tostr(&de.d_name: *const c::char)!;
	if (name == "." || name == "..") {
		return next(iter);
	};

	const ftype = switch (de.d_type) {
	case rt::DT_UNKNOWN =>
		yield io::mode::UNKNOWN;
	case rt::DT_FIFO =>
		yield io::mode::FIFO;
	case rt::DT_CHR =>
		yield io::mode::CHR;
	case rt::DT_DIR =>
		yield io::mode::DIR;
	case rt::DT_BLK =>
		yield io::mode::BLK;
	case rt::DT_REG =>
		yield io::mode::REG;
	case rt::DT_LNK =>
		yield io::mode::LINK;
	case rt::DT_SOCK =>
		yield io::mode::SOCK;
	case =>
		yield io::mode::UNKNOWN;
	};

	return dirent {
		name = name,
		ftype = ftype,
	};
};

// Frees resources associated with an [[iterator]].
export fn finish(iter: *iterator) void = {
	io::close(iter.dirfd)!;
	free(iter.buf);
};
