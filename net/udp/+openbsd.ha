// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use net;
use net::ip;
use sys;

// Creates a UDP socket and sets the default destination to the given address.
export fn connect(
	dest: ip::addr,
	port: u16,
	options: connect_option...
) (net::socket | net::error) = {
	const family = match (dest) {
	case ip::addr4 =>
		yield sys::AF_INET: int;
	case ip::addr6 =>
		yield sys::AF_INET6: int;
	};
	let flags = 0i;
	for (let i = 0z; i < len(options); i += 1) {
		// Only sockflag for now
		flags |= options[i];
	};
	flags ^= sys::SOCK_CLOEXEC; // invert CLOEXEC
	const sockfd = match (sys::socket(family, sys::SOCK_DGRAM | flags, 0)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	const sockaddr = ip::to_native(dest, port);
	const sz = ip::native_addrlen(dest);
	match (sys::connect(sockfd, &sockaddr, sz)) {
	case void =>
		return io::fdopen(sockfd);
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Creates a UDP socket bound to an interface.
export fn listen(
	addr: ip::addr,
	port: u16,
	options: listen_option...
) (net::socket | net::error) = {
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
	flags ^= sys::SOCK_CLOEXEC; // invert CLOEXEC
	const sockfd = match (sys::socket(family, sys::SOCK_DGRAM | flags, 0)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case reuseaddr =>
			setsockopt(sockfd, sys::SO_REUSEADDR, true)?;
		case reuseport =>
			setsockopt(sockfd, sys::SO_REUSEPORT, true)?;
		case => void;
		};
	};

	const sockaddr = ip::to_native(addr, port);
	const sz = ip::native_addrlen(addr);
	match (sys::bind(sockfd, &sockaddr, sz)) {
	case void => void;
	case let err: sys::errno =>
		return errors::errno(err);
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

	return io::fdopen(sockfd);
};

// Sends a UDP packet to a [[connect]]ed UDP socket.
export fn send(sock: net::socket, buf: []u8) (size | net::error) = {
	match (sys::sendto(sock, buf: *[*]u8, len(buf), 0, null, 0)) {
	case let sz: size =>
		return sz;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Sends a UDP packet using this socket.
export fn sendto(
	sock: net::socket,
	buf: []u8,
	dest: ip::addr,
	port: u16,
) (size | net::error) = {
	const sockaddr = ip::to_native(dest, port);
	const sz = ip::native_addrlen(dest);
	match (sys::sendto(sock, buf: *[*]u8, len(buf), 0, &sockaddr, sz)) {
	case let sz: size =>
		return sz;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Receives a UDP packet from a [[connect]]ed UDP socket.
export fn recv(
	sock: net::socket,
	buf: []u8,
) (size | net::error) = {
	match (sys::recvfrom(sock, buf: *[*]u8, len(buf), 0, null, null)) {
	case let sz: size =>
		return sz;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Receives a UDP packet from a bound socket.
export fn recvfrom(
	sock: net::socket,
	buf: []u8,
	src: nullable *ip::addr,
	port: nullable *u16,
) (size | net::error) = {
	let addrsz = size(sys::sockaddr): u32;
	const sockaddr = sys::sockaddr { ... };
	const sz = match (sys::recvfrom(sock, buf: *[*]u8, len(buf), 0,
		&sockaddr, &addrsz)) {
	case let sz: size =>
		yield sz;
	case let err: sys::errno =>
		return errors::errno(err);
	};

	assert(addrsz <= size(sys::sockaddr));
	const peer = ip::from_native(sockaddr);
	match (src) {
	case null => void;
	case let src: *ip::addr =>
		*src = peer.0;
	};
	match (port) {
	case null => void;
	case let port: *u16 =>
		*port = peer.1;
	};

	return sz;
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
