// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type ucontext_t = struct {
	link: *ucontext_t,
	uc_sigmask: sigset,
	uc_stack: stack_t,
	uc_mcontext: mcontext_t,
};

export type mcontext_t = vregs;

export type vregs = struct {
	rax: u64,
	rbx: u64,
	rcx: u64,
	rdx: u64,
	rdi: u64,
	rsi: u64,
	rbp: u64,
	r8: u64,
	r9: u64,
	r10: u64,
	r11: u64,
	r12: u64,
	r13: u64,
	r14: u64,
	r15: u64,
	rsp: u64,
	rip: u64,
	rflags: u64,
	fpu: savefpu,
};

export type savefpu = struct {
	fp_fxsave: fpu_state,
	fp_xstate: xstate_hdr,
	fp_ymm: [16]x86_64_xmm_register,
};

export type xstate_hdr = struct {
	bv: u64,
	xcom_bv: u64,
	_: [48]u8,
};

export type fpu_state = struct {
	control: u16,
	status: u16,
	tag: u16,
	opcode: u16,
	rip: u64,
	rdp: u64,
	mxcsr: u32,
	mxcsr_mask: u32,

	union {
		fp: [8]x86_64_fp_register,
		mmx: [8]x86_64_fp_register,
	},

	xmm: [16]x86_64_xmm_register,
	_: [96]u8,
};

export type x86_64_xmm_register = struct {
	value: [16]u8,
};

export type x86_64_fp_register = struct {
	value: [10]u8,
	_: [6]u8,
};
