// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// A resource limit.
export type limit = sys::rlim_t;

// A [[limit]] representing an unlimited value.
export def INFINITY: limit = sys::RLIM_INFINITY;

// Resources with limited or limitable usage constraints.
//
// Note that OpenBSD does not support the POSIX-standard AS (aka VMEM) limit.
export type resource = enum int {
	// Maximum CPU time (seconds)
	CPU = sys::RLIMIT_CPU,
	// Maximum size of files (bytes)
	FSIZE = sys::RLIMIT_FSIZE,
	// Maximum size of data segment (bytes)
	DATA = sys::RLIMIT_DATA,
	// Maximum size of stack(s) (bytes)
	STACK = sys::RLIMIT_STACK,
	// Maximum size of a core dump (bytes)
	CORE = sys::RLIMIT_CORE,
	// Maximum number of open files
	NOFILE = sys::RLIMIT_NOFILE,

	// Total processes per user ID (Linux)
	NPROC = sys::RLIMIT_NPROC,
	// Maximum size of resident set (bytes, Linux)
	RSS = sys::RLIMIT_RSS,
	// Maximum amount of data "locked" in RAM (bytes, Linux)
	MEMLOCK = sys::RLIMIT_MEMLOCK,
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
