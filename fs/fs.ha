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

// Renames a file. This generally only works if the source and destination path
// are both on the same filesystem. See [[move]] for an implementation which
// falls back on a "copy & remove" procedure in this situation.
export fn rename(fs: *fs, oldpath: str, newpath: str) (void | error) = {
	match (fs.rename) {
	case null =>
		return errors::unsupported;
	case let f: *renamefunc =>
		return f(fs, oldpath, newpath);
	};
};

// Moves a file. This will use [[rename]] if possible, and will fall back to
// copy and remove if necessary.
export fn move(fs: *fs, oldpath: str, newpath: str) (void | error) = {
	match (rename(fs, oldpath, newpath)) {
	case let err: error =>
		match (err) {
		case (cannotrename | errors::unsupported) => void; // Fallback
		case =>
			return err;
		};
	case void =>
		return; // Success
	};
	abort(); // TODO: move me to os:: and re-introduce xdev fallback
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

// Returns the path referred to by a symbolic link. The return value is
// statically allocated and will be overwritten on subsequent calls.
export fn readlink(fs: *fs, path: str) (str | error) = {
	match (fs.readlink) {
	case null =>
		return errors::unsupported;
	case let f: *readlinkfunc =>
		return f(fs, path);
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

// Resolves a path to its absolute, normalized value. Relative paths will be
// rooted (if supported by the fs implementation), and "." and ".." components
// will be reduced. This function does not follow symlinks; see [[realpath]] if
// you need this behavior. The return value is statically allocated; use
// [[strings::dup]] to extend its lifetime.
export fn resolve(fs: *fs, path: str) str = {
	match (fs.resolve) {
	case null => void;
	case let f: *resolvefunc =>
		return f(fs, path);
	};
	static let buf = path::buffer { ... };
	path::set(&buf, path)!;
	return path::string(&buf);
};

// Creates a new (hard) link at 'new' for the file at 'old'.
export fn link(fs: *fs, old: str, new: str) (void | error) = {
	match (fs.link) {
	case null =>
		return errors::unsupported;
	case let f: *linkfunc =>
		return f(fs, old, new);
	};
};

// Creates a new symbolic link at 'path' which points to 'target'.
export fn symlink(fs: *fs, target: str, path: str) (void | error) = {
	match (fs.symlink) {
	case null =>
		return errors::unsupported;
	case let f: *symlinkfunc =>
		return f(fs, target, path);
	};
};

// Returns the next directory entry from an iterator, or done if none remain.
// '.' and '..' are skipped. It is a programming error to call this again after
// it has returned void. Calling this again after an error is safe. The list is
// not guaranteed to be complete when an error has been returned. The file stat
// returned may only have the type bits set on the file mode; callers should
// call [[stat]] to obtain the detailed file mode.
export fn next(iter: *iterator) (dirent | done | error) = iter.next(iter);
