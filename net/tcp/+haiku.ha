// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use net;
use net::ip;
use sys;

// Opens a TCP connection to the given host and port. Blocks until the
// connection is established.
export fn connect(
	addr: ip::addr,
	port: u16,
	options: connect_option...
) (net::socket | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const family = match (addr) {
	case ip::addr4 =>
		yield sys::AF_INET: int;
	case ip::addr6 =>
		yield sys::AF_INET6: int;
	};

	let flags = 0i;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case let fl: net::sockflag =>
			flags |= fl;
		case => void;
		};
	};

	const sockfd = match (sys::socket(family, sys::SOCK_STREAM | flags, 0)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	if (flags & net::sockflag::NOCLOEXEC == 0) {
		match (sys::fcntl(sockfd, sys::F_SETFD, sys::FD_CLOEXEC)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
	};

	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case keepalive =>
			setsockopt(sockfd, sys::SO_KEEPALIVE, true)?;
		case => void;
		};
	};
	const sz = ip::native_addrlen(addr);
	match (sys::connect(sockfd, &sockaddr, sz)) {
	case let err: sys::errno =>
		if (err != sys::EINPROGRESS) {
			return errors::errno(err);
		};
	case void => void;
	};
	return io::fdopen(sockfd);
};

// Binds a TCP socket to the given address.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (net::socket | net::error) = {
	const sockaddr = ip::to_native(addr, port);
	const family = match (addr) {
	case ip::addr4 =>
		yield sys::AF_INET: int;
	case ip::addr6 =>
		yield sys::AF_INET6: int;
	};
	let flags = 0i;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case let fl: net::sockflag =>
			flags |= fl;
		case => void;
		};
	};

	const sockfd = match (sys::socket(family, sys::SOCK_STREAM, 0)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	if (flags & net::sockflag::NOCLOEXEC == 0) {
		match (sys::fcntl(sockfd, sys::F_SETFD, sys::FD_CLOEXEC)) {
		case int => void;
		case let e: sys::errno =>
			return errors::errno(e);
		};
	};

	let bk: u32 = 10;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case reuseaddr =>
			setsockopt(sockfd, sys::SO_REUSEADDR, true)?;
		case reuseport =>
			setsockopt(sockfd, sys::SO_REUSEPORT, true)?;
		case keepalive =>
			setsockopt(sockfd, sys::SO_KEEPALIVE, true)?;
		case let b: backlog =>
			bk = b;
		case => void;
		};
	};

	const sz = ip::native_addrlen(addr);
	match (sys::bind(sockfd, &sockaddr, sz)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void => void;
	};
	match (sys::listen(sockfd, bk)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void => void;
	};

	for (let i = 0z; i < len(options); i += 1) {
		let portout = match (options[i]) {
		case let p: portassignment =>
			yield p;
		case =>
			continue;
		};
		let sn = sys::sockaddr {...};
		let al = size(sys::sockaddr): u32;
		match (sys::getsockname(sockfd, &sn, &al)) {
		case let err: sys::errno =>
			return errors::errno(err);
		case void => void;
		};
		const addr = ip::from_native(sn);
		*portout = addr.1;
	};

	return sockfd;
};

// Returns the remote address for a given connection, or void if none is
// available.
export fn peeraddr(peer: net::socket) ((ip::addr, u16) | void) = {
	let sn = sys::sockaddr {...};
	let sz = size(sys::sockaddr): u32;
	if (sys::getpeername(peer, &sn, &sz) is sys::errno) {
		return;
	};
	return ip::from_native(sn);
};

fn setsockopt(
	sockfd: int,
	option: int,
	value: bool,
) (void | net::error) = {
	let val: int = if (value) 1 else 0;
	match (sys::setsockopt(sockfd, sys::SOL_SOCKET, option,
			&val: *opaque, size(int): u32)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void => void;
	};
};
