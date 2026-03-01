// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

fn isaddrmapped(addr: *opaque) bool = {
	// This is a hack, but it's a common pattern on POSIX for testing the
	// validity of an address.
	static let pipefd: [2]int = [0, 0];
	if (pipefd[0] == 0) {
		match (sys::pipe2(&pipefd, 0)) {
		case sys::errno =>
			return false;
		case void => yield;
		};
	};

	match (sys::write(pipefd[1], addr, 1)) {
	case let err: sys::errno =>
		assert(err == sys::EFAULT);
		return false;
	case size =>
		return true;
	};
};
