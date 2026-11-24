// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Overridden by rt/libc/exit.ha

use sys;

fn exit(status: int) never = {
	sys::exit(status);
};
