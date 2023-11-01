// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;
use rt::io;
use rt::sys;

// This is an opaque type which encloses an OS-level file handle resource. It
// can be used as a [[handle]] in most situations, but there are some APIs which
// require a [[file]] with some OS-level handle backing it - this type is used
// for such APIs.
//
// On Gaia, [[file]] is a capability.
export type file = rt::cap;

// Opens a capability as a file. This is a low-level interface, to open files
// most programs will use something like [[os::open]]. This function is not
// portable.
export fn fdopen(cap: rt::cap) file = cap;

fn fd_read(fd: file, buf: []u8) (size | EOF | error) = {
	let n = len(buf);
	if (n > rt::PAGESIZE) {
		// TODO: read buffers >1 page
		n = rt::PAGESIZE;
	};

	const (page, base) = rt::pool_acquire();
	defer rt::pool_release(base);

	const z = io::file_read(fd, [page], base, n);
	assert(z <= n);
	if (z == 0) {
		return EOF;
	};

	const data = base: *[*]u8;
	buf[..z] = data[..z];
	return z;
};

fn fd_write(fd: file, buf: const []u8) (size | error) = {
	let n = len(buf);
	if (n > rt::PAGESIZE) {
		// TODO: read buffers >1 page
		n = rt::PAGESIZE;
	};

	const (page, base) = rt::pool_acquire();
	defer rt::pool_release(base);

	let data = base: *[*]u8;
	data[..n] = buf[..n];
	return io::file_write(fd, [page], base, n);
};

fn fd_close(fd: file) (void | error) = {
	assert(rt::self != ~0);
	sys::process_unref(rt::self, fd);
};

fn fd_seek(
	fd: file,
	offs: off,
	whence: whence,
) (off | error) = {
	return io::file_seek(fd, offs, whence: io::whence): off;
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
