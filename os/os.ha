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

// Renames a file. This generally only works if the source and destination path
// are both on the same filesystem. See [[move]] for an implementation which
// falls back on a "copy & remove" procedure in this situation.
export fn rename(oldpath: str, newpath: str) (void | fs::error) =
	fs::rename(cwd, oldpath, newpath);

// Moves a file. This will use [[rename]] if possible, and will fall back to
// copy and remove if necessary.
export fn move(oldpath: str, newpath: str) (void | fs::error) =
	fs::move(cwd, oldpath, newpath);

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

// Resolves a path to its absolute, normalized value. Relative paths will be
// rooted (if supported by the host filesystem), and "." and ".." components
// will be reduced. This function does not follow symlinks; see [[realpath]] if
// you need this behavior. The return value is statically allocated; use
// [[strings::dup]] to extend its lifetime.
export fn resolve(path: str) str = fs::resolve(cwd, path);

// Returns the path referred to by a symbolic link. The return value is
// statically allocated and will be overwritten on subsequent calls.
export fn readlink(path: str) (str | fs::error) = fs::readlink(cwd, path);

// Creates a new (hard) link at 'new' for the file at 'old'.
export fn link(old: str, new: str) (void | fs::error) = fs::link(cwd, old, new);

// Creates a new symbolic link at 'path' which points to 'target'.
export fn symlink(target: str, path: str) (void | fs::error) =
	fs::symlink(cwd, target, path);

// Canonicalizes a path in this filesystem by resolving all symlinks and
// collapsing any "." or ".." path components.
//
// This function is a thin shim over [[fs::realpath]], and the return value is
// statically allocated by [[fs::realpath]]. Thus, calls to this function or to
// [[fs::realpath]] will overwrite the return value of either function.
export fn realpath(path: str) (str | fs::error) = fs::realpath(cwd, path);
