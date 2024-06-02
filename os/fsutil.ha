// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Filesystem-related helper functions for common high-level operations.

use errors;
use io;
use path;

// Canonicalizes a path in this filesystem by resolving all symlinks and
// collapsing any "." or ".." path components. The return value is statically
// allocated and will be overwritten on subsequent calls.
export fn realpath(path: str) (str | errors::error) = {
	static let res = path::buffer { ... };
	path::set(&res)!;

	static let inbuf = path::buffer { ... };
	if (path::abs(path)) {
		path::set(&inbuf, path)!;
	} else {
		path::set(&inbuf, getcwd(), path)!;
	};

	const iter = path::iter(&inbuf);
	for (let item => path::nextiter(&iter)) {
		const item = path::push(&res, item)!;

		const link = match (readlink(item)) {
		case let link: str =>
			yield link;
		case errors::wrongtype =>
			continue;
		case let err: errors::error =>
			return err;
		};

		if (!path::abs(link)) {
			path::push(&res, "..", link)!;
		} else {
			path::set(&res, link)!;
		};
	};

	return path::string(&res);
};

// Returns true if a node exists at the given path, or false if not.
//
// Note that testing for file existence before using the file can often lead to
// race conditions. If possible, prefer to simply attempt to use the file (e.g.
// via "open"), and handle the resulting error should the file not exist.
export fn exists(path: str) bool = {
	match (access(path, amode::F_OK)) {
	case let b: bool =>
		return b;
	case (errors::noaccess | errors::noentry | errors::wrongtype) =>
		return false;
	case errors::error =>
		// Implementation error
		abort();
	};
};


// Moves a file. This will use [[rename]] if possible. Otherwise, falls back to
// copying the file to the destination, then removing the original.
//
// This function only supports moving regular files, other kinds of inodes will
// return [[errors::unsupported]].
export fn move(oldpath: str, newpath: str) (void | errors::error) = {
	match (rename(oldpath, newpath)) {
	case errors::xdev => void; // Use fallback
	case let err: errors::error =>
		return err;
	case void =>
		return;
	};

	const st = stat(oldpath)?;
	if (!io::isfile(st.mode)) {
		return errors::unsupported;
	};

	const old = open(oldpath)?;
	defer io::close(old)!;

	const new = match (create(newpath, st.mode)) {
	case let file: io::file =>
		yield file;
	case let err: errors::error =>
		return err;
	};
	defer io::close(new)!;

	match (io::copy(new, old)) {
	case let err: io::error =>
		unlink(newpath)?;

		// io::error only adds io::underread to errors::error, which
		// should not be possible under these conditions.
		return err as errors::error;
	case size => void;
	};

	unlink(oldpath)?;
};

// Removes a file or directory. The direcotry
export fn remove(path: str) (void | errors::error) = {
	match (unlink(path)) {
	case void => void;
	case errors::wrongtype =>
		return rmdir(path);
	case let err: errors::error =>
		return err;
	};
};

// Removes a directory, and anything in it.
export fn rmdirall(path: str) (void | errors::error) = {
	let buf = path::init(path)!;
	return rmdirall_path(&buf);
};

fn rmdirall_path(buf: *path::buffer) (void | errors::error) = {
	let it = iter(path::string(buf))?;
	defer finish(&it);
	for (let ent => next(&it)?) {
		path::push(buf, ent.name)!;

		if (io::isdir(ent.ftype)) {
			rmdirall_path(buf)?;
		} else {
			remove(path::string(buf))?;
		};

		path::pop(buf);
	};
	return rmdir(path::string(buf));
};

// Makes a directory, and all non-extant directories in its path.
export fn mkdirs(path: str, mode: io::mode) (void | errors::error) = {
	let parent = path::dirname(path);
	if (path != parent) {
		match (mkdirs(parent, mode)) {
		case (errors::exists | errors::wrongtype) => void;
		case void => void;
		case let err: errors::error =>
			return err;
		};
	};

	match (mkdir(path, mode)) {
	case (errors::exists | errors::wrongtype) => void;
	case void => void;
	case let err: errors::error =>
		return err;
	};
};
