// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use sys;

// Returns whether the given stream is connected to a terminal.
export fn isatty(fd: io::file) bool = {
	let t = sys::termios { ... };
	match (sys::ioctl(fd, sys::TIOCGETA, &t: *opaque)) {
	case let e: sys::errno =>
		return false;
	case let r: int =>
		return r == 0;
	};
};
