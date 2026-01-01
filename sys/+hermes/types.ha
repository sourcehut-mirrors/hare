// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// A capability address.
export type caddr = u32;

// CPU usage statistics.
export type cpustat = struct {
	idle: u64,
	user: u64,
	kern: u64,
};

// Flags used for call operations.
export type call_flag = enum u64 {
	NONE = 0,

	// First 12 bits indicate the number of bytes of bulk data to transfer
	// between IPC buffers, if applicable.
	BUFSIZE_MASK = (1 << 12) - 1,

	// Indicates the N'th argument is the address of a capability (in the
	// caller's cspace) which the callee can copy to its own cspace.
	CAP_A1_OUT = 1 << 12,
	CAP_A2_OUT = 1 << 13,
	CAP_A3_OUT = 1 << 14,
	CAP_A4_OUT = 1 << 15,
	CAP_A5_OUT = 1 << 16,
	CAP_OUT_SHIFT   = 12,

	// Indicates that the 1st argument is a capability address where a
	// capability may be transferred from the callee during the reply.
	//
	// If [[CAP_A1_OUT]] is also set, [[MOVE]] must be set.
	//
	// If the capability address is invalid or refers to an occupied slot
	// (at the time of the reply), the callee generates a fault.
	CAP_A1_IN = 1 << 12,

	// Indicates that caller-initiated capability transfers should be
	// peformed with move semantics, not copy semantics.
	MOVE = 1 << 13,
};

// Flags that apply to the reply syscall.
export type reply_flag = enum u64 {
	NONE = 0,

	// First 12 bits indicate the number of bytes of bulk data to transfer
	// between IPC buffers, if applicable.
	BUFSIZE_MASK = (1 << 12) - 1,

	// Indicates that the reply is directed towards a stored reply
	// capability, whose capability address is indicated by the first ABI
	// argument to the syscall.
	REPLY_TO = 1 << 12,

	// Indicates that a capability should be transferred to the caller. The
	// caller must have [[CAP_A1_IN]] set.
	WITH_CAP = 1 << 13,

	// If [[WITH_CAP]] is specified, the capability transferred to the
	// caller is transferred with move semantics, not copy semantics.
	MOVE = 1 << 14,
};

// Events which can be polled on.
export type poll_event = enum u32 {
	NONE = 0,

	CALL = 1 << 0,
	RECV = 1 << 1,
	WAIT = RECV,
};

// Input for poll syscalls.
export type poll_cap = struct {
	// Address of capability to poll for
	caddr: caddr,
	// Events to poll for (in)
	events: poll_event,
	// Events available (out)
	revent: poll_event,
};
