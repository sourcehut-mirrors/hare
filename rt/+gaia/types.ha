// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt::ipc;

export type cap = ipc::cap;

// Capability address of the init task's cspace.
export def INIT_CAP_CSPACE: uint = 0;

// Capability address of the init task's vspace.
export def INIT_CAP_VSPACE: uint = 1;

// Capability address of the init task's ASID control.
export def INIT_CAP_ASID_CONTROL: uint = 2;

// Capability address of the init task's ASID pool.
export def INIT_CAP_ASID_POOL: uint = 3;

// Capability address of the init task itself.
export def INIT_CAP_TASK: uint = 4;

// Capability address of the init task's IPC buffer page.
export def INIT_CAP_IPC_BUFFER: uint = 5;

// Address of first dynamically allocated capability.
export def INIT_CAP_RANGES_START: uint = 16;

// The bootinfo structure.
export type bootinfo = struct {
	argv: str,

	// Capability ranges
	memory: cap_range,
	devmem: cap_range,
	userimage: cap_range,
	stack: cap_range,
	bootinfo: cap_range,
	unused: cap_range,

	// Other details
	arch: *arch_bootinfo,
	ipcbuf: uintptr,
	modules: []module_desc,
	memory_info: []memory_desc,
	devmem_info: []memory_desc,
	tls_base: uintptr,
	tls_size: size,
};

// A continuous range of capabilities allocated for a single purpose.
export type cap_range = struct {
	// Inclusive
	start: uint,
	// Exclusive
	end: uint,
};

// A description of a region of memory.
export type memory_desc = struct {
	phys: uintptr,
	pages: uint,
};

// A module provided by the boot loader.
export type module_desc = struct {
	pages: cap_range,
	length: size,
};
