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
export fn getuid() uid = sys::getuid();

// Returns the current process effective user ID.
export fn geteuid() uid = sys::geteuid();

// Returns the current process group ID.
export fn getgid() uid = sys::getgid();

// Returns the current process effective group ID.
export fn getegid() uid = sys::getegid();

// Sets the caller's user ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]] yourself,
// and take extreme care to handle errors correctly.
export fn setuid(uid: uid) void = sys::setuid(uid)!;

// Sets the caller's effective user ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from seteuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]] yourself,
// and take extreme care to handle errors correctly.
export fn seteuid(uid: uid) void = sys::seteuid(uid)!;

// Sets the caller's group ID to the specified value. This generally requires
// elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setuid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]] yourself,
// and take extreme care to handle errors correctly.
export fn setgid(gid: gid) void = sys::setgid(gid)!;

// Sets the caller's effective group ID to the specified value. This generally
// requires elevated permissions from the calling process.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setegid is a grave security issue in your program, and
// therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[sys::]] yourself,
// and take extreme care to handle errors correctly.
export fn setegid(gid: gid) void = sys::setegid(gid)!;

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

// Returns the process group associated with the given pid.
export fn getpgid(pid: pid) (pid | errors::noentry) = {
	match (sys::getpgid(pid)) {
	case let pid: sys::pid_t =>
		return pid;
	case let err: sys::errno =>
		assert(err == sys::ESRCH, "Unexpected getpgid return value");
		return errors::noentry;
	};
};

// Sets the process group ID of the specified process. This function is
// error-prone; see the notes in the POSIX specification for its many caveats.
export fn setpgid(targ: pid, pgid: pid) (void | errors::error) = {
	match (sys::setpgid(targ, pgid)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void =>
		return;
	};
};

// Returns the current process's session ID.
export fn getsid() pid = sys::getsid(0)!;

// Returns the session ID associated with the given process.
export fn getpsid(pid: pid) (pid | errors::noentry | errors::noaccess) = {
	match (sys::getsid(pid)) {
	case let pid: sys::pid_t =>
		return pid;
	case let err: sys::errno =>
		assert(err == sys::ESRCH, "Unexpected getsid return value");
		return errors::noentry;
	};
};

// Creates a new session and sets the current process to the session leader.
// A new process group is also created with its process group ID equal to the
// pid of the current process, and the current process is made the process group
// leader.
//
// Upon return, the new session will have no controlling terminal. To establish
// one, the caller must open a terminal file with [[fs::flag::CTTY]]; this
// opt-in approach differs from the Unix norm where O_NOCTTY is required to
// opt-out of establishing a controlling terminal.
//
// The current process cannot be a process group leader; this is a programmer
// error and will cause a runtime assertion failure.
export fn setsid() void = sys::setsid()!;
