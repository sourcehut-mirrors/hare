// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;
use unix;

// Sets the process group on the foreground of this terminal.
export fn tcsetpgrp(fd: io::file, pg: unix::pid) (void | errors::error) = {
	match (sys::ioctl(fd, sys::TIOCSPGRP, &pg)) {
	case int => void;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Gets the process group on the foreground of this terminal.
export fn tcgetpgrp(fd: io::file) (unix::pid | errors::error) = {
	let pg: unix::pid = @undefined;
	match (sys::ioctl(fd, sys::TIOCGPGRP, &pg)) {
	case int =>
		return pg;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};
