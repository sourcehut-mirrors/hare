// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Allocates a segment.
fn segmalloc(n: size) nullable *opaque = {
	return match (rt::mmap(null, n, rt::PROT_READ | rt::PROT_WRITE,
		rt::MAP_PRIVATE | rt::MAP_ANON, -1, 0)) {
	case let err: rt::errno =>
		assert(err == rt::ENOMEM);
		yield null;
	case let p: *opaque =>
		yield p;
	};
};

// Frees a segment allocated with segmalloc.
fn segfree(p: *opaque, s: size) void = {
	rt::munmap(p, s)!;
};

// Forward declarations from rt::
type rt::errno = !int;

fn rt::mmap(nullable *opaque, size, uint, uint, int, size) (*opaque | rt::errno);
fn rt::munmap(*opaque, size) (void | rt::errno);

def rt::ENOMEM: rt::errno = 12;
def rt::MAP_PRIVATE: uint = 0x02;
def rt::MAP_ANON: uint    = 0x20;
def rt::PROT_READ: uint   = 1;
def rt::PROT_WRITE: uint  = 2;
