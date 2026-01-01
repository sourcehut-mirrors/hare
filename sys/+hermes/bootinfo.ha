// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Radix of init's cspace.
export def INIT_CSPACE_RADIX: u8 = 16;

// Size of init's stack (64KiB).
export def INIT_STACK_SIZE: size = 1 << 16;

// Capability address of the init task's cspace.
export def INIT_CADDR_CSPACE: caddr = 0;

// Capability address of the init task's vspace.
export def INIT_CADDR_VSPACE: caddr = 1;

// Capability address of the init task itself.
export def INIT_CADDR_TASK: caddr = 2;

// Address of first dynamically allocated capability.
export def INIT_CADDR_DYNAMIC_START: caddr = 16;

// Information passed to the init task about the boot environment.
export type bootinfo = struct {
	// Capability ranges
	bootinfo: cap_range,
	memory: cap_range,
	mmio: cap_range,
	userimage: cap_range,
	stack: cap_range,
	modules: cap_range,
	unused: cap_range,

	// Other details
	memory_info: []memory_desc,
	mmio_info: []memory_desc,
	cpu_info: []cpu_desc,
	module_info: []module_desc,

	// Arch-specific details
	arch_bootinfo,
};

// Indicates a range of capabilities.
export type cap_range = struct {
	// Inclusive
	start: u32,
	// Exclusive
	end: u32,
};

// A description of a region of memory.
export type memory_desc = struct {
	phys: uintptr,
	pages: size,
};

export type module_desc = struct {
	data: []u8,
};
