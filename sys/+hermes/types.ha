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

// Flags used for call/send/recv operations.
export type ipc_flag = enum u64 {
	// First 12 bits indicate the number of bytes of bulk data to transfer
	// between IPC buffers, if applicable.

	NONE = 0,

	// Indicates the N'th argument is a capability address to be
	// transferred. The sender indicates the capability to send, and the
	// receiver indicates an empty slot to receive the capability in. The
	// sender and receiver must match, or else the sender returns with an
	// error.
	CAP_A1 = 1 << 12,
	CAP_A2 = 1 << 13,
	CAP_A3 = 1 << 14,
	CAP_A4 = 1 << 15,
	CAP_A5 = 1 << 16,

	// (Sender only) Indicates that the capabilities being sent should be
	// transferred with move semantics. The default behavior copies
	// capabilities instead.
	MOVE = 1 << 17,

	// (Caller only) Indicates that the capability addresses used for
	// CAP_A1-A5 are slots for receiving transfers upon reply.
	FOR_REPLY = 1 << 18,
};

// Flags that apply to the reply syscall.
export type reply_flag = enum u32 {
	// First 12 bits indicate the number of bytes of bulk data to transfer
	// between IPC buffers, if applicable.

	NONE = 0,

	// Indicates the N'th argument is a capability address to be
	// transferred via the reply. The caller being replied to must have
	// specified the FOR_REPLY flag and must have [[ipc_flag::CAP_A1]]-A5
	// configured to match the reply.
	CAP_A1 = 1 << 12,
	CAP_A2 = 1 << 13,
	CAP_A3 = 1 << 14,
	CAP_A4 = 1 << 15,
	CAP_A5 = 1 << 16,

	// Indicates that the capabilities being sent should be transferred with
	// move semantics. The default behavior copies capabilities instead.
	MOVE = 1 << 17,

	// Indicates that the reply is directed towards a stored reply
	// capability, whose capability address is indicated by the first ABI
	// argument to the syscall.
	REPLY_TO = 1 << 18,
};

