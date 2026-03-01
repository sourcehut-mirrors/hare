// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;

// Returns the dimensions of underlying terminal for an [[io::file]].
export fn winsize(fd: io::file) (ttysize | error) = {
	let wsz = sys::winsize { ... };
	match (sys::ioctl(fd, sys::TIOCGWINSZ, &wsz: *opaque)) {
	case let e: sys::errno =>
		switch (e) {
		case sys::EBADF =>
			return errors::invalid;
		case sys::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case int =>
		return ttysize {
			rows = wsz.ws_row,
			columns = wsz.ws_col,
		};
	};
};
