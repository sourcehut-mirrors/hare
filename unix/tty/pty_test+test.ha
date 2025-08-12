// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use fs;
use io;
use os;

@test fn pty() void = {
	let (master, slave) = openpty()!;
	defer io::close(slave)!;
	defer io::close(master)!;

	assert(fs::exists(os::cwd, ptsname(slave)!));

	for (let i: u16 = 5; i < 100; i += 1) {
		let sz1 = ttysize { rows = i, columns = i };
		set_winsize(master, sz1)!;
		let sz2 = winsize(slave)!;
		assert(sz2.rows == sz1.rows);
		assert(sz2.columns == sz1.columns);
	};

	fmt::fprintln(master, "hello, world")!;
	const scan = bufio::newscanner(slave);
	defer bufio::finish(&scan);

	const s = bufio::scan_line(&scan) as const str;
	assert(s == "hello, world");
};
