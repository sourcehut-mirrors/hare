// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

@symbol("__test_main") fn test_main() (bool | !void);

export fn start_ha() never = {
	init();
	const status = match (test_main()) {
	case let all_pass: bool =>
		yield if (all_pass) 0 else 1;
	case !void =>
		yield 255;
	};
	fini();
	sys::exit(status);
};
