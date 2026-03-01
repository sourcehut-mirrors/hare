// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use fs;
use io;
use os;
use sys;

// Opens an available pseudoterminal and returns the file descriptors of the
// master and slave.
export fn openpty() ((io::file, io::file) | fs::error) = {
	let master = open_master()?;
	let slave = match (get_slave(master)) {
	case let e: fs::error =>
		io::close(master)!;
		return e;
	case let s: io::file =>
		yield s;
	};
	return (master, slave);
};

// Opens an available pseudoterminal master.
fn open_master() (io::file | fs::error) = {
	return os::open("/dev/ptmx", fs::flag::RDWR);
};

// Returns a file descriptor referring to the pseudoterminal slave for a
// pseudoterminal master.
fn get_slave(master: io::file) (io::file | fs::error) = {
	// Unlock the pseudoterminal slave
	match (sys::ioctl(master, sys::TIOCSPTLCK, &0)) {
	case sys::errno =>
		return errors::invalid;
	case => void;
	};

	let ioctl = sys::ioctl(
		master, sys::TIOCGPTPEER,
		(sys::O_RDWR | sys::O_NOCTTY): u64);
	match (ioctl) {
	case let e: sys::errno =>
		return errors::errno(e);
	case let fd: int =>
		return io::fdopen(fd);
	};
};

// Returns the filename of the pseudoterminal slave. The return value is
// statically allocated and will be overwritten on subsequent calls to this
// function.
export fn ptsname(master: io::file) (str | error) = {
	let pty = 0;
	match (sys::ioctl(master, sys::TIOCGPTN, &pty)) {
	case let e: sys::errno =>
		switch (e) {
		case sys::EBADF =>
			return errors::invalid;
		case sys::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case =>
		static let buf: [9 + 20]u8 = [0...];
		return fmt::bsprintf(buf[..len(buf)], "/dev/pts/{}", pty)!;
	};
};

// Sets the dimensions of the underlying pseudoterminal for an [[io::file]].
export fn set_winsize(pty: io::file, sz: ttysize) (void | error) = {
	let wsz = sys::winsize { ws_row = sz.rows, ws_col = sz.columns, ... };
	match (sys::ioctl(pty, sys::TIOCSWINSZ, &wsz)) {
	case let e: sys::errno =>
		switch (e) {
		case sys::EBADF =>
			return errors::invalid;
		case sys::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case => void;
	};
};
