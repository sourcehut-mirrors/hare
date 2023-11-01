// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;
use strings;
use types::c;

// The command line arguments provided to the program. By convention, the first
// member is usually the name of the program.
export let args: []str = [];

// Statically allocate arg strings if there are few enough arguments, saves a
// syscall if we don't need it.
let args_static: [32]str = [""...];

@init fn args() void = {
	if (rt::argc < len(args_static)) {
		args = args_static[..rt::argc];
		for (let i = 0z; i < rt::argc; i += 1) {
			args[i] = c::tostr(rt::argv[i]: *const c::char)!;
		};
	} else {
		args = alloc([], rt::argc);
		for (let i = 0z; i < rt::argc; i += 1) {
			append(args, c::tostr(rt::argv[i]: *const c::char)!);
		};
	};

};

@fini fn args() void = {
	if (rt::argc >= len(args_static)) {
		free(args);
	};
};

// Returns a slice of the environment strings in the form KEY=VALUE.
export fn getenvs() []str = {
	// NOTE: This is a shim for Gaia support. Environment variables are not
	// supported by Gaia but are planned to be introduced later. The PATH
	// variable is set as a temporary measure so that os::exec works
	// properly.
	if (len(envp) != 0) {
		return envp;
	};
	append(envp, strings::dup("PATH=/bin:/sbin"));
	return envp;
};

// Returns the host kernel name
export fn sysname() const str = {
	return "helios";
};

// Returns the number of usable CPUs.
export fn cpucount() (size | errors::error) = {
	return errors::unsupported;
};
