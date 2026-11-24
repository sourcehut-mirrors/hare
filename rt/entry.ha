// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

fn entrypoint() never = {
	init();
	main();
	fini();
	sys::exit(0);
};
