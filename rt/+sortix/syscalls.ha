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
	memcpy(buf: *[*]u8, path: *[*]u8, len(path));
	buf[len(path)] = 0;
	return buf: *[*]u8: *const u8;
};

// NUL terminates a string and stores it in a static buffer of PATH_MAX bytes in
// length.
fn cpath(path: path) (*const u8 | errno) = {
	return copy_cpath(path, pathbuf);
};

// /include/errno.h: #define errno (*libk_get_errno_location())
@symbol("libk_get_errno_location") fn __errno() *int;

export @symbol("exit") fn exit(status: int) never;

@symbol("read") fn libc_read(d: int, buf: *opaque, nbytes: size) size;

export fn read(fd: int, buf: *opaque, count: size) (size | errno) = {
	let res: u64 = libc_read(fd, buf, count);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

@symbol("write") fn libc_write(d: int, buf: *const opaque, nbytes: size) size;

export fn write(fd: int, buf: *const opaque, count: size) (size | errno) = {
	let res: u64 = libc_write(fd, buf, count);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

@symbol("close") fn libc_close(d: int) int;

export fn close(fd: int) (void | errno) = {
	let res = libc_close(fd);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("lseek") fn libc_lseek(fildes: int, pos: i64, whence: int) i64;

export fn lseek(fd: int, off: i64, whence: int) (i64 | errno) = {
	let res = libc_lseek(fd, off, whence);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

@symbol("ftruncate") fn libc_ftruncate(fd: int, length: i64) int;

export fn ftruncate(fd: int, length: i64) (void | errno) = {
	let res = libc_ftruncate(fd, length);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("nanosleep") fn libc_nanosleep(
	timeout: *const timespec,
	remainder: *timespec
) int;

export fn nanosleep(
	timeout: *const timespec,
	remainder: *timespec
) (void | errno) = {
	let res = libc_nanosleep(timeout, remainder);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("clock_gettime") fn libc_clock_gettime(clock: int, now: *timespec) int;

export fn clock_gettime(clock: int, now: *timespec) (void | errno) = {
	let res = libc_clock_gettime(clock, now);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("clock_settime") fn libc_clock_settime(clock: int, now: *const timespec) int;

export fn clock_settime(clock: int, now: *const timespec) (void | errno) = {
	let res = libc_clock_settime(clock, now);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("uname") fn libc_uname(uts: *utsname) int;

export fn uname(uts: *utsname) (void | errno) = {
	let res = libc_uname(uts);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("openat") fn libc_openat(
	fd: int,
	path: *const u8,
	flags: int,
	mode: uint,
) int;

export fn openat(
	dirfd: int,
	path: path,
	flags: int,
	mode: uint,
) (int | errno) = {
	let res = libc_openat(dirfd, cpath(path)?, flags, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

@symbol("readlinkat") fn libc_readlinkat(
	fd: int,
	path: *const u8,
	buf: *u8,
	bufsiz: size
) i64;

export fn readlinkat(
	dirfd: int,
	path: path,
	buf: []u8,
) (size | errno) = {
	let res = libc_readlinkat(dirfd, cpath(path)?, buf: *[*]u8: *u8, len(buf));
	if (res == -1) {
		return *__errno(): errno;
	};
	return res: size;
};

@symbol("unlinkat") fn libc_unlinkat(fd: int, path: *const u8, flag: int) int;

export fn unlinkat(dirfd: int, path: path, flags: int) (void | errno) = {
	let res = libc_unlinkat(dirfd, cpath(path)?, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("fstatat") fn libc_fstatat(fd: int, path: *const u8, sb: *stat, flag: int) int;

export fn fstatat(
	dirfd: int,
	path: path,
	stat: *stat,
	flag: int
) (void | errno) = {
	let res = libc_fstatat(dirfd, cpath(path)?, stat, flag);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("mkdirat") fn libc_mkdirat(fd: int, path: *const u8, mode: mode_t) int;

export fn mkdirat(dirfd: int, path: path, mode: mode_t) (void | errno) = {
	let res = libc_mkdirat(dirfd, cpath(path)?, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("fchmodat") fn libc_fchmodat(
	fd: int,
	path: *const u8,
	mode: mode_t,
	flag: int
) int;

export fn fchmodat(
	dirfd: int,
	path: path,
	mode: mode_t,
	flag: int
) (void | errno) = {
	let res = libc_fchmodat(dirfd, cpath(path)?, mode, flag);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("fchmod") fn libc_fchmod(
	fd: int,
	mode: uint
) int;

export fn fchmod(fd: int, mode: uint) (void | errno) = {
	let res = libc_fchmod(fd, mode);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("fchownat") fn libc_fchownat(
	fd: int,
	path: *const u8,
	owner: uid_t,
	group: gid_t,
	flag: int
) int;

export fn fchownat(
	dirfd: int,
	path: path,
	uid: uid_t,
	gid: gid_t,
	flag: int
) (void | errno) = {
	let res = libc_fchownat(dirfd, cpath(path)?, uid, gid, flag);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("fchown") fn libc_fchown(
	fd: int,
	owner: uid_t,
	group: gid_t
) int;

export fn fchown(fd: int, uid: uid_t, gid: gid_t) (void | errno) = {
	let res = libc_fchown(fd, uid, gid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("linkat") fn libc_linkat(
	fd1: int,
	name1: *const u8,
	fd2: int,
	name2: *const u8,
	flag: int
) int;

export fn linkat(
	olddirfd: int,
	oldpath: path,
	newdirfd: int,
	newpath: path,
	flags: int,
) (void | errno) = {
	let oldpath = cpath(oldpath)?;
	let newpath = copy_cpath(newpath, pathbuf1)?;

	let res = libc_linkat(olddirfd, oldpath, newdirfd, newpath, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("utimensat") fn libc_utimensat(
	fd: int,
	path: *const u8,
	times: *const [2]timespec,
	flag: int
) int;

export fn utimensat(
	dirfd: int,
	path: str,
	ts: *[2]timespec,
	flags: int
) (void | errno) = {
	let res = libc_utimensat(dirfd, cpath(path)?, ts, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("futimens") fn libc_futimens(
	fd: int,
	times: *const [2]timespec
) int;

export fn futimens(fd: int, ts: *[2]timespec) (void | errno) = {
	let res = libc_futimens(fd, ts);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("symlinkat") fn libc_symlinkat(
	name1: *const u8,
	fd: int,
	name2: *const u8
) int;

export fn symlinkat(
	target: path,
	newdirfd: int,
	linkpath: path,
) (void | errno) = {
	let target = cpath(target)?;
	let linkpath = copy_cpath(linkpath, pathbuf1)?;

	let res = libc_symlinkat(target, newdirfd, linkpath);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("renameat") fn libc_renameat(
	fromfd: int,
	from: *const u8,
	tofd: int,
	to: *const u8
) int;

export fn renameat(
	olddirfd: int,
	oldpath: str,
	newdirfd: int,
	newpath: str,
) (void | errno) = {
	let newpath = copy_cpath(newpath, pathbuf1)?;

	let res = libc_renameat(olddirfd, cpath(oldpath)?, newdirfd,
			newpath);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("getcwd") fn libc_getcwd(buf: *u8, bufsz: size) *u8;

export fn getcwd() (*const u8 | errno) = {
	static let pathbuf: [PATH_MAX]u8 = [0...];

	let res = libc_getcwd(&pathbuf: *u8, len(pathbuf));
	if (res == null) {
		return *__errno(): errno;
	};

	return res;
};

@symbol("access") fn libc_access(path: *const u8, amode: int) int;

export fn access(path: path, amode: int) (bool | errno) = {
	let res = libc_access(cpath(path)?, amode);
	if (res == -1) {
		let err = *__errno(): errno;

		switch (res) {
		case EACCES =>
			return false;
		case =>
			return err;
		};
	};

	return true;
};

@symbol("chdir") fn libc_chdir(path: *const u8) int;

export fn chdir(path: path) (void | errno) = {
	let res = libc_chdir(cpath(path)?);

	if (res == -1)  {
		return *__errno(): errno;
	};
};

@symbol("fchdir") fn libc_fchdir(fd: int) int;

export fn fchdir(fd: int) (void | errno) = {
	let res = libc_fchdir(fd);

	if (res == -1)  {
		return *__errno(): errno;
	};
};

@symbol("chroot") fn libc_chroot(dirname: *const u8) int;

export fn chroot(path: path) (void | errno) = {
	let res = libc_chroot(cpath(path)?);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("fork") fn libc_fork() int;

export fn fork() (int | void | errno) = {
	let res = libc_fork();
	if (res == -1) {
		return *__errno(): errno;
	};
	if (res == 0) {
		return;
	};
	return res;
};

@symbol("execve") fn libc_execve(path: *const u8, argv: *[*]nullable *const u8,
		envp: *[*]nullable *const u8) int;

export fn execve(path: path, argv: *[*]nullable *const u8,
		envp: *[*]nullable *const u8) errno = {
	let res = libc_execve(cpath(path)?, argv, envp);
	return *__errno(): errno;
};

export @symbol("getuid") fn getuid() uid_t;
export @symbol("geteuid") fn geteuid() uid_t;
export @symbol("getgid") fn getgid() gid_t;
export @symbol("getegid") fn getegid() gid_t;
export @symbol("getpid") fn getpid() pid_t;
export @symbol("getppid") fn getppid() pid_t;

@symbol("getsid") fn libc_getsid(pid: pid_t) pid_t;

export fn getsid(pid: pid_t) (pid_t | errno) = {
	let res = libc_getsid(pid);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

@symbol("getpgid") fn libc_getpgid(pid: pid_t) pid_t;

export fn getpgid(pid: pid_t) (pid_t | errno) = {
	let res = libc_getpgid(pid);
	if (res == -1) {
		return *__errno(): errno;
	};

	return res;
};

@symbol("setuid") fn libc_setuid(uid: uid_t) int;

export fn setuid(uid: uid_t) (void | errno) = {
	let res = libc_setuid(uid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("setgid") fn libc_setgid(gid: gid_t) int;

export fn setgid(gid: gid_t) (void | errno) = {
	let res = libc_setgid(gid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("seteuid") fn libc_seteuid(uid: uid_t) int;

export fn seteuid(uid: uid_t) (void | errno) = {
	let res = libc_seteuid(uid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("setegid") fn libc_setegid(gid: gid_t) int;

export fn setegid(gid: gid_t) (void | errno) = {
	let res = libc_setegid(gid);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("setpgid") fn libc_setpgid(pid: pid_t, pgrp: pid_t) int;

export fn setpgid(pid: pid_t, pgrp: pid_t) (void | errno) = {
	let res = libc_setpgid(pid, pgrp);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("setsid") fn libc_setsid() pid_t;

export fn setsid() (void | errno) = {
	let res = libc_setsid();
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("pipe2") fn libc_pipe2(pipefd: *[2]int, flags: int) int;

export fn pipe2(pipefd: *[2]int, flags: int) (void | errno) = {
	let res = libc_pipe2(pipefd, flags);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("getrlimit") fn libc_getrlimit(
	resource: int,
	rlp: *rlimit,
) int;

export fn getrlimit(resource: int, rlp: *rlimit) (void | errno) = {
	let res = libc_getrlimit(resource, rlp);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("setrlimit") fn libc_setrlimit(
	resource: int,
	rlp: const *rlimit,
) int;

export fn setrlimit(resource: int, rlp: const *rlimit) (void | errno) = {
	let res = libc_setrlimit(resource, rlp);
	if (res == -1) {
		return *__errno(): errno;
	};
};

@symbol("umask") fn libc_umask(numask: mode_t) mode_t;

export fn umask(mode: mode_t) (mode_t | errno) = {
	// Always successful on Sortix.
	return libc_umask(mode);
};
