// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

fn rdtsc() u64;

fn monotime() instant = {
	const now = rdtsc();
	const sec = now / rt::clktck;
	const remain = now % rt::clktck;
	const nsec = 10e11 / rt::clktck * remain / 10e2;
	return instant {
		sec = sec: i64,
		nsec = nsec: i64,
	};
};
