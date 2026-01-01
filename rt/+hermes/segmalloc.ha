// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type segment_allocator = struct {
	segmalloc: *fn(n: size) nullable *opaque,
	segfree: *fn(p: *opaque, s: size) void,
};

let global_allocator: nullable *segment_allocator = null;

fn get_allocator() *segment_allocator = {
	assert(global_allocator != null,
		"Runtime heap allocation is not available");
	return global_allocator: *segment_allocator;
};

// Sets the global [[segment_allocator]] for the runtime. Can only be called
// once during the lifetime of the process.
export fn set_allocator(obj: *segment_allocator) void = {
	assert(global_allocator == null,
		"Cannot initialize multiple global allocators over lifetime of process");
	global_allocator = obj;
};

// Allocates a segment.
fn segmalloc(n: size) nullable *opaque = {
	return get_allocator().segmalloc(n);
};

// Frees a segment allocated with segmalloc.
fn segfree(p: *opaque, s: size) void = {
	get_allocator().segfree(p, s);
};
