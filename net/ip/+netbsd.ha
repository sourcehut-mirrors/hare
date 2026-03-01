// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use endian;
use sys;

export fn to_native(a: addr, port: u16) sys::sockaddr = {
	match (a) {
	case let v4: addr4 =>
		return sys::sockaddr {
			in = sys::sockaddr_in {
				sin_len = size(sys::in_addr): u8,
				sin_family = sys::AF_INET,
				sin_port = endian::htonu16(port),
				sin_addr = sys::in_addr { s_addr = *(&v4[0]: *opaque: *u32) },
				...
			},
			...
		};
	case let v6: addr6 =>
		return sys::sockaddr {
			in6 = sys::sockaddr_in6 {
				sin6_len = size(sys::in6_addr): u8,
				sin6_family = sys::AF_INET6,
				sin6_port = endian::htonu16(port),
				sin6_addr = sys::in6_addr { s6_addr = v6 },
				...
			},
			...
		};
	};
};

export fn from_native(a: sys::sockaddr) (addr, u16)  = {
	let family = a.in.sin_family;
	switch (family) {
	case sys::AF_INET =>
		let addr = a.in.sin_addr.s_addr;
		return (
			[addr: u8, (addr >> 8): u8, (addr >> 16): u8,
				(addr >> 24):  u8]: addr4,
			endian::ntohu16(a.in.sin_port)
		);
	case sys::AF_INET6 =>
		return (
			a.in6.sin6_addr.s6_addr: addr6,
			endian::ntohu16(a.in6.sin6_port)
		);
	case =>
		abort("Wrong address family!");
	};
};

export fn native_addrlen(a: addr) u32 = {
	match (a) {
	case addr4 =>
		return size(sys::sockaddr_in): u32;
	case addr6 =>
		return size(sys::sockaddr_in6): u32;
	};
};
