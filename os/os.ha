// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fs;
use io;
use path;
use time;

// Provides an implementation of [[fs::fs]] for the current working directory.
export let cwd: *fs::fs = null: *fs::fs;

// Removes a file.
export fn remove(path: str) (void | fs::error) = fs::remove(cwd, path);

// Creates an [[fs::iterator]] for a given directory to read its contents. The
// user should call [[fs::next]] to enumerate entries, and [[fs::finish]] when
// done using the object.
export fn iter(path: str) (*fs::iterator | fs::error) = fs::iter(cwd, path);

// Reads all entries from a directory. The caller must free the return value
// with [[fs::dirents_free]].
export fn readdir(path: str) ([]fs::dirent | fs::error) = fs::readdir(cwd, path);

// Creates a directory.
export fn mkdir(path: str, mode: io::mode) (void | fs::error) = fs::mkdir(cwd, path, mode);

// Creates a directory, and all non-extant directories in its path.
export fn mkdirs(path: str, mode: io::mode) (void | fs::error) = fs::mkdirs(cwd, path, mode);

// Removes a directory. The target directory must be empty; see [[rmdirall]] to
// remove its contents as well.
export fn rmdir(path: str) (void | fs::error) = fs::rmdir(cwd, path);

// Removes a directory, and anything in it.
export fn rmdirall(path: str) (void | fs::error) = fs::rmdirall(cwd, path);
