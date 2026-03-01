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
	// Maximum address space size (bytes)
	AS = sys::RLIMIT_AS,

	// Maximum size of resident set (bytes, FreeBSD)
	RSS = sys::RLIMIT_RSS,
	// Maximum amount of data "locked" in RAM (bytes, FreeBSD)
	MEMLOCK = sys::RLIMIT_MEMLOCK,
	// Total processes per user ID (FreeBSD)
	NPROC = sys::RLIMIT_NPROC,
	// Maximum socket buffer size per user ID (FreeBSD)
	SBSIZE = sys::RLIMIT_SBSIZE,
	// Maximum pseudo-terminals per user ID (FreeBSD)
	NPTS = sys::RLIMIT_NPTS,
	// Maximum swap space per user ID (FreeBSD)
	SWAP = sys::RLIMIT_SWAP,
	// Maximum kqueues per user ID (FreeBSD)
	KQUEUES = sys::RLIMIT_KQUEUES,
	// Maximum process-shared POSIX thread library objects per user ID
	// (FreeBSD)
	UMTXP = sys::RLIMIT_UMTXP,
	// Maximum size of kernel pipe/fifo buffers (bytes, FreeBSD)
	PIPEBUF = sys::RLIMIT_PIPEBUF,

	// Alias for [[resource::AS]] (FreeBSD)
	VMEM = AS,
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
