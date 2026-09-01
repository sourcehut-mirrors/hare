// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol("__test_main") fn test_main() (bool | !void);
@symbol("environ") let c_envp: *[*]nullable *u8;

export @symbol("main") fn start_ha(c_argc: int, c_argv: *[*]*u8) int = {
	argc = c_argc: size;
	argv = c_argv;
	envp = c_envp;

	init();
	defer fini();
	match (test_main()) {
	case let all_pass: bool =>
		return if (all_pass) 0 else 1;
	case !void =>
		return 255;
	};
};
