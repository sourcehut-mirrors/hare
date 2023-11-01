// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Stores information about a child process.
// TODO +gaia: It might be nice to change how sys::wait works and just store an
// rt::cap here instead of a struct, particularly if we want to wait on many
// processes for instance.
export type process = struct {
	proc: rt::cap,
	wait: rt::cap,
};

// Stores information about an exited process.
export type status = int;

// Returns the currently running [[process]].
export fn self() process = process {
	proc = rt::self,
	wait = ~0,
};

// Waits for a process to complete.
export fn wait(proc: *process) (status | error) = {
	rt::wait(proc.wait)!;
	proc_finish(proc);
	// TODO: Implement exit status in Mercury
	return 0;
};

fn proc_finish(proc: *process) void = {
	// TODO +gaia: This leaks, figure out how to clean it up, probably with
	// (meta::refcount?)
	void;
};
