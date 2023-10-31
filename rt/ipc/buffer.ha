// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export let ipcbuf: *ipc_buffer = null: *ipc_buffer;

// A capability address.
export type cap = uint;

// Maximum capabilities that can be used in a single IPC call.
export def MAX_CAP: size = 64;

// Maximum parameters that can be used in a single IPC call.
export def MAX_PARAM: size = 64;

// The IPC buffer.
export type ipc_buffer = struct {
	// Message tag
	tag: u64,
	// Badge of the invoked capability, or zero
	badge: uint,
	// Registers
	params: [64]u64,
	// Capability addresses
	caps: [64]cap,
	// Flags for capabilities transferred
	capflags: [64]capflag,
};

// Flags that apply to capabilities in an IPC buffer.
export type capflag = enum uint {
	// Three bits are reserved to specify the maximum lookup depth for this
	// capability address, up to 7 levels.
	//
	// If the depth is zero, the lookup depth is unbounded. If nonzero, the
	// resolver will traverse nested cspaces up to the maximum depth,
	// terminating upon reaching the maximum depth or when encountering a
	// node which is not a capability space. The remaining bits of the
	// capability address are discarded when the maximum depth is reached.
	//
	// This field is reset to zero by the kernel after use.
	DEPTH_MASK = 0b111,

	// Set by userspace on receive to indicate that a capability should be
	// unwrapped, not transferred, on receipt. Set by the kernel to confirm
	// that this occurred, or unset if the capability could not be unwrapped
	// (it's not an endpoint, or it is unbadged). In this case no capability
	// transfer takes place.
	UNWRAP = 1 << 4,

	// Indicates to the kernel that a capability should be allocated for
	// this slot. If the DEPTH_MASK is unset, the capability is allocated in
	// the caller's cspace and the address is discarded. Otherwise, the
	// address in this slot is resolved up to the max depth and the
	// addressed capability shall be the cspace to allocate the capability
	// in.
	//
	// The kernel writes the newly allocated capability address back into
	// the corresponding caps field of the IPC buffer and clears this bit to
	// zero after allocation.
	CAPALLOC = 1 << 5,
};
