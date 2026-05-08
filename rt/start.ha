// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

@symbol("main") fn main() void;

export fn start_ha() never = {
	init();
	main();
	fini();
	sys::exit(0);
};
