// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use proto::system;
use sys;

@symbol("main") fn main() void;

export fn start_ha() never = {
	init();
	main();
	fini();

	assert(process_svc != ~0, "Cannot exit without process service");
	system::process_exit(process_svc, 0);
	abort();
};
