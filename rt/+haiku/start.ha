// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

// The real main function.
@symbol(".main") fn main() void;

@symbol("__hare_init_array_start") const init_start: [*]*fn() void;
@symbol("__hare_init_array_end") const init_end: [*]*fn() void;
@symbol("__hare_fini_array_start") const fini_start: [*]*fn() void;
@symbol("__hare_fini_array_end") const fini_end: [*]*fn() void;

export @symbol("main") fn _main(
	c_argc: int,
	c_argv: *[*]*const u8,
	c_envp: *[*]nullable *const u8
) void = {
	argc = c_argc: size;
	argv = c_argv;
	envp = c_envp;

	init();
	main();
	fini();
	sys::exit(0);
};
