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
