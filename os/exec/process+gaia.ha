// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use os;
use rt;
use rt::sys;

// Stores information about a child process.
// TODO +gaia: It might be nice to change how sys::wait works and just store an
// rt::cap here instead of a struct, particularly if we want to wait on many
// processes for instance.
export type process = struct {
	proc: rt::cap,
	wait: rt::cap,
};

// Stores information about an exited process.
export type status = struct {
	status: int,
};

// The exit status code of a process.
export type exited = int;

// The exit status of a process.
export type exit_status = exited;

// Returns the currently running [[process]].
export fn self() process = process {
	proc = rt::self,
	wait = ~0,
};

// Waits for a process to complete.
export fn wait(proc: *process) (status | error) = {
	const st = rt::wait(proc.wait)!;
	proc_finish(proc);
	return status {
		status = st: int,
	};
};

// Checks for process completion, returning its status information on
// completion, or void if it is still running.
export fn peek(proc: *process) (status | void | error) = {
	match (rt::nbwait(proc.wait)) {
	case let u: uint =>
		proc_finish(proc);
		return status {
			status = u: int,
		};
	case rt::would_block =>
		return;
	case let err: rt::syserror =>
		abort(); // Should not be possible
	};
};

fn proc_finish(proc: *process) void = {
	// TODO +gaia: This leaks, figure out how to clean it up, probably with
	// (meta::refcount?)
	void;
};

// Returns a human friendly string describing the exit status. The string is
// statically allocated; use [[strings::dup]] to extend its lifetime.
export fn exitstr(status: exit_status) const str = {
	static let buf: [1024]u8 = [0...];
	switch (status) {
	case 0 =>
		return "exited normally";
	case =>
		return fmt::bsprintf(buf, "exited with status {}",
			status: int);
	};
};

// Returns the exit status of a completed process.
export fn exit(stat: *status) exit_status = {
	return stat.status: exit_status;
};

// Checks the exit status of a completed process, returning void if successful,
// or its status code as an error type if not.
export fn check(stat: *status) (void | !exit_status) = {
	if (stat.status == os::status::SUCCESS) {
		return;
	};
	return exit(stat);
};

// Forcibly terminates a process.
export fn kill(proc: *process) void = {
	sys::process_kill(proc.proc);
	proc_finish(proc);
};
