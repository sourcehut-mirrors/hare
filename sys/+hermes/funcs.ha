// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Functions implemented by memory capabilities.
export type memory_func = enum u64 {
	ALLOC = 1,
	GET_PHYS,
	GET_FREE_PAGES,
};

// Functions implemented by MMIO capabilities.
export type mmio_func = enum u64 {
	ALLOC = 1,
	GET_PHYS,
};

// Functions implemented by cspace capabilities.
export type cspace_func = enum u64 {
	SET_GUARD = 1,
	GET_GUARD,
	GET_RADIX,
	COPY,
	MOVE,
	DESTROY,
	STORE_REPLY,
};

// Functions implemented by task capabilities.
export type task_func = enum u64 {
	SET_GUARD = 1,
	CONFIGURE,
	CONFIGURE_FAULT,
	SUSPEND,
	RESUME,
	READ_REGISTERS,
	WRITE_REGISTERS,
	SET_AFFINITY,
	UNSET_AFFINITY,
};

// Functions implemented by cspace capabilities.
export type vspace_func = enum u64 {
	MAP = 1,
	REMAP,
};

// Functions implemented by page capabilities.
export type page_func = enum u64 {
	UNMAP = 1,
	GET_PHYS,
};
