// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type socklen_t = u32;
export type sa_family_t = u8;

export type in_addr = struct {
	s_addr: u32
};

export type sockaddr_in = struct {
	sin_len: u8,
	sin_family: sa_family_t,
	sin_port: u16,
	sin_addr: in_addr,
	_: [24]u8,
};

export type in6_addr = struct {
	union {
		s6_addr: [16]u8,
		s6_addr16: [8]u16,
		s6_addr32: [4]u32,
	}
};

export type sockaddr_in6 = struct {
	sin6_len: u8,
	sin6_family: sa_family_t,
	sin6_port: u16,
	sin6_flowinfo: u32,
	sin6_addr: in6_addr,
	sin6_scope_id: u32,
};

export def UNIX_PATH_MAX: size = 126;

export type sockaddr_un = struct {
	sun_len: u8,
	sun_family: sa_family_t,
	sun_path: [UNIX_PATH_MAX]u8,
};

export type sockaddr = struct {
	union {
		in: sockaddr_in,
		in6: sockaddr_in6,
		un: sockaddr_un,
	},
};

export def SCM_RIGHTS: int = 0x01;

export type msghdr = struct {
	msg_name: nullable *opaque,
	msg_namelen: socklen_t,
	msg_iov: nullable *[*]iovec,
	msg_iovlen: uint,
	msg_control: nullable *opaque,
	msg_controllen: socklen_t,
	msg_flags: int
};

export type cmsghdr = struct {
	cmsg_len: socklen_t,
	cmsg_level: int,
	cmsg_type: int,
};

export type cmsg = struct {
	hdr: cmsghdr,
	cmsg_data: [*]u8,
};

export def SOCK_STREAM: int = 1;
export def SOCK_DGRAM: int = 2;
export def SOCK_RAW: int = 3;
export def SOCK_SEQPACKET: int = 5;
export def SOCK_MISC: int = 255;

export def SOL_SOCKET = -1;

export def SHUT_RD = 0;
export def SHUT_WR = 1;
export def SHUT_RDWR = 2;

export def AF_UNSPEC: sa_family_t = 0;
export def AF_INET: sa_family_t = 1;
export def AF_APPLETALK: sa_family_t = 2;
export def AF_ROUTE: sa_family_t = 3;
export def AF_LINK: sa_family_t = 4;
export def AF_INET6: sa_family_t = 5;
export def AF_DLI: sa_family_t = 6;
export def AF_IPX: sa_family_t = 7;
export def AF_NOTIFY: sa_family_t = 8;
export def AF_LOCAL: sa_family_t = 9;
export def AF_UNIX: sa_family_t = AF_LOCAL;
export def AF_BLUETOOTH: sa_family_t = 10;

export def SO_ACCEPTCONN: int = 0x00000001;
export def SO_BROADCAST: int = 0x00000002;
export def SO_DEBUG: int = 0x00000004;
export def SO_DONTROUTE: int = 0x00000008;
export def SO_KEEPALIVE: int = 0x00000010;
export def SO_OOBINLINE: int = 0x00000020;
export def SO_REUSEADDR: int = 0x00000040;
export def SO_REUSEPORT: int = 0x00000080;
export def SO_USELOOPBACK: int = 0x00000100;
export def SO_LINGER: int = 0x00000200;

export def SO_SNDBUF: int = 0x40000001;
export def SO_SNDLOWAT: int = 0x40000002;
export def SO_SNDTIMEO: int = 0x40000003;
export def SO_RCVBUF: int = 0x40000004;
export def SO_RCVLOWAT: int = 0x40000005;
export def SO_RCVTIMEO: int = 0x40000006;
export def SO_ERROR: int = 0x40000007;
export def SO_TYPE: int = 0x40000008;
export def SO_NONBLOCK: int = 0x40000009;
export def SO_BINDTODEVICE: int = 0x4000000a;
export def SO_PEERCRED: int = 0x4000000b;
