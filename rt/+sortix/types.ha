// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type off_t = i64;
export type time_t = i64;
export type suseconds_t = i64;
export type clock_t = i64;
export type clockid_t = i32;
export type uid_t = u64;
export type gid_t = u64;
export type mode_t = uint;
export type ino_t = u64;
export type dev_t = uintptr;
export type nlink_t = uint;
export type blksize_t = i64;
export type blkcnt_t = i64;
export type pid_t = uintptr;
export type rlim_t = u64;
export type id_t = u64;
export type nfds_t = size;

// Maximum length of a file path including the NUL terminator.
//
// Note: Sortix does not define a maximum path length. This is a limitation of
// the Hare standard library.
export def PATH_MAX: size = 4096;

// Maximum length of a file name.
//
// Note: Sortix does not define a maximum filename length. This is a limitation
// of the Hare standard library.
export def NAME_MAX: size = 255;

export type timespec = struct {
	tv_sec: time_t,
	tv_nsec: i64,
};

export type timeval = struct {
	tv_sec: time_t,
	tv_usec: suseconds_t,
};

export def CLOCK_REALTIME: clockid_t = 0;
export def CLOCK_MONOTONIC: clockid_t = 1;
export def CLOCK_BOOTTIME: clockid_t = 2;
export def CLOCK_INIT: clockid_t = 3;
export def CLOCK_PROCESS_CPUTIME_ID: clockid_t = 4;
export def CLOCK_PROCESS_SYSTIME_ID: clockid_t = 5;
export def CLOCK_CHILD_CPUTIME_ID: clockid_t = 6;
export def CLOCK_CHILD_SYSTIME_ID: clockid_t = 7;
export def CLOCK_THREAD_CPUTIME_ID: clockid_t = 8;
export def CLOCK_THREAD_SYSTIME_ID: clockid_t = 9;

export def _UTSNAME_LENGTH = 65z;

export type utsname = struct {
	sysname: [_UTSNAME_LENGTH]u8,
	nodename: [_UTSNAME_LENGTH]u8,
	release: [_UTSNAME_LENGTH]u8,
	version: [_UTSNAME_LENGTH]u8,
	tagline: [_UTSNAME_LENGTH]u8,
	machine: [_UTSNAME_LENGTH]u8,
	processor: [_UTSNAME_LENGTH]u8,
};

export def O_READ = 1<<0;
export def O_WRITE = 1<<1;
export def O_EXEC = 1<<2;
export def O_APPEND = 1<<3;
export def O_CLOEXEC = 1<<4;
export def O_CREATE = 1<<5;
export def O_DIRECTORY = 1<<6;
export def O_EXCL = 1<<7;
export def O_TRUNC = 1<<8;
export def O_CLOFORK = 1<<9;
export def O_SEARCH = 1<<10;
export def O_NONBLOCK = 1<<11;
export def O_NOFOLLOW = 1<<12;
export def O_SYMLINK_NOFOLLOW = 1<<13;
export def O_NOCTTY = 1<<14;
export def O_TTY_INIT = 1<<15;

export type stat = struct {
	st_dev: dev_t,
	st_rdev: dev_t,
	st_ino: ino_t,
	st_mode: mode_t,
	st_nlink: nlink_t,
	st_uid: uid_t,
	st_gid: gid_t,
	st_size: off_t,
	st_atim: timespec,
	st_mtim: timespec,
	st_ctim: timespec,
	st_blksize: blksize_t,
	st_blkcnt: blkcnt_t,
};

export def UTIME_NOW = 0x3FFFFFFF;
export def UTIME_OMIT = 0x3FFFFFFE;

export def R_OK = 4;
export def W_OK = 2;
export def X_OK = 1;
export def F_OK = 0;

export def AT_FDCWD = -100;
export def AT_REMOVEDIR = 1<<0;
export def AT_EACCESS = 1<<1;
export def AT_SYMLINK_NOFOLLOW = 1<<2;
export def AT_REMOVEFILE = 1<<3;
export def AT_SYMLINK_FOLLOW = 1<<4;

export def STDIN_FILENO = 0;
export def STDOUT_FILENO = 1;
export def STDERR_FILENO = 2;

export type rusage = struct {
	ru_utime: timeval,
	ru_stime: timeval,
};

export def RLIM_INFINITY = ~0;
export def RLIM_SAVED_CUR = RLIM_INFINITY;
export def RLIM_SAVED_MAX = RLIM_INFINITY;

export type rlimit = struct {
	rlim_cur: rlim_t,
	rlim_max: rlim_t,
};

export def RLIMIT_AS = 0;
export def RLIMIT_CORE = 1;
export def RLIMIT_CPU = 2;
export def RLIMIT_DATA = 3;
export def RLIMIT_FSIZE = 4;
export def RLIMIT_NOFILE = 5;
export def RLIMIT_STACK = 6;

export def FD_CLOEXEC = (1<<0);
export def FD_CLOFORK = (1<<1);

export def F_TYPE_EXP = 3;
export def F_TYPE_VOID = 0;
export def F_TYPE_INT = 1;
export def F_TYPE_LONG = 2;
export def F_TYPE_PTR = 3;

export def F_SETFD = 0 << F_TYPE_EXP | F_TYPE_INT;
export def F_GETFD = 1 << F_TYPE_EXP | F_TYPE_VOID;
export def F_SETFL = 3 << F_TYPE_EXP | F_TYPE_INT;
export def F_GETFL = 3 << F_TYPE_EXP | F_TYPE_VOID;
export def F_DUPFD = (4 | (0 << 16)) << F_TYPE_EXP | F_TYPE_INT;
export def F_DUPFD_CLOEXEC = (4 | (FD_CLOEXEC << 16)) << F_TYPE_EXP | F_TYPE_INT;
export def F_DUPFD_CLOFORK = (4 | (FD_CLOFORK << 16)) << F_TYPE_EXP | F_TYPE_INT;

export def WCONTINUED = 1<<0;
export def WNOHANG = 1<<1;
export def WUNTRACED = 1<<2;

export fn wtermsig(status: int) int = status & 0x7F;
export fn wexitstatus(status: int) int = (status >> 8) & 0xff;
export fn wifexited(status: int) bool = wtermsig(status) == 0;
export fn wifsignaled(status: int) bool =
	wtermsig(status) != 0o177 && wtermsig(status) != 0;

export type iovec = struct {
	iov_base: nullable *opaque,
	iov_len: size,
};

export def POLLERR = (1<<0);
export def POLLHUP = (1<<1);
export def POLLNVAL = (1<<2);

export def POLLIN = (1<<3);
export def POLLRDNORM = (1<<4);
export def POLLRDBAND = (1<<5);
export def POLLPRI = (1<<6);
export def POLLOUT = (1<<7);
export def POLLWRNORM = (1<<8);
export def POLLWRBAND = (1<<9);

export type pollfd = struct {
	fd: int,
	events: i16,
	revents: i16,
};
