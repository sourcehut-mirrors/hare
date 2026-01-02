// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;

// An enumeration of clocks available on this system. Different clocks represent
// times from different epochs, and have different characteristics with regards
// to leap seconds, NTP adjustments, and so on. All systems provide the REALTIME
// and MONOTONIC clocks at least; use of other clocks is not guaranteed to be
// portable.
export type clock = enum {
	// The current monotonic time. This clock measures from some undefined
	// epoch and is not affected by leap seconds, NTP adjustments, and
	// changes to the system time: it always increases by one second per
	// second.
	MONOTONIC = 0,

	// The current wall-clock time. This may jump forwards or backwards in
	// time to account for leap seconds, NTP adjustments, etc.
	REALTIME = 1,
};

// Yields the process to the kernel and returns after the requested duration.
export fn sleep(d: duration, c: clock = clock::MONOTONIC) void = {
	abort("TODO: Hermes");
};

// Yields the process to the kernel and returns when [[clock]] c reaches [[instant]] i.
export fn sleep_until(i: instant, c: clock = clock::MONOTONIC) void = {
	abort("TODO: Hermes");
};

// Returns the current time for a given clock.
export fn now(clock: clock) instant = {
	abort("TODO: Hermes");
};

// Sets system clock to given time.
export fn set(clock: clock, t: instant) (void | errors::noaccess) = {
	abort("TODO: Hermes");
};
