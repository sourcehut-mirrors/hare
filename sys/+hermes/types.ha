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
	// If [[CAP_A1_OUT]] is also set, [[MOVE]] must be set, to empty the
	// slot before accepting the incoming transfer.
	//
	// If the capability address is invalid or refers to an occupied slot
	// (at the time of the reply), the call returns with an error.
	CAP_A1_IN = 1 << 17,

	// Indicates that caller-initiated capability transfers should be
	// peformed with move semantics, not copy semantics.
	MOVE = 1 << 18,
};

// Flags that apply to the reply syscall.
export type reply_flag = enum u64 {
	NONE = 0,

	// First 12 bits indicate the number of bytes of bulk data to transfer
	// between IPC buffers, if applicable.
	BUFSIZE_MASK = (1 << 12) - 1,

	// Indicates that the reply is directed towards a stored reply
	// capability. The third ABI parameter to SYS_reply is used as the
	// capability address of the capability to be replied to.
	REPLY_TO = 1 << 12,

	// Indicates that the high 32 bits of r1 is a capability address, in the
	// callee's cspace, to be transferred to the recipient. The caller must
	// have [[call_flag::CAP_A1_IN]] set.
	//
	// Up to one R*_CAP flag may be set in a reply.
	R1H_CAP = 1 << 13,

	// Indicates that low 32 bits of r1 is a capability address, in the
	// callee's cspace, to be transferred to the recipient. The caller must
	// have [[call_flag::CAP_A1_IN]] set.
	//
	// Up to one R*_CAP flag may be set in a reply.
	R1L_CAP = 1 << 14,

	// Indicates that the high 32 bits of r2 is a capability address, in the
	// callee's cspace, to be transferred to the recipient. The caller must
	// have [[call_flag::CAP_A1_IN]] set.
	//
	// Up to one R*_CAP flag may be set in a reply.
	R2H_CAP = 1 << 15,

	// Indicates that the low 32 bits of r2 is a capability address, in the
	// callee's cspace, to be transferred to the recipient. The caller must
	// have [[call_flag::CAP_A1_IN]] set.
	//
	// Up to one R*_CAP flag may be set in a reply.
	R2L_CAP = 1 << 16,

	// If a capability is included in the reply, the capability transferred
	// to the caller is transferred with move semantics, not copy semantics.
	MOVE = 1 << 17,
};

// Flags that apply to the recv_cap syscall.
export type recv_cap_flag = enum u32 {
	// Recieve capability from the 1st call argument. Corresponds to
	// [[call_flag::CAP_A1_IN]].
	A1 = 0,
	// Recieve capability from the 2nd call argument. Corresponds to
	// [[call_flag::CAP_A2_IN]].
	A2 = 1,
	// Recieve capability from the 3rd call argument. Corresponds to
	// [[call_flag::CAP_A3_IN]].
	A3 = 2,
	// Recieve capability from the 4th call argument. Corresponds to
	// [[call_flag::CAP_A4_IN]].
	A4 = 3,
	// Recieve capability from the 5th call argument. Corresponds to
	// [[call_flag::CAP_A5_IN]].
	A5 = 4,

	// Mask to get the addressed capability register, [[A1]]-[[A5]].
	A_MASK = 0b111,

	// Receive from a specific reply capability stored in the slot addressed
	// by the third parameter to SYS_recv_cap. If not specified, the reply
	// stored in the calling task's reply slot is used.
	RECV_FROM = 1 << 8,
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
