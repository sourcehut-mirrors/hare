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
