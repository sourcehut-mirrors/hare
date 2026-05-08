// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;

// A network socket.
export type socket = io::file;

// Optional flags to [[accept]] to be set on the returned [[socket]].
// See the O_CLOEXEC and O_NONBLOCK sections of open(2) for details.
// Note that CLOEXEC is on by default, and NOCLOEXEC flag disables it.
export type sockflag = enum int {
	NOCLOEXEC = sys::SOCK_CLOEXEC,
	NONBLOCK = sys::SOCK_NONBLOCK
};

// Accepts the next connection from a socket. Blocks until a new connection is
// available. Optionally accepts NOCLOEXEC and NONBLOCK flags. If flags are
// supplied, the [[io::file]] returned will have the supplied flags set.
export fn accept(sock: socket, flags: sockflag = 0) (socket | error) = {
	const fd = match (sys::accept(sock, null, null)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	if (flags & sockflag::NOCLOEXEC == 0) {
		match (sys::fcntl(fd, sys::F_SETFD, sys::FD_CLOEXEC)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
	};
	if (flags & sockflag::NONBLOCK != 0) {
		match (sys::fcntl(fd, sys::F_SETFL, sys::O_NONBLOCK)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
	};

	return io::fdopen(fd);
};

fn msg_to_native(msg: *msghdr) *sys::msghdr = {
	let native = &msg.native;
	if (len(msg.vectors) != 0) {
		native.msg_iov = msg.vectors: *[*]sys::iovec;
		// XXX: size -> uint could overflow here.
		native.msg_iovlen = len(msg.vectors): uint;
	};
	if (len(msg.control) != 0) {
		native.msg_control = msg.control: *[*]u8;
		// XXX: size -> uint could overflow here.
		native.msg_controllen = len(msg.control): uint;
	};
	return native;
};

// Sends a message to a socket. See [[newmsg]] for details.
export fn sendmsg(sock: socket, msg: *msghdr) (size | error) = {
	// TODO: Flags
	match (sys::sendmsg(sock, msg_to_native(msg), 0)) {
	case let n: int =>
		return n: size;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Receives a message from a socket. See [[newmsg]] for details.
export fn recvmsg(sock: socket, msg: *msghdr) (size | error) = {
	// TODO: Flags
	match (sys::recvmsg(sock, msg_to_native(msg), 0)) {
	case let n: int =>
		return n: size;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Closes a [[socket]]. No further operations against this socket are permitted
// after calling this function. Closing a socket can fail only under certain
// conditions (for example, closing a socket twice, or an interrupted syscall).
// However, the user should not attempt to close the file again on failure - at
// best the user should print a diagnostic message and move on. See close(2) for
// details.
//
// On Haiku, this function is an alias for [[io::close]].
export fn close(sock: socket) (void | error) = {
	match (io::close(sock)) {
	case void => void;
	case io::underread => abort();
	case io::mode => abort();
	case let err: errors::error =>
		return err;
	};
};

// Shuts down part of a full-duplex connection.
export fn shutdown(sock: socket, how: shut) (void | error) = {
	match (sys::shutdown(sock, how)) {
	case void => void;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};
