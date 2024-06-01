// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use errors;
use io;
use path;
use strings;

// An entry of a particular type was sought, but is something else in practice.
// For example, opening a file with [[iter]].
export type wrongtype = !void;

// Returned from [[rename]] if this rename is not possible due to technical
// constraints, such as if it would cause a file to move between filesystems. In
// this situation, other operations (such as copy & remove) may succeed if
// attempted.
export type cannotrename = !void;

// All possible fs error types.
export type error = !(
	errors::noentry |
	errors::noaccess |
	errors::exists |
	errors::busy |
	errors::invalid |
	errors::unsupported |
	utf8::invalid |
	wrongtype |
	cannotrename |
	io::error);

// Returns a human-friendly representation of an error.
export fn strerror(err: error) const str = match (err) {
case wrongtype =>
	yield "Wrong entry type for requested operation";
case cannotrename =>
	yield "Unable to perform rename operation (try move instead)";
case errors::noentry =>
	yield "File or directory not found";
case errors::noaccess =>
	yield "Permission denied";
case errors::exists =>
	yield "File or directory exists";
case errors::invalid =>
	yield "Invalid argument";
case errors::busy =>
	yield "Device is busy";
case errors::unsupported =>
	yield "Operation not supported";
case let err: utf8::invalid =>
	yield utf8::strerror(err);
case let err: io::error =>
	yield io::strerror(err);
};

// An entry in a directory. This may be borrowed from the filesystem's internal
// state. If you want to keep this around beyond one call to [[next]], use
// [[dirent_dup]].
export type dirent = struct {
	// The name of this entry. Not fully qualified: for example,
	// "foo/bar/baz.txt" would store "baz.txt" here.
	name: str,

	// The type of this entry. The permission bits may be unset.
	ftype: io::mode,
};

// Duplicates a [[dirent]] object. Call [[dirent_finish]] to get rid of it
// later.
export fn dirent_dup(e: *dirent) dirent = {
	let new = *e;
	new.name = strings::dup(e.name);
	return new;
};

// Frees memory associated with a [[dirent]] object which was duplicated with
// [[dirent_dup]].
export fn dirent_finish(e: *dirent) void = free(e.name);

export type closefunc = fn(fs: *fs) void;
export type removefunc = fn(fs: *fs, path: str) (void | error);
export type renamefunc = fn(fs: *fs, oldpath: str, newpath: str) (void | error);
export type iterfunc = fn(fs: *fs, path: str) (*iterator | error);
export type mkdirfunc = fn(fs: *fs, path: str, mode: io::mode) (void | error);
export type rmdirfunc = fn(fs: *fs, path: str) (void | error);
export type resolvefunc = fn(fs: *fs, path: str) str;
export type readlinkfunc = fn(fs: *fs, path: str) (str | error);
export type linkfunc = fn(fs: *fs, old: str, new: str) (void | error);
export type symlinkfunc = fn(fs: *fs, target: str, path: str) (void | error);

// An abstract implementation of a filesystem, which provides common filesystem
// operations such as file creation and deletion, but which may be backed by any
// underlying storage system. See [[os::cwd]] for access to the host filesystem.
//
// To create a custom filesystem implementation, embed this type as the first
// member of a struct with user-specific data and fill out these fields as
// appropriate.
export type fs = struct {
	// Frees resources associated with this filesystem.
	close: nullable *closefunc,

	// Removes a file.
	remove: nullable *removefunc,

	// Renames a file.
	rename: nullable *renamefunc,

	// Returns an iterator for a path, which yields the contents of a
	// directory. Pass empty string to yield from the root.
	//
	// The iterator must return all entries without error. If an error would
	// occur, it should be identified here and returned upfront.
	iter: nullable *iterfunc,

	// Returns the path referred to by a symbolic link. The caller will free
	// the return value.
	readlink: nullable *readlinkfunc,

	// Creates a directory.
	mkdir: nullable *mkdirfunc,

	// Removes a directory. The target directory must be empty.
	rmdir: nullable *rmdirfunc,

	// Resolves a path to its absolute, normalized value. If the fs
	// implementation does not provide this, [resolve] presumes that
	// relative paths are rooted (i.e. "foo" == "/foo").
	resolve: nullable *resolvefunc,

	// Creates a new (hard) link.
	link: nullable *linkfunc,

	// Creates a new symbolic link.
	symlink: nullable *symlinkfunc,
};

// A function which returns the next directory from an [[iterator]].
export type nextfunc = fn(iter: *iterator) (dirent | done | error);

// A function which frees state associated with an [[iterator]].
export type finishfunc = fn(iter: *iterator) void;

// A directory iterator. To implement a directory iterator for a filesystem,
// subtype this struct to store any necessary state and populate the pointers
// with your implementation.
export type iterator = struct {
	// Returns the next member of the directory, or done if there are none
	// remaining.
	next: *nextfunc,
	// Frees resources associated with the iterator.
	finish: nullable *finishfunc,
};
