// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use os;

// Returns a stream connected to the TTY of the current process. The caller must
// close it using [[io::close]].
export fn open() (io::file | error) = {
	match (os::open("/dev/tty", io::flag::RDWR)) {
	case let f: io::file =>
		return f;
	case errors::error =>
		return errors::noentry;
	};
};
