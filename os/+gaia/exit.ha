// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use rt::sys;

// Exit the program with the provided status code.
export fn exit(status: int) never = {
	rt::fini();
	assert(rt::self != ~0);
	// TODO: Make use of the exit status
	sys::process_kill(rt::self);
	abort("unreachable");
};
