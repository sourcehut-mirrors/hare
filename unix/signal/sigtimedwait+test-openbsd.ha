// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// XXX: sigtimedwait is not yet available in OpenBSD. Quoting
// from OpenBSD's lib/libc/gen/sigwait.c: "need kernel to fill in more siginfo_t
// bits first"

use errors;
use time;


let handled = false;

fn handle_signal_usr2(
	_sig: sig,
	info: *siginfo,
	ucontext: *opaque
) void = {
	handled = true;
};

@test fn test_timedwait() void = {
	test::require("integration");

	handle(sig::USR2, &handle_signal_usr2);
	const set = newsigset(sig::USR2);
	match (timedwait(&set, time::MILLISECOND)) {
	case let si: siginfo => abort("Unexpected signal");
	case let err: errors::interrupted => abort("Unexpected interruption");
	case let err: errors::again => void;
	};

	assert(!handled);
};
