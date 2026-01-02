// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use io;

let stdin_bufio: bufio::stream = @undefined;
let stdout_bufio: bufio::stream = @undefined;

// The standard input. This handle is buffered.
export let stdin: io::handle = 0; // initialized by init_stdfd

// The standard input, as an [[io::file]]. This handle is unbuffered.
export let stdin_file: io::file = 0;

// The standard output. This handle is buffered.
export let stdout: io::handle = 1; // initialized by init_stdfd

// The standard output, as an [[io::file]]. This handle is unbuffered.
export let stdout_file: io::file = 1;

// The standard error. This handle is unbuffered.
export let stderr: io::handle = 2;

// The standard error, as an [[io::file]]. This handle is unbuffered.
export let stderr_file: io::file = 2;

// The recommended buffer size for reading from disk.
export def BUFSZ: size = 4096; // 4 KiB

@init fn init_stdfd() void = {
	// TODO: Hermes: rig up files if file services are available
	stdin = io::empty;

	static let stdoutbuf: [BUFSZ]u8 = [0...];
	stdout_bufio = bufio::init(klog, [], stdoutbuf,
		bufio::flag::MANAGED_HANDLE);
	stdout = &stdout_bufio;

	stderr = klog;
};

@fini fn fini_stdfd() void = {
	// Flush any pending writes
	_ = io::close(stdout);
};
