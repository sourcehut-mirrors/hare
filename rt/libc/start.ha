// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol("environ") let c_envp: *[*]nullable *u8;

export @symbol("main") fn start_ha(c_argc: int, c_argv: *[*]*u8) never = {
	argc = c_argc: size;
	argv = c_argv;
	envp = c_envp;

	init();
	main();
	fini();
	exit(0);
};
