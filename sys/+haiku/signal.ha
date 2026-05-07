// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

@symbol("sigwait") fn libc_sigwait(set: *sigset, sig: *int) int;

export fn sigwait(set: *sigset, sig: *int) (void | errno) = {
	let res = libc_sigwait(set, sig);
	if (res != 0) {
		return get_errno();
	};
};

export @symbol("alarm") fn alarm(sec: uint) int;
export @symbol("sigemptyset") fn sigemptyset(set: *sigset) void;
export @symbol("sigemptyset") fn sigfillset(set: *sigset) void;

@symbol("sigaddset") fn libc_sigaddset(set: *sigset, sig: int) int;

export fn sigaddset(set: *sigset, sig: int) (void | errno) = {
	let res = libc_sigaddset(set, sig);
	check_error(res != 0)?;
};

@symbol("sigdelset") fn libc_sigdelset(set: *sigset, sig: int) int;

export fn sigdelset(set: *sigset, sig: int) (void | errno) = {
	let res = libc_sigdelset(set, sig);
	check_error(res != 0)?;
};

@symbol("sigaddset") fn libc_sigismember(set: *sigset, sig: int) int;

export fn sigismember(set: *sigset, sig: int) (bool | errno) = {
	let res = libc_sigismember(set, sig);
	check_error(res == -1)?;
	return res == 1;
};

// Test sigset operations do not fail for valid signal numbers.
@test fn sigset_valid_signum() void = {
	let set: sigset = 0;
	sigemptyset(&set);

	assert(!(sigismember(&set, 1) is errno), "Unexpected error");
	assert(!(sigismember(&set, 15) is errno), "Unexpected error");
	assert(!(sigismember(&set, NSIG) is errno), "Unexpected error");

	assert(!(sigaddset(&set, 1) is errno), "Unexpected error");
	assert(!(sigaddset(&set, 15) is errno), "Unexpected error");
	assert(!(sigaddset(&set, NSIG) is errno), "Unexpected error");

	// It's ok to add a signal that is already present in the set.
	assert(!(sigaddset(&set, 1) is errno), "Unexpected error");

	assert(!(sigdelset(&set, 1) is errno), "Unexpected error");
	assert(!(sigdelset(&set, 15) is errno), "Unexpected error");
	assert(!(sigdelset(&set, NSIG) is errno), "Unexpected error");

	// It's ok to delete a signal that is not present in the set.
	assert(!(sigdelset(&set, 10) is errno), "Unexpected error");
};

// Test sigset operations fail for invalid signal numbers.
@test fn sigset_invalid_signum() void = {
	let set: sigset = 0;
	sigemptyset(&set);

	assert(sigismember(&set, -1) is errno, "Expected error");
	assert(sigismember(&set, 0) is errno, "Expected error");
	assert(sigismember(&set, NSIG + 1) is errno, "Expected error");

	assert(sigaddset(&set, -1) is errno, "Expected error");
	assert(sigaddset(&set, 0) is errno, "Expected error");
	assert(sigaddset(&set, NSIG + 1) is errno, "Expected error");

	assert(sigdelset(&set, -1) is errno, "Expected error");
	assert(sigdelset(&set, 0) is errno, "Expected error");
	assert(sigdelset(&set, NSIG + 1) is errno, "Expected error");
};
