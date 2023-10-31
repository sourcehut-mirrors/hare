// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt::sys;
use rt::sys::{map_flags};

// Allocates a segment.
fn segmalloc(n: size) nullable *opaque = {
	assert(self != ~0);
	return sys::mmapper_mmap(self, [], 0, n, map_flags::W): *opaque;
};

// Frees a segment allocated with segmalloc.
fn segfree(p: *opaque, s: size) void = {
	assert(self != ~0);
	return sys::munmapper_munmap(self, p: uintptr, s);
};
