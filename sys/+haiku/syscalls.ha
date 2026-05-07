// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

let pathbuf: [PATH_MAX]u8 = [0...];

// For functions that need more than one path, i.e. unveil, linkat, renameat, etc.
let pathbuf1: [PATH_MAX]u8 = [0...];

export type path = (str | []u8 | *const u8);

fn copy_cpath(path: path, buf: []u8) (*const u8 | errno) = {
	let path = match (path) {
	case let c: *const u8 =>
		return c;
	case let s: str =>
		let ptr = &s: *struct {
			buf: *[*]u8,
			length: size,
			capacity: size,
		};
		yield ptr.buf[..ptr.length];
	case let b: []u8 =>
		yield b;
	};
	if (len(path) + 1 >= len(buf)) {
		return ENAMETOOLONG;
	};
	buf[..len(path)] = path;
	buf[len(path)] = 0;
	return buf: *[*]u8: *const u8;
};

// NUL terminates a string and stores it in a static buffer of PATH_MAX bytes in
// length.
fn cpath(path: path) (*const u8 | errno) = {
	return copy_cpath(path, pathbuf);
};

// exit
export @symbol("exit") fn exit(status: int) never;

// writev

@symbol("readv") fn libc_readv(d: int, iov: const *[*]iovec, iovcnt: int) size;

export fn readv(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	let res: u64 = libc_readv(fd, iov, iovcnt);
	check_error(res == -1)?;
	return res;
};

@symbol("read") fn libc_read(d: int, buf: *opaque, nbytes: size) size;

export fn read(fd: int, buf: *opaque, count: size) (size | errno) = {
	let res: u64 = libc_read(fd, buf, count);
	check_error(res == -1)?;
	return res;
};

@symbol("writev") fn libc_writev(d: int, iov: const *[*]iovec, iovcnt: int) size;

export fn writev(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	let res: u64 = libc_writev(fd, iov, iovcnt);
	check_error(res == -1)?;
	return res;
};

@symbol("write") fn libc_write(d: int, buf: *const opaque, nbytes: size) size;

export fn write(fd: int, buf: *const opaque, count: size) (size | errno) = {
	let res: u64 = libc_write(fd, buf, count);
	check_error(res == -1)?;
	return res;
};

@symbol("close") fn libc_close(d: int) int;

export fn close(fd: int) (void | errno) = {
	let res = libc_close(fd);
	check_error(res == -1)?;
};

@symbol("lseek") fn libc_lseek(fildes: int, pos: i64, whence: int) i64;

export fn lseek(fd: int, off: i64, whence: int) (i64 | errno) = {
	let res = libc_lseek(fd, off, whence);
	check_error(res == -1)?;
	return res;
};

@symbol("flock") fn libc_flock(fd: int, op: int) int;

export fn flock(fd: int, op: int) (void | errno) = {
	let res = libc_flock(fd, op);
	check_error(res == -1)?;
};

@symbol("ftruncate") fn libc_ftruncate(fd: int, length: i64) int;

export fn ftruncate(fd: int, length: i64) (void | errno) = {
	let res = libc_ftruncate(fd, length);
	check_error(res == -1)?;
};

@symbol("kill") fn libc_kill(pid: pid_t, signal: int) int;

export fn kill(pid: pid_t, signal: int) (void | errno) = {
	let res = libc_kill(pid, signal);
	check_error(res == -1)?;
};

export @symbol("getpid") fn getpid() pid_t;
export @symbol("getppid") fn getppid() pid_t;

@symbol("getsid") fn libc_getsid(pid: pid_t) pid_t;

export fn getsid(pid: pid_t) (pid_t | errno) = {
	let res = libc_getsid(pid);
	check_error(res == -1)?;
	return res;
};

@symbol("setsid") fn libc_setsid() pid_t;

export fn setsid() (void | errno) = {
	let res = libc_setsid();
	check_error(res == -1)?;
};

export @symbol("getpgrp") fn getpgrp() pid_t;

@symbol("getpgid") fn libc_getpgid(pid: pid_t) pid_t;

export fn getpgid(pid: pid_t) (pid_t | errno) = {
	let res = libc_getpgid(pid);
	check_error(res == -1)?;
	return res;
};

@symbol("setpgid") fn libc_setpgid(pid: pid_t, pgrp: pid_t) int;

export fn setpgid(pid: pid_t, pgrp: pid_t) (void | errno) = {
	let res = libc_setpgid(pid, pgrp);
	check_error(res == -1)?;
};

@symbol("setuid") fn libc_setuid(uid: uid_t) int;

export fn setuid(uid: uid_t) (void | errno) = {
	let res = libc_setuid(uid);
	check_error(res == -1)?;
};

export @symbol("getuid") fn getuid() uid_t;
export @symbol("geteuid") fn geteuid() uid_t;

export @symbol("getgid") fn getgid() gid_t;
export @symbol("getegid") fn getegid() gid_t;

@symbol("setgid") fn libc_setgid(gid: gid_t) int;

export fn setgid(gid: gid_t) (void | errno) = {
	let res = libc_setgid(gid);
	check_error(res == -1)?;
};

// setegid

@symbol("setegid") fn libc_setegid(gid: gid_t) int;

export fn setegid(gid: gid_t) (void | errno) = {
	let res = libc_setegid(gid);
	check_error(res == -1)?;
};

// seteuid

@symbol("seteuid") fn libc_seteuid(uid: uid_t) int;

export fn seteuid(uid: uid_t) (void | errno) = {
	let res = libc_seteuid(uid);
	check_error(res == -1)?;
};

@symbol("getgroups") fn libc_getgroups(gidsetlen: int, gidset: *[*]gid_t) int;

export fn getgroups(gids: []gid_t) (uint | errno) = {
	let res = libc_getgroups(len(gids): int, gids: *[*]gid_t);
	check_error(res == -1)?;
	return res: uint;
};

// setgroups

@symbol("setgroups") fn libc_setgroups(
	ngroups: int,
	gidset: *[*]gid_t,
) int;

export fn setgroups(gids: []gid_t) (void | errno) = {
	let res = libc_setgroups(len(gids): int, gids: *[*]gid_t);
	check_error(res == -1)?;
};

@symbol("dup2") fn libc_dup(fd: int) int;

export fn dup(fd: int) (int | errno) = {
	let res = libc_dup(fd);
	check_error(res == -1)?;
	return res;
};

@symbol("dup2") fn libc_dup2(oldd: int, newd: int) int;

export fn dup2(oldfd: int, newfd: int) (int | errno) = {
	let res = libc_dup2(oldfd, newfd);
	check_error(res == -1)?;
	return res;
};

@symbol("fcntl") fn libc_fcntl(fd: int, cmd: int, arg: u64) int;

export type fcntl_arg = (void | int | *st_flock | *u64);

export fn fcntl(fd: int, cmd: int, arg: fcntl_arg) (int | errno) = {
	let res = match (arg) {
	case void =>
		yield libc_fcntl(fd, cmd, 0);
	case let i: int =>
		yield libc_fcntl(fd, cmd, i: u64);
	case let l: *st_flock =>
		yield libc_fcntl(fd, cmd, l: uintptr: u64);
	case let u: *u64 =>
		yield libc_fcntl(fd, cmd, u: uintptr: u64);
	};
	check_error(res == -1)?;
	return res;
};

@symbol("mmap") fn libc_mmap(
	addr: nullable *opaque,
	len_: size,
	prot: int,
	flags: int,
	fd: int,
	pos: i64
) nullable *opaque;

export fn mmap(
	addr: nullable *opaque,
	len_: size,
	prot: int,
	flags: int,
	fd: int,
	pos: i64
) (*opaque | errno) = {
	let res = libc_mmap(addr, len_, prot, flags, fd, pos);
	check_error(res == MAP_FAILED)?;
	return res: *opaque;
};

@symbol("munmap") fn libc_munmap(addr: *opaque, len_: size) int;

export fn munmap(addr: *opaque, len_: size) (void | errno) = {
	let res = libc_munmap(addr, len_);
	check_error(res == -1)?;
};

@symbol("fsync") fn libc_fsync(fd: int) int;

export fn fsync(fd: int) (void | errno) = {
	let res = libc_fsync(fd);
	check_error(res == -1)?;
	return res;
};

@symbol("nanosleep") fn libc_nanosleep(
	timeout: *const timespec,
	remainder: nullable *timespec,
) int;

export fn nanosleep(
	timeout: *const timespec,
	remainder: nullable *timespec,
) (void | errno) = {
	let res = libc_nanosleep(timeout, remainder);
	check_error(res == -1)?;
};

@symbol("clock_nanosleep") fn libc_clock_nanosleep(
	clock: clockid_t,
	flags: int,
	timeout: *const timespec,
	remainder: nullable *timespec,
) int;

export fn clock_nanosleep(
	clock: clockid_t,
	flags: int,
	timeout: *const timespec,
	remainder: nullable *timespec,
) (void | errno) = {
	let res = libc_clock_nanosleep(clock, flags, timeout, remainder);
	check_error(res == -1)?;
};

@symbol("clock_gettime") fn libc_clock_gettime(clock: int, now: *timespec) int;

export fn clock_gettime(clock: int, now: *timespec) (void | errno) = {
	let res = libc_clock_gettime(clock, now);
	check_error(res == -1)?;
};

@symbol("clock_settime") fn libc_clock_settime(clock: int, now: *const timespec) int;

export fn clock_settime(clock: int, now: *const timespec) (void | errno) = {
	let res = libc_clock_settime(clock, now);
	check_error(res == -1)?;
};

@symbol("getpriority") fn libc_getpriority(which: int, who: id_t) int;

export fn getpriority(which: int, who: id_t) (int | errno) = {
	let res = libc_getpriority(which, who);
	check_error(res == -1)?;
	return res;
};

@symbol("setpriority") fn libc_setpriority(
	which: int,
	who: id_t,
	prio: int
) int;

export fn setpriority(which: int, who: id_t, prio: int) (void | errno) = {
	let res = libc_setpriority(which, who, prio);
	check_error(res == -1)?;
};

@symbol("pipe") fn libc_pipe(pipefd: *[2]int) int;

export fn pipe(pipefd: *[2]int) (void | errno) = {
	let res = libc_pipe(pipefd);
	check_error(res == -1)?;
};

@symbol("getrlimit") fn libc_getrlimit(
	resource: int,
	rlp: *rlimit,
) int;

export fn getrlimit(resource: int, rlp: *rlimit) (void | errno) = {
	let res = libc_getrlimit(resource, rlp);
	check_error(res == -1)?;
};

@symbol("setrlimit") fn libc_setrlimit(
	resource: int,
	rlp: const *rlimit,
) int;

export fn setrlimit(resource: int, rlp: const *rlimit) (void | errno) = {
	let res = libc_setrlimit(resource, rlp);
	check_error(res == -1)?;
};

@symbol("umask") fn libc_umask(numask: mode_t) mode_t;

export fn umask(mode: mode_t) (mode_t | errno) = {
	return libc_umask(mode);
};

export @symbol("sigaction") fn libc_sigaction(
	sig: int,
	act: *const sigact,
	oact: nullable *sigact
) int;

export fn sigaction(
	signum: int,
	act: *const sigact,
	old: nullable *sigact,
) (void | errno) = {
	let res = libc_sigaction(signum, act, old);
	check_error(res == -1)?;
};

export @symbol("sigaltstack") fn libc_sigaltstack(
	ss: const nullable *stack_t, oss: nullable *stack_t,
) int;

export fn sigaltstack(
	ss: const nullable *stack_t,
	oss: nullable *stack_t,
) (void | errno) = {
	let res = libc_sigaltstack(ss, oss);
	check_error(res == -1)?;
};

@symbol("sigprocmask") fn libc_sigprocmask(
	how: int,
	set: nullable *const sigset,
	old: nullable *sigset
) int;

export fn sigprocmask(
	how: int,
	set: nullable *const sigset,
	old: nullable *sigset
) (void | errno) = {
	let res = libc_sigprocmask(how, set, old);
	check_error(res == -1)?;
};
