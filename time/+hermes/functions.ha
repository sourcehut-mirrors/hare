// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use format::elf;
use rt;
use sys;

fn read_ticks() u64;

let clock_rate = 0u64;

@init fn init() void = {
	for (let i = 0z; rt::auxv[i].a_type != elf::at::NULL; i += 1) {
		const aux = &rt::auxv[i];
		switch (aux.a_type) {
		case elf::at::CLKTCK =>
			clock_rate = aux.a_val;
		case => void;
		};
	};
};

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
	// TODO: There will be better ways to sleep in the future
	let deadline = add(now(c), d);
	for (compare(now(c), deadline) < 0) {
		sys::schedule();
	};
};

// Yields the process to the kernel and returns when [[clock]] c reaches
// [[instant]] i.
export fn sleep_until(i: instant, c: clock = clock::MONOTONIC) void = {
	// TODO: There will be better ways to sleep in the future
	for (compare(now(c), i) < 0) {
		sys::schedule();
	};
};

// Returns the current time for a given clock.
export fn now(clock: clock) instant = {
	// TODO: Implement different clocks
	const now = read_ticks();
	const sec = now / clock_rate;
	const remain = now % clock_rate;
	const nsec = 10e11 / clock_rate * remain / 10e2;
	return instant {
		sec = sec: i64,
		nsec = nsec: i64,
	};
};

// Sets system clock to given time.
export fn set(clock: clock, t: instant) (void | errors::noaccess) = {
	abort("TODO: Hermes");
};
