// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>


// /include/errno.h: #define errno (*libk_get_errno_location())
@symbol("libk_get_errno_location") fn __errno() *int;

// exit
export @symbol("exit") fn exit(status: int) never;

// read

@symbol("read") fn libc_read(d: int, buf: *opaque, nbytes: size) size;

export fn read(fd: int, buf: *opaque, count: size) (size | errno) = {
	let res: u64 = libc_read(fd, buf, count);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// write

@symbol("write") fn libc_write(d: int, buf: *const opaque, nbytes: size) size;

export fn write(fd: int, buf: *const opaque, count: size) (size | errno) = {
	let res: u64 = libc_write(fd, buf, count);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// close

@symbol("close") fn libc_close(d: int) int;

export fn close(fd: int) (void | errno) = {
	let res = libc_close(fd);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// lseek

@symbol("lseek") fn libc_lseek(fildes: int, pos: i64, whence: int) i64;

export fn lseek(fd: int, off: i64, whence: int) (i64 | errno) = {
	let res = libc_lseek(fd, off, whence);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

// ftruncate

@symbol("ftruncate") fn libc_ftruncate(fd: int, length: i64) int;

export fn ftruncate(fd: int, length: i64) (void | errno) = {
	let res = libc_ftruncate(fd, length);
	if (res == -1) {
		return *__errno(): errno;
	};
};

// nanosleep

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

// clock_gettime
// clock_settime

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
