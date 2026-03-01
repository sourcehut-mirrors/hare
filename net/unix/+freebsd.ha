// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use net;
use sys;
use types::c;

// Opens a UNIX socket connection to the path. Blocks until the connection is
// established.
export fn connect(
	addr: addr,
	options: connect_option...
) (net::socket | net::error) = {
	let sockaddr = match (to_native(addr)) {
	case let a: sys::sockaddr =>
		yield a;
	case invalid =>
		return errors::unsupported; // path too long
	};
	let f = 0i;
	for (let i = 0z; i < len(options); i += 1) {
		// Only sockflag for now
		f |= options[i];
	};
	f ^= sys::SOCK_CLOEXEC; // invert CLOEXEC
	const sockfd = match (sys::socket(sys::AF_UNIX: int, sys::SOCK_STREAM | f, 0)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	const sz = size(sys::sockaddr_un): u32;
	match (sys::connect(sockfd, &sockaddr, sz)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void => void;
	};
	return io::fdopen(sockfd);
};

// Binds a UNIX socket to the given path.
export fn listen(
	addr: addr,
	options: listen_option...
) (net::socket | net::error) = {
	let sockaddr = match (to_native(addr)) {
	case let a: sys::sockaddr =>
		yield a;
	case invalid =>
		return errors::unsupported; // path too long
	};
	let f = 0i;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case let fl: net::sockflag =>
			f |= fl;
		case => void;
		};
	};
	f ^= sys::SOCK_CLOEXEC; // invert CLOEXEC
	const sockfd = match (sys::socket(sys::AF_UNIX: int, sys::SOCK_STREAM | f, 0)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};

	let bk: u32 = 10;
	for (let i = 0z; i < len(options); i += 1) {
		match (options[i]) {
		case let b: backlog =>
			bk = b;
		case => void;
		};
	};

	match (sys::bind(sockfd, &sockaddr, size(sys::sockaddr_un): u32)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case void => void;
	};
	match (sys::listen(sockfd, bk)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case int => void;
	};

	return sockfd;
};

// Converts a UNIX socket address to a native sockaddr.
fn to_native(addr: addr) (sys::sockaddr | invalid) = {
	// sun_path should be NUL-terminated and fit into sys::UNIX_PATH_MAX
	if (len(addr) > sys::UNIX_PATH_MAX - 1) {
		return invalid;
	};
	let ret = sys::sockaddr {
		un = sys::sockaddr_un {
			sun_len = size(sys::sockaddr_un): u8,
			sun_family = sys::AF_UNIX,
			...
		}
	};
	c::fromstr_buf(addr, ret.un.sun_path: []c::char)!;
	return ret;
};
