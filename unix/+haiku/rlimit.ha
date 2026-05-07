// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// A resource limit.
export type limit = sys::rlim_t;

// A [[limit]] representing an unlimited value.
export def INFINITY: limit = sys::RLIM_INFINITY;

// Resources with limited or limitable usage constraints.
export type resource = enum int {
	// Maximum size of a core dump (bytes)
	CORE = sys::RLIMIT_CORE,
	// Maximum CPU time (seconds)
	CPU = sys::RLIMIT_CPU,
	// Maximum size of data segment (bytes)
	DATA = sys::RLIMIT_DATA,
	// Maximum size of files (bytes)
	FSIZE = sys::RLIMIT_FSIZE,
	// Maximum number of open files
	NOFILE = sys::RLIMIT_NOFILE,
	// Maximum size of stack(s) (bytes)
	STACK = sys::RLIMIT_STACK,
	// Maximum number of open files
	AS = sys::RLIMIT_AS,

	// Number of open vnode monitors (Haiku)
	NOVMON = sys::RLIMIT_NOVMON,
};

// Soft and hard limits for a [[resource]].
export type rlimit = struct {
	soft: limit,
	hard: limit,
};

// Returns the current limits for a [[resource]].
export fn getrlimit(res: resource) rlimit = {
	let rlim = sys::rlimit { ... };
	sys::getrlimit(res, &rlim)!;
	return rlimit {
		soft = rlim.rlim_cur,
		hard = rlim.rlim_max,
	};
};

// Modifies a [[resource]] limit.
export fn setrlimit(res: resource, limit: *rlimit) (void | errors::error) = {
	let rlim = sys::rlimit {
		rlim_cur = limit.soft,
		rlim_max = limit.hard,
	};
	match (sys::setrlimit(res, &rlim)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};
