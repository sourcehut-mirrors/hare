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
