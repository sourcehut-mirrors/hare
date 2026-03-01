// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use linux::vdso;
use sys;

// Converts a [[duration]] to an [[sys::timespec]]. This function is
// non-portable.
export fn duration_to_timespec(d: duration) sys::timespec = sys::timespec {
	tv_sec = d / SECOND,
	tv_nsec = d % SECOND,
};

// Converts a [[sys::timespec]] to a [[duration]]. This function is non-portable.
export fn timespec_to_duration(spec: sys::timespec) duration = {
	return (spec.tv_sec: i64 * SECOND) + spec.tv_nsec: i64;
};

// Converts a [[duration]] to an [[sys::timeval]]. This function is
// non-portable.
export fn duration_to_timeval(d: duration) sys::timeval = sys::timeval {
	tv_sec = d / SECOND,
	tv_usec = d % SECOND / 1000,
};

// Converts an [[instant]] to an [[sys::timespec]]. This function is
// non-portable.
export fn instant_to_timespec(t: instant) sys::timespec = sys::timespec {
	tv_sec = t.sec,
	tv_nsec = t.nsec,
};

// Converts a [[sys::timespec]] to an [[instant]]. This function is non-portable.
export fn timespec_to_instant(ts: sys::timespec) instant = instant {
	sec = ts.tv_sec,
	nsec = ts.tv_nsec,
};

// Yields the process to the kernel and returns after the requested duration.
export fn sleep(d: duration, c: clock = clock::MONOTONIC) void = {
	let req = duration_to_timespec(d);

	for (true) {
		let res = sys::timespec { ... };
		match (sys::clock_nanosleep(c: int, 0, &req, &res)) {
		case void =>
			return;
		case let err: sys::errno =>
			switch (err) {
			case sys::EINTR =>
				req = res;
			case =>
				abort("Unexpected error from clock_nanosleep");
			};
		};
	};
};

// Yields the process to the kernel and returns when [[clock]] c reaches [[instant]] i.
export fn sleep_until(i: instant, c: clock = clock::MONOTONIC) void = {
	const requested = instant_to_timespec(i);

	for (true) {
		match (sys::clock_nanosleep(c: int, sys::TIMER_ABSTIME, &requested, null)) {
		case void =>
			return;
		case let err: sys::errno =>
			switch (err) {
			case sys::EINTR =>
				continue;
			case =>
				abort("Unexpected error from clock_nanosleep");
			};
		};
	};
};

// An enumeration of clocks available on this system. Different clocks represent
// times from different epochs, and have different characteristics with regards
// to leap seconds, NTP adjustments, and so on. All systems provide the REALTIME
// and MONOTONIC clocks at least; use of other clocks is not guaranteed to be
// portable.
export type clock = enum {
	// The current wall-clock time. This may jump forwards or backwards in
	// time to account for leap seconds, NTP adjustments, etc.
	REALTIME = 0,

	// The current monotonic time. This clock measures from some undefined
	// epoch and is not affected by leap seconds, NTP adjustments, and
	// changes to the system time: it always increases by one second per
	// second.
	MONOTONIC = 1,

	// Measures CPU time consumed by the calling process.
	PROCESS_CPU = 2,

	// Time since the system was booted. Increases monotonically and, unlike
	// [[MONOTONIC]], continues to tick while the system is suspended.
	BOOT = 7,

	// This clock is like [[REALTIME]], but will wake the system if it is suspended.
	REALTIME_ALARM = 8,
	// This clock is like [[BOOT]], but will wake the system if it is suspended.
	BOOT_ALARM = 9,

	// A system-wide clock derived from wall-clock time but ignoring leap seconds.
	TAI = 11,
};

fn cgt_vdso() nullable *fn(_: int, _: *sys::timespec) int = {
	static let vdso_checked: bool = false;
	static let cgt_vdso: nullable *fn(_: int, _: *sys::timespec) int = null;
	if (vdso_checked) {
		return cgt_vdso;
	};
	vdso_checked = true;
	cgt_vdso = vdso::getsym(VDSO_CGT_SYM, VDSO_CGT_VER):
		nullable *fn(_: int, _: *sys::timespec) int;
	return cgt_vdso;
};

fn now_vdso(clock: clock, tp: *sys::timespec) (void | sys::errno) = {
	const vfn = match (cgt_vdso()) {
	case null =>
		return sys::ENOSYS;
	case let vfn: *fn(_: int, _: *sys::timespec) int =>
		yield vfn;
	};
	const ret = vfn(clock, tp);
	if (ret == 0) {
		return;
	};
	return ret;
};

// Returns the current time for a given clock.
export fn now(clock: clock) instant = {
	let tp = sys::timespec { ... };
	let err = match (now_vdso(clock, &tp)) {
	case void =>
		return timespec_to_instant(tp);
	case let err: sys::errno =>
		yield err;
	};
	if (err != sys::ENOSYS) {
		abort("Unexpected error from clock_gettime");
	};
	match (sys::clock_gettime(clock, &tp)) {
	case void =>
		return timespec_to_instant(tp);
	case let err: sys::errno =>
		abort("Unexpected error from clock_gettime");
	};
};

// Sets system clock to given time.
export fn set(clock: clock, t: instant) (void | errors::noaccess) = {
	let tp = instant_to_timespec(t);
	let err = match (sys::clock_settime(clock, &tp)) {
	case void => return;
	case let err: sys::errno =>
		yield err;
	};
	if (err == sys::EPERM) {
		return errors::noaccess;
	};
	abort("Unexpected error from clock_settime");
};
