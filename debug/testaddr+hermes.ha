// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

fn isaddrmapped(addr: *opaque) bool = {
	match (sys::log(addr: *[*]u8, 0)) {
	case let err: sys::errno =>
		assert(err == sys::EFAULT);
		return false;
	case void =>
		return true;
	};
};
