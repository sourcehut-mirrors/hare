// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use proto::io;
use sys;

// This is an opaque type which encloses an OS-level file handle resource. It
// can be used as a [[handle]] in most situations, but there are some APIs which
// require a [[file]] with some OS-level handle backing it - this type is used
// for such APIs.
//
// On Hermes, [[file]] is a capability address.
export type file = sys::caddr;

fn fd_read(fd: file, buf: []u8) (size | EOF | error) = {
	let params = sys::call_params {
		ep = fd,
		...
	};
	const n = match (io::file_read(&params, len(buf))) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let n: size =>
		yield n;
	};

	const data = io::get_buffer_file_read(&params);
	if (n == 0) {
		return EOF;
	};
	buf[..n] = data[..];
	return n;
};

fn fd_write(fd: file, buf: const []u8) (size | error) = {
	let params = sys::call_params {
		ep = fd,
		...
	};
	io::prep_buffer_file_write(&params, buf);
	match (io::file_write(&params)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let z: size =>
		return z;
	};
};

fn fd_close(fd: file) (void | error) = {
	return errors::unsupported;
};

fn fd_seek(
	fd: file,
	offs: off,
	whence: whence,
) (off | error) = {
	match (io::file_seek(fd, offs, whence: io::whence)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let o: i64 =>
		return o;
	};
};

fn fd_copy(to: file, from: file) (size | error) = {
	return errors::unsupported;
};

fn fd_lock(fd: file, flags: int) (bool | error) = {
	return errors::unsupported;
};

fn fd_trunc(fd: file, ln: size) (void | error) = {
	match (io::file_truncate(fd, ln)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let z: size =>
		return z;
	};
};
