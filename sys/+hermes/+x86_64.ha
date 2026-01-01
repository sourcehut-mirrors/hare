// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Size of a page on this target.
export def PAGESIZE = 4096;

// Minimum interrupt vector available to userspace.
export def VECTOR_MIN: u8 = 32;

// Maximum interrupt vector available to userspace.
export def VECTOR_MAX: u8 = 250;

// Maximum legacy IRQ available to userspace.
export def IRQ_MAX: u8 = 16;

// Address to store bootinfo for init.
export def INIT_BOOTINFO_ADDR: uintptr = 0x7fff80000000;

// Initial stack address for init.
export def INIT_STACK_ADDR: uintptr = 0x7fff80000000;

// Capability address of the I/O control capability.
export def INIT_CADDR_IOCONTROL: uint = 8;

// Capability address of the IRQ control capability.
export def INIT_CADDR_IRQCONTROL: uint = 9;

// x86_64-specific boot information
export type arch_bootinfo = struct {
	// Page table capabilities used to load init
	pdpt: cap_range,
	pd: cap_range,
	pt: cap_range,

	// TSC rate in Hz
	tsc_rate: u64,

	// Physical address of ACPI RSDP table
	rsdp: uintptr,

	// Framebuffer provisioned by bootloader, if applicable
	fb: bootfb,
};

// Details about a CPU core installed on the system.
export type cpu_desc = struct {
	id: u32,
};

// Framebuffer pixel format.
export type pixel_format = enum uint {
	RGBX8,
	BGRX8,
};

// Framebuffer provided by bootloader. fb_base & fb_size are set to 0 if the
// bootloader did not prepare a framebuffer.
export type bootfb = struct {
	fb_base: uintptr,
	fb_size: size,
	fmt: pixel_format,
	width: u32,
	height: u32,
	stride: u32,
};

// VSpace mapping flags.
export type map_flag = enum u64 {
	// Generic
	R = 0,		// Read
	W = 1 << 0,	// Write
	X = 1 << 1,	// Execute
	A = 1 << 2,	// Accessed
	D = 1 << 3,	// Dirty

	// Arch-specific
	PWT = 1 << 16,	// Page write through
	PCD = 1 << 17,	// Page cache disable

	RW = R | W,
	RX = R | X,
	VALID_FLAGS = W | X | A | D | PWT | PCD,
};

// Platform registers.
export type context = struct {
	fs: u64,
	fsbase: u64,
	r15: u64,
	r14: u64,
	r13: u64,
	r12: u64,
	r11: u64,
	r10: u64,
	r9: u64,
	r8: u64,
	rbp: u64,
	rdi: u64,
	rsi: u64,
	rdx: u64,
	rcx: u64,
	rbx: u64,
	rax: u64,
	vec: u64,
	errcode: u64,
	rip: u64,
	cs: u64,
	rflags: u64,
	rsp: u64,
	ss: u64,
};

// Types of faults generated on this platform.
export type fault = enum u64 {
	// General protection fault
	GP,
	// Page fault
	// r1: error code
	// r2: faulting address
	PF,
	// Undefined instruction
	UD,
	// Division error
	DE,
	// Floating point error
	XM,
};

// Capability type
export type ctype = enum u8 {
	// Generic
	NULL,
	MEMORY,
	MMIO,
	CSPACE,
	VSPACE,
	TASK,
	PAGE,
	NOTIFICATION,
	ENDPOINT,
	REPLY,

	// Arch-specific
	PDPT,
	PD,
	PT,
	IOCONTROL,
	IOPORT,
	IRQCONTROL,
	IRQ,
};

// Functions implemented by I/O control capabilities.
export type iocontrol_func = enum u64 {
	MAP = 1,
};

// Functions implemented by I/O port capabilities.
export type ioport_func = enum u64 {
	IN8 = 1,
	IN16,
	IN32,
	OUT8,
	OUT16,
	OUT32,
};

// Functions implemented by IRQ control capabilities.
export type irqcontrol_func = enum u64 {
	ISSUE_IRQ = 1,
	ISSUE_IOAPIC,
	ISSUE_MSI,
};

// Functions implemented by IRQ capabilities.
export type irq_func = enum u64 {
	CONFIGURE = 1,
	ACK,
};

// Functions implemented by PDPT capabilities.
export type pdpt_func = enum u64 {
	UNMAP = 1,
	GET_PHYS,
};

// Functions implemented by PD capabilities.
export type pd_func = enum u64 {
	UNMAP = 1,
	GET_PHYS,
};

// Functions implemented by PT capabilities.
export type pt_func = enum u64 {
	UNMAP = 1,
	GET_PHYS,
};

// Page table capabilities in order from smallest to largest.
export const page_table_types = [
	ctype::PT,	// L1PT
	ctype::PD,	// L2PT
	ctype::PDPT,	// L3PT
];
