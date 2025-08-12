// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use rt;
use types::c;

// Opens an available pseudoterminal and returns the file descriptors of the
// master and slave.
export fn openpty() ((io::file, io::file) | fs::error) = {
	let master = 0, slave = 0;
	match (rt::openpty(&master, &slave, null, null, null)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void =>
		return (master: io::file, slave: io::file);
	};
};

// Returns the filename of the pseudoterminal slave. The return value is
// statically allocated and will be overwritten on subsequent calls to this
// function.
export fn ptsname(master: io::file) (str | error) = {
	static let path_buf: [rt::PATH_MAX]u8 = [0...];

	let name = match (rt::ptsname(master)) {
	case let name: *u8 =>
		yield name: *[*]u8;
	case let err: rt::errno =>
		switch (err) {
		// master is not a pseudo-terminal device
		case rt::EINVAL =>
			return errors::unsupported;
		// master is not an open valid file descriptor
		case rt::EBADF =>
			return errors::invalid;
		case =>
			abort("Unexpected error from ptsname");
		};
	};
	let namelen = c::strlen(name: *const c::char);
	path_buf[..namelen] = name[..namelen];
	return c::tostrn(&path_buf: *const c::char, namelen)!;
};

// Sets the dimensions of the underlying pseudoterminal for an [[io::file]].
export fn set_winsize(pty: io::file, sz: ttysize) (void | error) = {
	let wsz = rt::winsize { ws_row = sz.rows, ws_col = sz.columns, ... };
	match (rt::ioctl(pty, rt::TIOCSWINSZ, &wsz)) {
	case let e: rt::errno =>
		switch (e) {
		case rt::EBADF, rt::EINVAL =>
			return errors::invalid;
		case rt::ENOTTY =>
			return errors::unsupported;
		case =>
			abort("Unexpected error from ioctl");
		};
	case => void;
	};
};
