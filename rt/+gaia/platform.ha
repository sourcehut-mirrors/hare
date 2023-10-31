// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt::sys;

fn exit(status: int) never = {
	assert(self != ~0);
	sys::process_kill(self);
	abort(); // Unreachable
};
