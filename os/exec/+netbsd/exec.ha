// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use os;
use sys;
use types::c;
use unix;

// Forks the current process, returning the [[process]] of the child (to the
// parent) and void (to the child), or an error.
export fn fork() (process | void | error) = {
	match (sys::fork()) {
	case let err: sys::errno  =>
		return errors::errno(err);
	case let i: sys::pid_t =>
		return i: process;
	case void =>
		return void;
	};
};

// Creates an anonymous pipe for use with [[addfile]]. Any data written to the
// second file may be read from the first file. The caller should close one or
// both of the file descriptors after they have transferred them to another
// process, and after they have finished using them themselves, if applicable.
//
// This function will abort the process if the system is unable to allocate the
// resources for a pipe. If you need to handle this error gracefully, you may
// call [[unix::pipe]] yourself, but this may reduce the portability of your
// software.
//
// To capture the standard output of a process:
//
// 	const (read, write) = exec::pipe();
// 	exec::addfile(&cmd, os::stdout_file, write);
// 	let proc = exec::start(&cmd)!;
// 	io::close(write)!;
//
// 	let data = io::drain(read)!;
// 	io::close(read)!;
// 	exec::wait(&proc)!;
//
// To write to the standard input of a process:
//
// 	const (read, write) = exec::pipe();
// 	exec::addfile(&cmd, os::stdin_file, read);
// 	let proc = exec::start(&cmd)!;
// 	io::close(read)!;
//
// 	io::writeall(write, data)!;
// 	io::close(write)!;
// 	exec::wait(&proc)!;
export fn pipe() (io::file, io::file) = {
	return unix::pipe()!;
};

fn open(path: str) (platform_cmd | error) = {
	let fd = match (sys::open(path, sys::O_RDONLY, 0u)) {
	case let fd: int =>
		yield fd;
	case let err: sys::errno =>
		return errors::errno(err);
	};
	let success = false;
	defer if (!success) sys::close(fd)!;
	match (sys::access(path, sys::X_OK)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let b: bool =>
		if (!b) {
			return errors::noaccess;
		};
	};
	// Make sure we are not trying to execute anything weird. fstat()
	// already dereferences symlinks, so if this is anything other than a
	// regular file it cannot be executed.
	let s = sys::st { ... };
	match (sys::fstat(fd, &s)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void =>
		if (s.mode & sys::S_IFREG == 0) {
			return errors::noaccess;
		};
	};
	success = true;
	return fd;

};

fn platform_exec(cmd: *command) error = {
	let need_devnull = false;
	for (let file &.. cmd.files) {
		const from = match (file.0) {
		case let file: io::file =>
			yield file;
		case nullfd =>
			need_devnull = true;
			continue;
		case closefd =>
			continue;
		};

		file.0 = match (sys::fcntl(from, sys::F_DUPFD_CLOEXEC, 0)) {
		case let fd: int =>
			yield fd;
		case let err: sys::errno =>
			return errors::errno(err);
		};
	};

	const devnull: io::file = if (need_devnull) {
		yield os::open("/dev/null", fs::flag::RDWR)!;
	} else -1;

	for (let file .. cmd.files) {
		const from = match (file.0) {
		case let file: io::file =>
			yield file;
		case nullfd =>
			yield devnull;
		case closefd =>
			io::close(file.1)?;
			continue;
		};

		if (file.1 == from) {
			let flags = match (sys::fcntl(from, sys::F_GETFD, 0)) {
			case let flags: int =>
				yield flags;
			case let e: sys::errno =>
				return errors::errno(e);
			};
			sys::fcntl(from, sys::F_SETFD, flags & ~sys::FD_CLOEXEC)!;
		} else {
			match (sys::dup2(from, file.1)) {
			case int => void;
			case let e: sys::errno =>
				return errors::errno(e);
			};
		};
	};

	if (cmd.dir != "") {
		os::chdir(cmd.dir)?;
	};

	let envp: nullable *[*]nullable *const c::char = null;
	if (len(cmd.env) > 1) {
		envp = cmd.env: *[*]nullable *const c::char;
	};

	return errors::errno(sys::fexecve(cmd.platform,
		cmd.argv: *[*]nullable *const u8,
		envp: *[*]nullable *const u8));
};

fn platform_start(cmd: *command) (process | errors::error) = {
	// TODO: Let the user configure clone more to their taste (e.g. SIGCHLD)
	let pipe: [2]int = [0...];
	match (sys::pipe2(&pipe, sys::O_CLOEXEC)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void => void;
	};

	match (sys::fork()) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let pid: sys::pid_t =>
		sys::close(pipe[1])!;
		defer sys::close(pipe[0])!;
		let errno: int = 0;
		match (sys::read(pipe[0], &errno, size(int))) {
		case let err: sys::errno =>
			return errors::errno(err);
		case let n: size =>
			switch (n) {
			case size(int) =>
				return errors::errno(errno);
			case 0 =>
				return pid;
			case =>
				abort("Unexpected sys::read result");
			};
		};
	case void =>
		sys::close(pipe[0])!;
		let err = platform_exec(cmd);
		if (!(err is errors::opaque_)) {
			sys::exit(1);
		};
		let err = err as errors::opaque_;
		let err = &err.data: *sys::errno;
		sys::write(pipe[1], err, size(int))!;
		sys::exit(1);
	};
};
