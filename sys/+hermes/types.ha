// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// A capability address.
export type caddr = u32;

// Flags that apply to the reply syscall.
export type reply_flag = enum u32 {
	NONE = 0,
	REPLY_TO = 1 << 0,
};

// CPU usage statistics.
export type cpustat = struct {
	idle: u64,
	user: u64,
	kern: u64,
};
