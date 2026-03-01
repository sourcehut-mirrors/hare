// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use sys;

// Exit the program with the provided status code.
export fn exit(status: int) never = {
	rt::fini();
	sys::exit(status);
};
