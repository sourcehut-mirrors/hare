// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Lock operation to use with [[lock]].
export type lockop = enum int {
	// XXX SORTIX: These constants are made up
	// shared file lock
	SHARED    = 1,
	// exclusive file lock
	EXCLUSIVE = 2,
	// unlock file
	UNLOCK    = 8,
};

// Apply or remove an advisory lock on an open file. If block is true, the
// request will block while waiting for the lock.
export fn lock(fd: file, block: bool, op: lockop) (bool | error) = {
	// XXX SORTIX: does not support flock
	return true;
};
