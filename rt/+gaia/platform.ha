// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt::sys;

fn exit(status: uint) never = {
	assert(self != ~0);
	sys::process_exit(self, status);
	abort(); // Unreachable
};
