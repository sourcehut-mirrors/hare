// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type off_t = i64;
export type time_t = i64;
export type suseconds_t = i64;
export type clock_t = i64;
export type clockid_t = i32;

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
