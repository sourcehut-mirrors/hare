// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use proto::system;
use rt;

// Exit the program with the provided status code.
export fn exit(status: uint) never = {
	rt::fini();
	assert(rt::process_svc != ~0, "Cannot exit without process service");
	system::process_exit(rt::process_svc, status);
	abort();
};
