// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

def AARCH64_FP: uint = 29; // fp is an alias of r29
def AARCH64_LR: uint = 30; // lr is an alias of r30

// Returns the stack pointer from a ucontext.
fn uctx_sp(uctx: *opaque) uintptr = {
	const uctx = uctx: *sys::ucontext_t;
	return uctx.uc_mcontext.sp: uintptr;
};

// Returns the instruction pointer from a ucontext.
fn uctx_ip(uctx: *opaque) uintptr = {
	const uctx = uctx: *sys::ucontext_t;
	return uctx.uc_mcontext.pc: uintptr;
};

// Returns the current call frame from a ucontext.
fn uctx_frame(uctx: *opaque) stackframe = {
	const uctx = uctx: *sys::ucontext_t;
	return *(uctx.uc_mcontext.regs[AARCH64_FP]: uintptr: *stackframe);
};
