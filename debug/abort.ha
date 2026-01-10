// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use debug::image;
use fmt;
use fs;
use os;
use rt;
use sys;

let default_abort: *rt::abort_handler = @undefined;

@init fn init_abort() void = {
	default_abort = rt::onabort(&debug_abort);
};

// Note: take care not to get into an abort loop when working on this code
fn debug_abort(
	path: *str,
	line: u64,
	col: u64,
	msg: str,
) never = {
	begin_fatal();

	const self = match (image::self()) {
	case let img: image::image =>
		yield img;
	case =>
		_ = fmt::errorfln("Abort: {}:{}:{}: {}", *path, line, col, msg);
		let frame = walk();
		skip_frames(&frame, 2);
		simple_backtrace(frame);
		rt::halt();
	};
	defer image::close(&self);

	const st = match (os::fstat(self.fd)) {
	case let st: fs::filestat =>
		yield st;
	case fs::error =>
		yield fs::filestat { mask = 0, ... };
	};

	_ = fmt::errorfln("Abort: {}:{}:{}: {}", *path, line, col, msg);
	print_context(*path, line, col, st.mtime);

	let frame = walk();
	skip_frames(&frame, 2);
	backtrace(&self, frame);
	rt::halt();
};

fn skip_frames(frame: *stackframe, n: uint) void = {
	for (n > 0; n -= 1) {
		match (next(*frame)) {
		case let next: stackframe =>
			*frame = next;
		case done => rt::halt();
		};
	};
};
