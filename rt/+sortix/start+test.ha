// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol("__test_main") fn test_main() size;

let @symbol("environ") environ: *[*]nullable *u8;

const @symbol("__libc_init_array_start") init_start: [*]*fn() void;
const @symbol("__libc_init_array_end") init_end: [*]*fn() void;
const @symbol("__fini_array_start") fini_start: [*]*fn() void;
const @symbol("__fini_array_end") fini_end: [*]*fn() void;

// The purpose of this "fake" main function is to make sure we exit with the
// correct exit code in the case that rt::exit() is not called from within the
// program. The intilization and finilization functions are not run from here,
// they are ran by crt0.
export fn main(c_argc: int, c_argv: *[*]*u8) int = {
	argc = c_argc: size;
	argv = c_argv;
	envp = environ;

	// we deliberately prevent libc from running @init for us, in order to
	// be able to initialize argc/argv/envp beforehand. we can still get
	// away with just using libc for @fini though
	init();
	const nfail = test_main();
	return if (nfail > 0) 1 else 0;
};
