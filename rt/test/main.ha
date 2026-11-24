// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol("__test_main") fn test_main() (bool | !void);

export fn main() void = {
	defer fini();

	const status = match (test_main()) {
	case let all_pass: bool =>
		yield if (all_pass) 0 else 1;
	case !void =>
		yield 255;
	};
	exit(status);
};
