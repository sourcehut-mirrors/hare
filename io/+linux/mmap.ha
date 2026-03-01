// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// Values for the [[mmap]] prot parameter. Only the EXEC, READ, WRITE, and NONE
// values are portable.
export type prot = enum uint {
	NONE = sys::PROT_NONE,
	READ = sys::PROT_READ,
	WRITE = sys::PROT_WRITE,
	EXEC = sys::PROT_EXEC,
	GROWSDOWN = sys::PROT_GROWSDOWN,
	GROWSUP = sys::PROT_GROWSUP,
};

// Values for the [[mmap]] flags parameter. Only the SHARED, PRIVATE, and FIXED
// values are portable.
export type mflag = enum uint {
	SHARED = sys::MAP_SHARED,
	PRIVATE = sys::MAP_PRIVATE,
	SHARED_VALIDATE = sys::MAP_SHARED_VALIDATE,
	FIXED = sys::MAP_FIXED,
	ANON = sys::MAP_ANON,
	NORESERVE = sys::MAP_NORESERVE,
	GROWSDOWN = sys::MAP_GROWSDOWN,
	DENYWRITE = sys::MAP_DENYWRITE,
	EXECUTABLE = sys::MAP_EXECUTABLE,
	LOCKED = sys::MAP_LOCKED,
	POPULATE = sys::MAP_POPULATE,
	NONBLOCK = sys::MAP_NONBLOCK,
	STACK = sys::MAP_STACK,
	HUGETLB = sys::MAP_HUGETLB,
	SYNC = sys::MAP_SYNC,
	FIXED_NOREPLACE = sys::MAP_FIXED_NOREPLACE,
	FILE = sys::MAP_FILE,
	HUGE_SHIFT = sys::MAP_HUGE_SHIFT,
	HUGE_MASK = sys::MAP_HUGE_MASK,
	HUGE_64KB = sys::MAP_HUGE_64KB,
	HUGE_512KB = sys::MAP_HUGE_512KB,
	HUGE_1MB = sys::MAP_HUGE_1MB,
	HUGE_2MB = sys::MAP_HUGE_2MB,
	HUGE_8MB = sys::MAP_HUGE_8MB,
	HUGE_16MB = sys::MAP_HUGE_16MB,
	HUGE_32MB = sys::MAP_HUGE_32MB,
	HUGE_256MB = sys::MAP_HUGE_256MB,
	HUGE_512MB = sys::MAP_HUGE_512MB,
	HUGE_1GB = sys::MAP_HUGE_1GB,
	HUGE_2GB = sys::MAP_HUGE_2GB,
	HUGE_16GB = sys::MAP_HUGE_16GB,
};

// Performs the mmap syscall. Consult your system for documentation on this
// function.
export fn mmap(
	addr: nullable *opaque,
	length: size,
	prot: prot,
	flags: mflag,
	fd: file,
	offs: size
) (*opaque | errors::error) = {
	match (sys::mmap(addr, length, prot, flags, fd, offs)) {
	case let ptr: *opaque =>
		return ptr;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Unmaps memory previously mapped with [[mmap]].
export fn munmap(addr: *opaque, length: size) (void | errors::error) = {
	match (sys::munmap(addr, length)) {
	case void =>
		return;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};
