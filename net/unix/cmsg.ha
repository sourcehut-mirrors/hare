// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use net;
use sys;

// Adds a list of file descriptors to "send" over a Unix socket with
// [[net::sendmsg]] using a [[net::msghdr]] prepared with [[net::newmsg]].
//
// See [[allocfiles]] and [[recvfiles]] for details on the recipient
// ([[net::recvmsg]]) operation.
export fn addfiles(buf: *net::msghdr, files: io::file...) (void | nomem) = {
	const msgsz = size(io::file) * len(files);
	let buf = net::addcontrol(buf, msgsz, sys::SOL_SOCKET, sys::SCM_RIGHTS)?;
	let buf = buf: *[*]io::file;
	buf[..len(files)] = files[..];
};

// Prepares a buffer in which to store file descriptors received from a call to
// [[net::recvmsg]] over a Unix socket. One must call allocfiles prior to
// calling [[net::recvmsg]] to prepare this buffer, then use [[recvfiles]] to
// extract [[io::file]] handles from the buffer after the message is received.
//
// This function concerns receiving files, see [[addfiles]] for information
// about sending files.
export fn allocfiles(buf: *net::msghdr, nfile: size) (void | nomem) = {
	const msgsz = size(io::file) * nfile;
	net::addcontrol(buf, msgsz, sys::SOL_SOCKET, sys::SCM_RIGHTS)?;
};

// Receives files from a control message which was previously prepared with
// [[allocfiles]].
export fn recvfiles(buf: *net::msghdr, nfile: size) []io::file = {
	match (net::getcontrol(buf,
		nfile * size(io::file),
		sys::SOL_SOCKET, sys::SCM_RIGHTS)) {
	case let buf: []u8 =>
		return (buf: *[*]io::file)[..nfile];
	case void =>
		return [];
	};
};
