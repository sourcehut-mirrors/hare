// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol("__test_main") fn test_main() (bool | !void);
@symbol("environ") let c_envp: *[*]nullable *u8;

export fn entrypoint() void = {
	defer fini();
	match (test_main()) {
	case let all_pass: bool =>
		c_exit(if (all_pass) 0 else 1);
	case !void =>
		c_exit(255);
	};
};
