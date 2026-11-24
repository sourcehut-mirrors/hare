// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

fn pagealloc(n: size) nullable *opaque = {
	return match (sys::mmap(null, n,
		sys::PROT_READ | sys::PROT_WRITE,
		sys::MAP_PRIVATE | sys::MAP_ANON, -1, 0)) {
	case let err: sys::errno =>
		assert(err == sys::ENOMEM: sys::errno);
		yield null;
	case let p: *opaque =>
		yield p;
	};
};

fn pagefree(p: *opaque, s: size) void = {
	match (sys::munmap(p, s)) {
		case let err: sys::errno =>
			abort("munmap failed");
		case void => void;
	};
};
