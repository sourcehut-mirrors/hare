// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;

// This is an opaque type which encloses an OS-level file handle resource. It
// can be used as a [[handle]] in most situations, but there are some APIs which
// require a [[file]] with some OS-level handle backing it - this type is used
// for such APIs.
//
// On Hermes, [[file]] is a capability address.
export type file = sys::caddr;

fn fd_read(fd: file, buf: []u8) (size | EOF | error) = {
	return errors::unsupported;
};

fn fd_write(fd: file, buf: const []u8) (size | error) = {
	return errors::unsupported;
};

fn fd_close(fd: file) (void | error) = {
	return errors::unsupported;
};

fn fd_seek(
	fd: file,
	offs: off,
	whence: whence,
) (off | error) = {
	return errors::unsupported;
};

fn fd_copy(to: file, from: file) (size | error) = {
	return errors::unsupported;
};

fn fd_lock(fd: file, flags: int) (bool | error) = {
	return errors::unsupported;
};

fn fd_trunc(fd: file, ln: size) (void | error) = {
	return errors::unsupported;
};
