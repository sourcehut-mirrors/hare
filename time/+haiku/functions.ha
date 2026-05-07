// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// Converts a [[duration]] to an [[sys::timespec]]. This function is
// non-portable.
export fn duration_to_timespec(n: duration) sys::timespec = sys::timespec {
	tv_sec = n / SECOND,
	tv_nsec = n % SECOND,
};

// Converts a [[sys::timespec]] to a [[duration]]. This function is non-portable.
export fn timespec_to_duration(spec: sys::timespec) duration = {
	return (spec.tv_sec: i64 * SECOND) + spec.tv_nsec: i64;
};

// Converts a [[duration]] to an [[sys::timeval]]. This function is
// non-portable.
export fn duration_to_timeval(d: duration) sys::timeval = sys::timeval {
	tv_sec = d / SECOND,
	tv_usec = (d % SECOND / 1000): sys::suseconds_t,
};

// Converts an [[instant]] to an [[sys::timespec]]. This function is
// non-portable.
export fn instant_to_timespec(t: instant) sys::timespec = sys::timespec {
	tv_sec = t.sec,
	tv_nsec = t.nsec,
};

// Converts a [[sys::timespec]] to an [[instant]]. This function is
// non-portable.
export fn timespec_to_instant(ts: sys::timespec) instant = instant {
	sec = ts.tv_sec,
	nsec = ts.tv_nsec,
};

// Yields the process to the kernel and returns after the requested duration.
export fn sleep(d: duration) void = {
	let req = duration_to_timespec(d);

	for (true) {
		let res = sys::timespec { ... };
		match (sys::nanosleep(&req, &res)) {
		case void =>
			return;
		case let err: sys::errno =>
			switch (err) {
			case sys::EINTR =>
				req = res;
			case =>
				abort("Unexpected error from nanosleep");
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
	REALTIME = sys::CLOCK_REALTIME,

	// The current monotonic time. This clock measures from some undefined
	// epoch and is not affected by leap seconds, NTP adjustments, and
	// changes to the system time: it always increases by one second per
	// second.
	MONOTONIC = sys::CLOCK_MONOTONIC,

	// The process CPU clock. It begins at zero and is advanced while the
	// calling process is running in user or kernel mode.
	PROCESS_CPU = sys::CLOCK_PROCESS_CPUTIME_ID,

	// The thread CPU clock. It begins at zero and is advanced while the
	// calling thread is running in user or kernel mode.
	THREAD_CPU = sys::CLOCK_THREAD_CPUTIME_ID,
};

// Returns the current time for a given clock.
export fn now(clock: clock) instant = {
	let ts = sys::timespec { ... };
	match (sys::clock_gettime(clock, &ts)) {
	case void =>
		return timespec_to_instant(ts);
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
