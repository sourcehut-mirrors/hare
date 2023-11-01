// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use format::elf;
use format::elf::{at};
use io;
use os;
use rt::sys;
use rt;
use strings;
use fmt;

export type platform_cmd = io::file;

// Forks the current process, returning the [[process]] of the child (to the
// parent), and void (to the child), or an error.
export fn fork() (process | void | error) = {
	let child: rt::cap = ~0;
	const pid = sys::process_fork(rt::self, &child);
	if (pid == 0) {
		return;
	};

	let wait: rt::cap = 0;
	sys::process_wait(child, &wait);
	sys::process_start(child);

	return process {
		proc = child,
		wait = wait,
	};
};

// Creates an anonymous pipe for use with [[addfile]]. Any data written to the
// second file may be read from the first file. The caller should close one or
// both of the file descriptors after they have transferred them to another
// process, and after they have finished using them themselves, if applicable.
//
// To capture the standard output of a process:
//
// 	let pipe = exec::pipe();
// 	exec::addfile(&cmd, os::stdout_file, pipe.1);
// 	let proc = exec::start(&cmd)!;
// 	io::close(pipe.1)!;
//
// 	let data = io::drain(pipe.0)!;
// 	io::close(pipe.0)!;
// 	exec::wait(&proc)!;
//
// To write to the standard input of a process:
//
// 	let pipe = exec::pipe();
// 	exec::addfile(&cmd, os::stdin_file, pipe.0);
// 	let proc = exec::start(&cmd)!;
//
// 	io::writeall(data)!;
// 	io::close(pipe.1)!;
// 	io::close(pipe.0)!;
// 	exec::wait(&proc)!;
export fn pipe() (io::file, io::file) = {
	assert(pipeserv != ~0);
	let rd: rt::cap = ~0, wr: rt::cap = ~0;
	sys::pipeserv_pipe(pipeserv, &rd, &wr);
	return (rd, wr);
};

fn open(path: str) (platform_cmd | error) = os::open(path)?;

fn platform_finish(cmd: *command) void = io::close(cmd.platform)!;

fn platform_exec(cmd: *command) error = {
	assert(len(cmd.files) == 0); // TODO
	const (page, base) = prepare_argv(cmd.argv);
	sys::process_load(rt::self, cmd.platform, [page], base);
	abort(); // Unreachable
};

fn platform_start(cmd: *command) (process | errors::error) = {
	assert(procmgr != ~0);

	let proc: rt::cap = 0;
	sys::procmgr_new(procmgr, &proc);

	const (page, base) = prepare_argv(cmd.argv);
	defer rt::pool_release(base);
	sys::process_load(proc, cmd.platform, [page], base);

	// TODO: Figure out how to deal with CLOEXEC et al for Gaia.
	let stdfiles = 0b111u;
	for (let i = 0z; i < len(cmd.files); i += 1) {
		const to = cmd.files[i].1;
		if (to < 3) {
			stdfiles &= ~(1 << to);
		};
		const from = match (cmd.files[i].0) {
		case let file: io::file =>
			yield file;
		case nullfd =>
			return errors::unsupported; // TODO
		case closefd =>
			continue;
		};
		sys::process_refat(proc, from, to);
	};

	// Install standard files
	for (let i = 0u; i < 3; i += 1) {
		if (stdfiles & (1 << i) != 0) {
			sys::process_refat(proc, i, i);
		};
	};

	// TODO: Install services as well

	let wait: rt::cap = 0;
	sys::process_wait(proc, &wait);
	sys::process_start(proc);

	return process {
		proc = proc,
		wait = wait,
	};
};

let procmgr: rt::cap = ~0;
let pipeserv: rt::cap = ~0;

@init fn init() void = {
	match (rt::try_service(sys::PROCMGR_ID)) {
	case let cap: rt::cap =>
		procmgr = cap;
	case void =>
		yield;
	};

	match (rt::try_service(sys::PIPESERV_ID)) {
	case let cap: rt::cap =>
		pipeserv = cap;
	case void =>
		yield;
	};
};

fn prepare_argv(args: []str) (rt::cap, uintptr) = {
	const (page, base) = rt::pool_acquire();
	let vec = base: *[*]u8;

	let narg = &vec[0]: *size;
	*narg = len(args);

	let offs = size(size);
	for (let i = 0z; i < len(args); i += 1) {
		const arg = args[i];
		let argln = &vec[offs]: *size;
		*argln = len(arg);
		offs += size(size);

		let argbuf = vec[offs..offs+len(arg)];
		argbuf[..] = strings::toutf8(arg);
		offs += len(arg);
	};

	return (page, &vec[0]: uintptr);
};
