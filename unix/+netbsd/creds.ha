// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
// Unix credentials types & functions; ref credentials(7)

use errors;
use sys;

// Process ID.
export type pid = sys::pid_t;

// User ID.
export type uid = sys::uid_t;

// Group ID.
export type gid = sys::gid_t;

// Returns the current process user ID.
export fn getuid() uid = sys::getuid() as sys::uid_t: uid;

// Returns the current process effective user ID.
export fn geteuid() uid = sys::geteuid() as sys::uid_t: uid;

// Returns the current process group ID.
export fn getgid() gid = sys::getgid() as sys::gid_t: gid;

// Returns the current process effective group ID.
export fn getegid() gid = sys::getegid() as sys::gid_t: gid;

// Sets the caller's user ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]]
// yourself, and take extreme care to handle errors correctly.
export fn setuid(uid: uid) void = sys::setuid(&uid)!;

// Sets the caller's effective user ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from seteuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]]
// yourself, and take extreme care to handle errors correctly.
export fn seteuid(euid: uid) void = sys::seteuid(&euid)!;

// Sets the caller's group ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]]
// yourself, and take extreme care to handle errors correctly.
export fn setgid(gid: gid) void = sys::setgid(&gid)!;

// Sets the caller's effective group ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setegid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]]
// yourself, and take extreme care to handle errors correctly.
export fn setegid(egid: gid) void = sys::setegid(&egid)!;

// Returns a list of supplementary group IDs for the current process. The
// returned slice is statically allocated.
export fn getgroups() []gid = {
	static let gids: [sys::NGROUPS_MAX]sys::gid_t = [0...];
	const n = sys::getgroups(gids)!;
	return gids[..n]: []gid;
};

// Sets the list of supplementary group IDs which apply to the current process.
// This generally requires elevated permissions.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setgroups is a grave security issue in your program,
// and therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]]
// yourself, and take extreme care to handle errors correctly.
export fn setgroups(gids: []gid) void = sys::setgroups(gids: []sys::gid_t)!;

// Returns the current process ID.
export fn getpid() pid = sys::getpid();

// Returns the parent process ID.
export fn getppid() pid = sys::getppid();

// Returns the current process group ID.
export fn getpgrp() pid = sys::getpgrp();

// Returns the current process's session ID.
export fn getsid() pid = sys::getsid(0)!;

// Returns the session ID associated with the given process.
export fn getpsid(pid: pid) (pid | errors::noentry | errors::noaccess) = {
	match (sys::getsid(pid)) {
	case let pid: sys::pid_t =>
		return pid;
	case let err: sys::errno =>
		assert(err == sys::ESRCH);
		return errors::noentry;
	};
};
