// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use net;
use sys;

// A thin wrapper around socketpair(2) that presumes [[sys::AF_UNIX]] for the
// domain and returns an unnamed pair of sockets of type [[sys::SOCK_STREAM]].
export fn socketpair(flags: net::sockflag = 0) ((net::socket, net::socket) | net::error) = {
	let sv: [2]int = [0...];
	match (sys::socketpair(sys::AF_UNIX: int, sys::SOCK_STREAM | flags, 0, &sv)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case => void;
	};

	if (flags & net::sockflag::NOCLOEXEC == 0) {
		match (sys::fcntl(sv[0], sys::F_SETFD, sys::FD_CLOEXEC)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
		match (sys::fcntl(sv[1], sys::F_SETFD, sys::FD_CLOEXEC)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
	};

	return (io::fdopen(sv[0]), io::fdopen(sv[1]));
};
