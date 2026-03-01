// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

// Exit the program with the provided status code.
export fn exit(status: int) never = {
	// The @fini functions will be run by libc.
	sys::exit(status);
};
