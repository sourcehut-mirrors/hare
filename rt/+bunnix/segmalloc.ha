// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Allocates a segment.
fn segmalloc(n: size) nullable *opaque = {
	abort(); // TODO
};

// Frees a segment allocated with segmalloc.
fn segfree(p: *opaque, s: size) void = {
	abort(); // TODO
};
