// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use fs;
use io;
use os;
use sys;
use types::c;

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
	match (sys::posix_openpt(sys::O_RDWR | sys::O_NOCTTY)) {
	case let e: sys::errno =>
		return errors::errno(e);
	case let i: int =>
		return io::fdopen(i);
	};
};

// Returns a file descriptor referring to the pseudoterminal slave for a
// pseudoterminal master.
fn get_slave(master: io::file) (io::file | fs::error) =
	os::open(ptsname(master)?, fs::flag::RDWR);

// Returns the filename of the pseudoterminal slave. The return value is
// statically allocated and will be overwritten on subsequent calls to this
// function.
export fn ptsname(master: io::file) (str | error) = {
	let pm = sys::ptmget { ... };
	match (sys::ioctl(master, sys::TIOCPTSNAME, &pm)) {
	case let e: sys::errno =>
		switch (e) {
		case sys::EBADF =>
			return errors::invalid;
		case sys::EINVAL, sys::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case => void;
	};

	static let buf: [sys::PATH_MAX]u8 = [0...];
	return fmt::bsprintf(buf, c::tostr(&pm.sn: *const c::char)!)!;
};

// Sets the dimensions of the underlying pseudoterminal for an [[io::file]].
export fn set_winsize(pty: io::file, sz: ttysize) (void | error) = {
	let wsz = sys::winsize { ws_row = sz.rows, ws_col = sz.columns, ... };
	match (sys::ioctl(pty, sys::TIOCSWINSZ, &wsz)) {
	case let e: sys::errno =>
		switch (e) {
		case sys::EBADF, sys::EINVAL =>
			return errors::invalid;
		case sys::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case => void;
	};
};
