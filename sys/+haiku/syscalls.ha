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

@symbol("writev") fn libc_writev(d: int, iov: const *[*]iovec, iovcnt: int) size;

export fn writev(fd: int, iov: const *[*]iovec, iovcnt: int) (size | errno) = {
	let res: u64 = libc_writev(fd, iov, iovcnt);
	check_error(res == -1)?;
	return res;
};

@symbol("kill") fn libc_kill(pid: pid_t, signal: int) int;

export fn kill(pid: pid_t, signal: int) (void | errno) = {
	let res = libc_kill(pid, signal);
	check_error(res == -1)?;
};

export @symbol("getpid") fn getpid() pid_t;
