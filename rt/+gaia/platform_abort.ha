// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use rt::io;

fn ud() never;

let aborted = false;

fn platform_abort(path: *str, line: u64, col: u64, msg: str) never = {
	if (aborted) {
		ud(); // Prevents stack overflow from aborts in pool_acquire etc
	};
	aborted = true;

	if (auxv[0].a_type == elf::at::NULL) {
		abort_klog(path, line, col, msg);
	};

	const prefix = "Abort: ";
	const sep = ":";
	const sepspace = ": ";
	const linefeed = "\n";

	const (page, base) = pool_acquire();
	write_stderr(page, base, *(&prefix: **opaque): *const u8, len(prefix));
	write_stderr(page, base, *(path: **opaque): *const u8, len(path));
	write_stderr(page, base, *(&sep: **opaque): *const u8, len(sep));
	let (line, z) = u64tos(line);
	write_stderr(page, base, line, z);
	write_stderr(page, base, *(&sep: **opaque): *const u8, len(sep));
	let (col, z) = u64tos(col);
	write_stderr(page, base, col, z);
	write_stderr(page, base, *(&sepspace: **opaque): *const u8, len(sepspace));
	write_stderr(page, base, *(&msg: **opaque): *const u8, len(msg));
	write_stderr(page, base, *(&linefeed: **opaque): *const u8, 1);
	ud();
};

fn abort_klog(path: *str, line: u64, col: u64, msg: str) never = {
	const prefix = "Abort: ";
	const sep = ":";
	const sepspace = ": ";
	const linefeed = "\n";

	// If we were not provided with an auxillary vector, we are not running
	// in a Gaia-compatible environment, and stderr is unavailable. The most
	// common explanation is that this process is sysinit. In this case,
	// we should abort to the kernel log rather than stderr.
	write_klog(*(&prefix: **opaque): *const u8, len(prefix));
	write_klog(*(path: **opaque): *const u8, len(path));
	write_klog(*(&sep: **opaque): *const u8, len(sep));
	let (line, z) = u64tos(line);
	write_klog(line, z);
	write_klog(*(&sep: **opaque): *const u8, len(sep));
	let (col, z) = u64tos(col);
	write_klog(col, z);
	write_klog(*(&sepspace: **opaque): *const u8, len(sepspace));
	write_klog(*(&msg: **opaque): *const u8, len(msg));
	write_klog(*(&linefeed: **opaque): *const u8, 1);
	ud();
};

fn write_stderr(page: cap, base: uintptr, data: *const u8, n: size) void = {
	let data = data: *[*]u8;
	let string = base: *[*]u8;
	string[..n] = data[..n];
	io::file_write(2, [page], base, n);
};

fn write_klog(data: *const u8, n: size) void = {
	let data = data: *[*]u8;
	writecons(data[..n]);
};
