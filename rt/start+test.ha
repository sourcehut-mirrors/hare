// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

@symbol("__test_main") fn test_main() size;

export fn start_ha() never = {
	init();
	const nfail = test_main();
	fini();
	sys::exit(if (nfail > 0) 1 else 0);
};
