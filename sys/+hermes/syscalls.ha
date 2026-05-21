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

export @symbol("sys_reply") fn sys_reply(
	r1: u64,
	r2: u64,
	addr: caddr = 0,
	flags: reply_flag = reply_flag::NONE,
) (u64, u64);

// Yields the current time slice to the scheduler.
export @symbol("sys_schedule") fn schedule() void;

@symbol("sys_log") fn sys_log(data: *[*]u8, n: size) (u64, u64);

export fn log(data: *[*]u8, n: size) (void | errno) = {
	check_void(sys_log(data, n))?;
};

@symbol("sys_cpu_stat") fn sys_cpu_stat(_: u32, _: *cpustat, _: size) (u64, u64);

export fn cpu_stat(id: u32, buf: *cpustat) (void | errno) = {
	return check_void(sys_cpu_stat(id, buf, size(cpustat)))?;
};

@symbol("sys_ident") fn sys_ident(_: caddr) (u64, u64);

export fn ident(addr: caddr) (ctype | errno) = {
	return check_u64(sys_ident(addr))?: ctype;
};

@symbol("sys_signal") fn sys_signal(_: caddr, _: u32) (u64, u64);

export fn signal(addr: caddr, word: u32) (void | errno) = {
	check_void(sys_signal(addr, word))?;
};

@symbol("sys_wait") fn sys_wait(_: caddr) (u64, u64);

export fn wait(addr: caddr) (u64 | errno) = {
	return check_u64(sys_wait(addr))?: u64;
};

export @symbol("sys_call") fn call(user: u64, ...) (u64, u64);

export @symbol("sys_poll") fn sys_poll(vectors: *[*]poll_cap, nvec: size) (u64, u64);

export fn poll(vectors: []poll_cap) (size | errno) = {
	return check_u64(sys_poll(vectors: *[*]poll_cap, len(vectors)))?: size;
};

export @symbol("sys_recv_cap") fn sys_recv_cap(
	dest: caddr,
	flags: recv_cap_flag,
	reply: caddr,
) (u64, u64);
