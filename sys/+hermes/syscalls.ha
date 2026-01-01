// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Checks a syscall outcome which returns an error or void.
export fn check_void(r: (u64, u64)) (void | errno) = {
	const (err, _) = r;
	if (err != 0) {
		return err: errno;
	};
};

// Checks a syscall outcome which returns an error or a u64.
export fn check_u64(r: (u64, u64)) (u64 | errno) = {
	const (err, res) = r;
	if (err != 0) {
		return err: errno;
	};
	return res;
};

@symbol("sys_log") fn _log(data: *[*]u8, n: size) (u64, u64);

export fn log(data: *[*]u8, n: size) (void | errno) = {
	check_void(_log(data, n))?;
};

export @symbol("sys_schedule") fn schedule() void;

@symbol("sys_cpu_stat") fn _cpu_stat(_: u32, _: *cpustat, _: size) (u64, u64);

export fn cpu_stat(id: u32, buf: *cpustat) (void | errno) = {
	return check_void(_cpu_stat(id, buf, size(cpustat)))?;
};

@symbol("sys_ident") fn _ident(_: caddr) (u64, u64);

export fn ident(addr: caddr) (ctype | errno) = {
	return check_u64(_ident(addr))?: ctype;
};

@symbol("sys_signal") fn _signal(_: caddr, _: u32) (u64, u64);

export fn signal(addr: caddr, word: u32) (void | errno) = {
	check_void(_signal(addr, word))?;
};

@symbol("sys_wait") fn _wait(_: caddr) (u64, u64);

export fn wait(addr: caddr) (u64 | errno) = {
	return check_u64(_wait(addr))?: u64;
};

export @symbol("sys_call") fn call(user: u64, ...) (u64, u64);

@symbol("sys_reply") fn _reply(
	r1: u64,
	r2: u64,
	addr: caddr = 0,
	flags: reply_flag = reply_flag::NONE,
) (u64, u64);

export fn reply(
	r1: u64,
	r2: u64,
	addr: caddr = 0,
	flags: reply_flag = reply_flag::NONE,
) (void | errno) = {
	check_void(_reply(r1, r2, addr, flags))?;
};

@symbol("sys_poll") fn _poll(vectors: *[*]poll_cap, nvec: size) (u64, u64);

export fn poll(vectors: []poll_cap) (size | errno) = {
	return check_u64(_poll(vectors: *[*]poll_cap, len(vectors)))?: size;
};
