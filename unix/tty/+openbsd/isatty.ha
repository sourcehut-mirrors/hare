// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;
use io;

// Returns whether the given stream is connected to a terminal.
export fn isatty(fd: io::file) bool = {
	return sys::fcntl(fd, sys::F_ISATTY, 0) is int;
};
