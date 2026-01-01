// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

// TODO: Log to stdout/stderr if available
fn logstr(s: str) void = {
	_ = sys::log((*(&s: *[]u8)): *[*]u8, len(s));
};

fn platform_abort(path: *str, line: u64, col: u64, msg: str) never = {
	let linebuf: [U64_BUFSZ]u8 = [0...];
	let colbuf: [U64_BUFSZ]u8 = [0...];

	logstr("Abort: ");
	logstr(*path);
	logstr(": ");
	logstr(u64tos(linebuf, line));
	logstr(":");
	logstr(u64tos(colbuf, col));
	logstr(": ");
	logstr(msg);
	logstr("\n");

	halt();
};
