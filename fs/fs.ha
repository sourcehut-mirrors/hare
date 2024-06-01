// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use path;
use time;

// Closes a filesystem. The fs cannot be used after this function is called.
export fn close(fs: *fs) void = {
	match (fs.close) {
	case null => void;
	case let f: *closefunc =>
		f(fs);
	};
};

// Removes a file.
export fn remove(fs: *fs, path: str) (void | error) = {
	match (fs.remove) {
	case null =>
		return errors::unsupported;
	case let f: *removefunc =>
		return f(fs, path);
	};
};

// Returns an iterator for a path, which yields the contents of a directory.
// Pass empty string to yield from the root. The order in which entries are
// returned is undefined. The return value must be finished with [[finish]].
export fn iter(fs: *fs, path: str) (*iterator | error) = {
	match (fs.iter) {
	case null =>
		return errors::unsupported;
	case let f: *iterfunc =>
		return f(fs, path);
	};
};

// Frees state associated with an [[iterator]].
export fn finish(iter: *iterator) void = {
	match (iter.finish) {
	case null => void;
	case let f: *finishfunc =>
		return f(iter);
	};
};

// Creates a directory.
export fn mkdir(fs: *fs, path: str, mode: io::mode) (void | error) = {
	match (fs.mkdir) {
	case null =>
		return errors::unsupported;
	case let f: *mkdirfunc =>
		return f(fs, path, mode);
	};
};

// Makes a directory, and all non-extant directories in its path.
export fn mkdirs(fs: *fs, path: str, mode: io::mode) (void | error) = {
	let parent = path::dirname(path);
	if (path != parent) {
		match (mkdirs(fs, parent, mode)) {
		case errors::exists => void;
		case void => void;
		case let err: error =>
			return err;
		};
	};
	match (mkdir(fs, path, mode)) {
	case errors::exists => void;
	case void => void;
	case let err: error =>
		return err;
	};
};

// Removes a directory. The target directory must be empty; see [[rmdirall]] to
// remove its contents as well.
export fn rmdir(fs: *fs, path: str) (void | error) = {
	if (path == "") {
		return errors::invalid;
	};
	match (fs.rmdir) {
	case null =>
		return errors::unsupported;
	case let f: *rmdirfunc =>
		return f(fs, path);
	};
};

// Returns the next directory entry from an iterator, or done if none remain.
// '.' and '..' are skipped. It is a programming error to call this again after
// it has returned void. Calling this again after an error is safe. The list is
// not guaranteed to be complete when an error has been returned. The file stat
// returned may only have the type bits set on the file mode; callers should
// call [[stat]] to obtain the detailed file mode.
export fn next(iter: *iterator) (dirent | done | error) = iter.next(iter);
