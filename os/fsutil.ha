// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;

// Returns true if a node exists at the given path, or false if not.
//
// Note that testing for file existence before using the file can often lead to
// race conditions. If possible, prefer to simply attempt to use the file (e.g.
// via "open"), and handle the resulting error should the file not exist.
export fn exists(path: str) bool = {
	match (rt::access(path, rt::F_OK)) {
	case let b: bool =>
		return b;
	case let err: rt::errno =>
		switch (err) {
		case rt::EACCES, rt::ENOENT, rt::ENOTDIR =>
			return false;
		case =>
			// Implementation error
			abort();
		};
	};
};

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
