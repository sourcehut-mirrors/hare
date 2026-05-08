// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use sys;
use unix;

fn isaddrmapped(addr: *opaque) bool = {
	// This is a hack, but it's a common pattern on POSIX for testing the
	// validity of an address.
	static let pipefd: [2]int = [0, 0];
	if (pipefd[0] == 0) {
		const (rd, wr) = match (unix::pipe()) {
		case let pipe: (io::file, io::file) =>
			yield pipe;
		case =>
			return false;
		};
		pipefd[0] = rd;
		pipefd[1] = wr;
	};

	match (sys::write(pipefd[1], addr, 1)) {
	case let err: sys::errno =>
		assert(err == sys::EFAULT);
		return false;
	case size =>
		return true;
	};
};
