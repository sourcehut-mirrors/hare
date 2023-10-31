// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt::io;

fn ud() never;

let aborted = false;

fn platform_abort(path: *str, line: u64, col: u64, msg: str) void = {
	if (aborted) {
		ud(); // Prevents stack overflow from aborts in pool_acquire etc
	};
	aborted = true;

	const prefix = "Abort: ";
	const sep = ":";
	const sepspace = ": ";
	const linefeed = "\n";

	const (page, base) = pool_acquire();
	write_stderr(page, base, *(&prefix: **opaque): *const u8, len(prefix)): void;
	write_stderr(page, base, *(path: **opaque): *const u8, len(path)): void;
	write_stderr(page, base, *(&sep: **opaque): *const u8, len(sep)): void;
	let (line, z) = u64tos(line);
	write_stderr(page, base, line, z): void;
	write_stderr(page, base, *(&sep: **opaque): *const u8, len(sep)): void;
	let (col, z) = u64tos(col);
	write_stderr(page, base, col, z): void;
	write_stderr(page, base, *(&sepspace: **opaque): *const u8,
		len(sepspace)): void;
	write_stderr(page, base, *(&msg: **opaque): *const u8, len(msg)): void;
	write_stderr(page, base, *(&linefeed: **opaque): *const u8, 1): void;
	ud();
};

fn write_stderr(page: cap, base: uintptr, data: *const u8, n: size) void = {
	let data = data: *[*]u8;
	let string = base: *[*]u8;
	string[..n] = data[..n];
	io::file_write(2, [page], base, n);
};
