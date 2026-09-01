// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use fs;
use io;
use os;
use time;

// Prints a context line from the source file.
fn print_context(
	out: io::handle,
	path: str,
	line: u64,
	col: u64,
	age: time::instant,
) (size | io::error) = {
	let z = 0z;

	const file = match (os::open(path)) {
	case fs::error =>
		return 0z;
	case let file: io::file =>
		yield file;
	};
	defer _ = io::close(file);

	match (os::fstat(file)) {
	case let st: fs::filestat =>
		if (st.mask & fs::stat_mask::MTIME == 0) yield;
		if (time::compare(st.mtime, age) == 1) {
			z += fmt::fprintln(out, "* Warning: file was modified after executable was built")?;
		};
	case => void;
	};

	static let linebuf: [1024]u8 = [0...];
	const scan = bufio::newscanner_buf(file, linebuf);

	let context = "";
	for (let i = 0u; i < line; i += 1) {
		match (bufio::scan_line(&scan)) {
		case let s: const str =>
			context = s;
		case =>
			return z;
		};
	};

	z += fmt::fprintfln(out, "| {}", context)?;

	if (col != 0) {
		z += fmt::fprint(out, "  ")?;
		for (let i = 1u; i < col - 1; i += 1) {
			z += fmt::fprint(out, " ")?;
		};
		z += fmt::fprint(out, "^")?;
	};

	z += fmt::fprintln(out)?;
	return z;
};
