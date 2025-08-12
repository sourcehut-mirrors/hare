// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use io;

// Returns whether the given stream is connected to a terminal.
export fn isatty(fd: io::file) bool = {
	match (rt::isatty(fd)) {
	case let b: bool =>
		return b;
	case rt::errno =>
		return false;
	};
};
