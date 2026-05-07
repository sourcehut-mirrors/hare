// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use io;
use sys;

let stdin_bufio: bufio::stream = @undefined; // overwritten by init_stdfd

let stdout_bufio: bufio::stream = @undefined; // overwritten by init_stdfd

// The standard input. This handle is buffered (i.e. backed by a
// [[bufio::stream]]).
export let stdin: io::handle = sys::STDIN_FILENO; // initialized by init_stdfd

// The standard input, as an [[io::file]]. This handle is unbuffered. Reads from
// this file should not be intermixed with reads from the buffered stream
// [[stdin]].
export let stdin_file: io::file = sys::STDIN_FILENO;

// The standard output. This handle is buffered (i.e. backed by a
// [[bufio::stream]]).
export let stdout: io::handle = sys::STDOUT_FILENO; // initialized by init_stdfd

// The standard output, as an [[io::file]]. This handle is unbuffered. Writes to
// this file should not be intermixed with writes to the buffered stream
// [[stdout]].
export let stdout_file: io::file = sys::STDOUT_FILENO;

// The standard error. This handle is unbuffered.
export let stderr: io::handle = sys::STDERR_FILENO;

// The standard error, as an [[io::file]]. This handle is unbuffered.
export let stderr_file: io::file = sys::STDERR_FILENO;

// The recommended buffer size for reading from disk.
export def BUFSZ: size = 8192; // 8 KiB

@init fn init_stdfd() void = {
	static let stdinbuf: [BUFSZ]u8 = [0...];
	stdin_bufio = bufio::init(stdin_file, stdinbuf, [],
		bufio::flag::MANAGED_HANDLE);
	stdin = &stdin_bufio;

	static let stdoutbuf: [BUFSZ]u8 = [0...];
	stdout_bufio = bufio::init(stdout_file, [], stdoutbuf,
		bufio::flag::MANAGED_HANDLE);
	stdout = &stdout_bufio;
};

@fini fn fini_stdfd() void = {
	// Flush any pending writes
	_ = io::close(stdout);
};
