// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;
use types::c;

// Returns the current working directory. The return value is statically
// allocated and must be duplicated (see [[strings::dup]]) before calling getcwd
// again.
export fn getcwd() str = c::tostr(rt::getcwd() as *const u8: *const c::char)!;

// Access modes for [[access]].
export type amode = enum int {
	F_OK = rt::F_OK,
	R_OK = rt::R_OK,
	W_OK = rt::W_OK,
	X_OK = rt::X_OK,
};

// Returns true if the given mode of access is permissible. The use of this
// function is discouraged as it can allow for a race condition to occur betwen
// testing for the desired access mode and actually using the file should the
// permissions of the file change between these operations. It is recommended
// instead to attempt to use the file directly and to handle any errors that
// should occur at that time.
export fn access(path: str, mode: amode) (bool | errors::error) = {
	match (rt::access(path, mode)) {
	case let b: bool =>
		return b;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};

// Change the current working directory.
export fn chdir(target: str) (void | errors::error) = {
	match (rt::chdir(target)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Changes the root directory of the process. Generally requires the caller to
// have root or otherwise elevated permissions.
//
// This function is not appropriate for sandboxing.
export fn chroot(target: str) (void | errors::error) = {
	match (rt::chroot(target)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};
