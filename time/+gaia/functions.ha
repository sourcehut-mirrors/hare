// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use rt::dev;

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
};

// Returns after the requested duration.
export fn sleep(d: duration) void = {
	// TODO: This should be replaced with a system-provided sleep function
	const deadline = add(now(clock::MONOTONIC), d);
	for (true) {
		const now = now(clock::MONOTONIC);
		if (compare(now, deadline) == 1) {
			break;
		};
		rt::yieldtask();
	};
};

// Returns the current time for a given clock.
export fn now(clock: clock) instant = {
	switch (clock) {
	case clock::REALTIME =>
		const rtc = rt::service(dev::CLOCK_ID);
		const unix = dev::clock_get_time(rtc);
		return from_unix(unix);
	case clock::MONOTONIC =>
		return monotime();
	};
};
