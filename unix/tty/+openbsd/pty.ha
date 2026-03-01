// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;
use sys;
use types::c;

// Opens an available pseudoterminal and returns the file descriptors of the
// master and slave.
export fn openpty() ((io::file, io::file) | fs::error) = {
	let master = open_master()?;
	defer io::close(master)!;

	let ptm = sys::ptmget { ... };
	match (sys::ioctl(master, sys::PTMGET, &ptm)) {
	case let e: sys::errno =>
		return errors::errno(e);
	case =>	void;
	};

	return (ptm.cfd, ptm.sfd);
};

// Opens an available pseudoterminal master.
fn open_master() (io::file | fs::error) = {
	match (sys::open(sys::PATH_PTMDEV, sys::O_RDWR, 0)) {
	case let e: sys::errno =>
		return errors::errno(e);
	case let i: int =>
		return io::fdopen(i);
	};
};

// Returns the filename of the pseudoterminal slave. The return value is
// statically allocated and will be overwritten on subsequent calls to this
// function.
export fn ptsname(master: io::file) (str | error) = {
	static let path_buf: [sys::PATH_MAX]u8 = [0...];

	let name = match (sys::ptsname(master)) {
	case let name: *u8 =>
		yield name: *[*]u8;
	case let err: sys::errno =>
		switch (err) {
		// master is not a pseudo-terminal device
		case sys::EINVAL =>
			return errors::unsupported;
		// master is not an open valid file descriptor
		case sys::EBADF =>
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
