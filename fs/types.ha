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

export type closefunc = fn(fs: *fs) void;
export type mkdirfunc = fn(fs: *fs, path: str, mode: io::mode) (void | error);
export type rmdirfunc = fn(fs: *fs, path: str) (void | error);

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

	// Creates a directory.
	mkdir: nullable *mkdirfunc,
};
