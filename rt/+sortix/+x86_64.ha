// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type gregset_t = struct {
	r8: u64,
	r9: u64,
	r10: u64,
	r11: u64,
	r12: u64,
	r13: u64,
	r14: u64,
	r15: u64,
	rdi: u64,
	rsi: u64,
	rbp: u64,
	rbx: u64,
	rdx: u64,
	rax: u64,
	rcx: u64,
	rsp: u64,
	rip: u64,
	efl: u64,
	csgsfs: u64,
	cr2: u64,
	fsbase: u64,
	gsbase: u64,
};

export type mcontext_t = struct {
	gregs: gregset_t,
	fpuenv: [512]u8,
};

export type ucontext_t = struct {
	uc_link: nullable *ucontext_t,
	uc_sigmask: sigset,
	uc_stack: stack_t,
	uc_mcontext: mcontext_t,
};
