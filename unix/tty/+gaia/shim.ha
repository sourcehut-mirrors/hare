// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use rt_io = rt::io;

// Returns whether the given stream is connected to a tty.
export fn isatty(fd: io::file) bool = {
	return rt_io::file_isconsole(fd);
};
