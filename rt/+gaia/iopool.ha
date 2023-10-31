// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;

def IOPOOL_STATIC: size = 128;

let iopool_static: [IOPOOL_STATIC]iopool_page = [iopool_page { ... }...];
let iopool: []iopool_page = [];

export type iopool_aux = struct {
	base: uintptr,
	npage: uint,
	pages: [*]cap,
};

type iopool_page = struct {
	base: uintptr,
	page: cap,
	lock: bool,
};

fn iopool_init(aux: *iopool_aux) void = {
	iopool = iopool_static[..0];

	const vec = aux.pages[..aux.npage];
	if (len(vec) > IOPOOL_STATIC) {
		vec = vec[..IOPOOL_STATIC];
	};

	const base = aux.base;
	for (let i: uintptr = 0; i < len(vec): uintptr; i += 1) {
		static append(iopool, iopool_page {
			base = base + i * UPAGESIZE,
			page = vec[i],
			lock = false,
		});
	};
};

// Acquires a page of memory from the I/O pool, blocking until one is available.
// The caller must call [[pool_release]] when they are done using it.
export fn pool_acquire() (cap, uintptr) = {
	assert(len(iopool) != 0, "io::pool_acquire called without valid I/O pool");
	for (let i = 0z; i < len(iopool); i += 1) {
		const item = &iopool[i];
		if (!item.lock) {
			item.lock = true;
			return (item.page, item.base);
		};
	};
	abort("No I/O pool available");
};

// Returns a page to the I/O pool with the given base address.
export fn pool_release(base: uintptr) void = {
	for (let i = 0z; i < len(iopool); i += 1) {
		if (iopool[i].base == base) {
			iopool[i].lock = false;
			return;
		};
	};

	abort("Unknown page returned to I/O pool");
};
