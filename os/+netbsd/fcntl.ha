// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use sys;

// Returns the [[fs::flag]]s associated with a file descriptor. See fcntl(2).
export fn getfl(file: io::file) (fs::flag | errors::error) = {
	match (sys::fcntl(file, sys::F_GETFL, void)) {
	case let i: int =>
		return bsd_to_fsflags(i);
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Sets the [[fs::flag]]s associated with a file descriptor. Changes to the
// access mode (e.g. [[fs::flag::RDWR]] and file creation flags (e.g.
// [[fs::flag::CREATE]]) are ignored. See fcntl(2).
export fn setfl(file: io::file, flags: fs::flag) (void | errors::error) = {
	const flags = fsflags_to_bsd(flags)?;
	match (sys::fcntl(file, sys::F_SETFL, flags)) {
	case int =>
		return;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};
