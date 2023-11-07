// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn syscall0(u64) (u64, u64);
fn syscall1(u64, u64) (u64, u64);
fn syscall2(u64, u64, u64) (u64, u64);
fn syscall3(u64, u64, u64, u64) (u64, u64);
fn syscall4(u64, u64, u64, u64, u64) (u64, u64);
fn syscall5(u64, u64, u64, u64, u64, u64) (u64, u64);
fn syscall6(u64, u64, u64, u64, u64, u64, u64) (u64, u64);

export def SYS_writecons: uint = 0;
export def SYS_yield: uint = 1;
export def SYS_send: uint = 3;
export def SYS_recv: uint = 4;
export def SYS_signal: uint = 5;
export def SYS_wait: uint = 6;
export def SYS_nbsend: uint = 7;
export def SYS_nbrecv: uint = 8;
export def SYS_nbwait: uint = 9;
export def SYS_call: uint = 10;
export def SYS_reply: uint = 11;
export def SYS_poll: uint = 12;
export def SYS_pollx: uint = 13;

// Writes data to the kernel console, returning the number of bytes written.
export fn writecons(buf: []u8) size = {
	return syscall2(SYS_writecons,
		buf: *[*]u8: uintptr: u64,
		len(buf): u64).1: size;
};

// Yields the current task's time slice.
export fn yieldtask() void = {
	syscall0(SYS_yield);
};

// Sends a message to a capability.
export fn send(
	cap: cap,
	tag: u64,
	a1: u64,
	a2: u64,
	a3: u64,
) (u64 | syserror) = {
	return check(syscall5(SYS_send, cap: u64, tag, a1, a2, a3))?;
};

// Receives a message from a capability.
export fn recv(cap: cap) (u64, u64) = {
	return syscall1(SYS_recv, cap: u64);
};

// Signals a notification capability.
export fn signal(note: cap, word: uint) (void | syserror) = {
	check(syscall2(SYS_signal, note: u64, word: u64))?;
};

// Waits on a notification capability.
export fn wait(note: cap) (uint | syserror) = {
	return check(syscall1(SYS_wait, note: u64))?: uint;
};

// Performs a non-blocking send to a capability.
export fn nbsend(
	cap: cap,
	tag: u64,
	a1: u64,
	a2: u64,
	a3: u64,
) (u64 | syserror) = {
	return check(syscall5(SYS_nbsend, cap: u64, tag, a1, a2, a3))?;
};

// Performs a non-blocking receive from a capability.
export fn nbrecv(cap: cap) (u64 | syserror) = {
	return check(syscall1(SYS_nbrecv, cap: u64))?;
};

// Performs a non-blocking wait on a notification capability.
export fn nbwait(note: cap) (uint | syserror) = {
	return check(syscall1(SYS_nbwait, note: u64))?: uint;
};

// Performs a call to a capability, sending it a message and blocking until a
// reply is received.
export fn call(
	cap: cap,
	tag: u64,
	a1: u64,
	a2: u64,
	a3: u64,
) (u64, u64) = {
	return syscall5(SYS_call, cap: u64, tag, a1, a2, a3);
};

// Sends a message to the reply capability in the current task's reply slot.
export fn reply(
	tag: u64,
	a1: u64,
	a2: u64,
	a3: u64,
) (void | syserror) = {
	check(syscall4(SYS_reply, tag, a1, a2, a3))?;
};

// Polls on endpoint or notification capabilities.
export fn poll(
	tag: u64,
	a1: u64,
	a2: u64,
	a3: u64,
) (void | syserror) = {
	check(syscall4(SYS_poll, tag, a1, a2, a3))?;
};
