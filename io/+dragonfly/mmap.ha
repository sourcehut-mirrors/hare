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
};

// Values for the [[mmap]] flags parameter. Only the SHARED, PRIVATE, and FIXED
// values are portable.
export type mflag = enum uint {
	SHARED = sys::MAP_SHARED,
	PRIVATE = sys::MAP_PRIVATE,
	FIXED = sys::MAP_FIXED,
	HASSEMAPHORE = sys::MAP_HASSEMAPHORE ,
	STACK = sys::MAP_STACK,
	NOSYNC = sys::MAP_NOSYNC,
	FILE = sys::MAP_FILE,
	ANON = sys::MAP_ANON,
	NOCORE = sys::MAP_NOCORE,
	_32BIT = sys::MAP_32BIT,
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
