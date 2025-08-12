// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type socklen_t = size;
export type sa_family_t = u16;
export type in_port_t = u16;
export type in_addr_t = u32;

export def SOCK_TYPE_MASK = ((1<<20)-1);
export def SOCK_DGRAM = 1;
export def SOCK_SEQPACKET = 2;
export def SOCK_STREAM = 3;
export def SOCK_RAW = 4;

export def SOCK_NONBLOCK = (1<<20);
export def SOCK_CLOEXEC = (1<<21);
export def SOCK_CLOFORK = (1<<22);

export def _SS_SIZE = 128;
export def _SS_PADSIZE = _SS_SIZE - 2 * size(u64);

export type sockaddr = union {
	in: sockaddr_in,
	in6: sockaddr_in6,
	un: sockaddr_un,
	_: sockaddr_padding,
};

export type sockaddr_padding = struct {
	ss_family: sa_family_t,
	_: u64,
	_: [_SS_PADSIZE]u8,
};

export type in_addr = struct {
	s_addr: in_addr_t,
};

export type sockaddr_in = struct {
	sin_family: sa_family_t,
	sin_port: in_port_t,
	sin_addr: in_addr,
};

export type in6_addr = struct {
	union {
		s6_addr: [16]u8,
		s6_addr16: [8]u16,
		s6_addr32: [4]u32,
	}
};

export type sockaddr_in6 = struct {
	sin6_family: sa_family_t,
	sin6_port: in_port_t,
	sin6_flowinfo: u32,
	sin6_addr: in6_addr,
	sin6_scope_id: u32,
};

export type sockaddr_un = struct {
	sun_family: sa_family_t,
	sun_path: [128 - size(sa_family_t)]u8,
};

export def SCM_RIGHTS = 1;

export type msghdr = struct {
	msg_name: nullable *opaque,
	msg_namelen: socklen_t,
	msg_iov: nullable *[*]iovec,
	msg_iovlen: int,
	msg_control: nullable *opaque,
	msg_controllen: socklen_t,
	msg_flags: int,
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

export def SOL_SOCKET = 0;

export def SO_ACCEPTCONN = 1;
export def SO_BROADCAST = 2;
export def SO_DEBUG = 3;
export def SO_DONTROUTE = 4;
export def SO_ERROR = 5;
export def SO_KEEPALIVE = 6;
export def SO_LINGER = 7;
export def SO_OOBINLINE = 8;
export def SO_RCVBUF = 9;
export def SO_RCVLOWAT = 10;
export def SO_RCVTIMEO = 11;
export def SO_REUSEADDR = 12;
export def SO_SNDBUF = 13;
export def SO_SNDLOWAT = 14;
export def SO_SNDTIMEO = 15;
export def SO_TYPE = 16;
export def SO_BINDTOINDEX = 17;
export def SO_BINDTODEVICE = 18;
export def SO_DOMAIN = 19;
export def SO_PROTOCOL = 20;

export def SOMAXCONN = 128;

export def MSG_CTRUNC = (1<<0);
export def MSG_DONTROUTE = (1<<1);
export def MSG_EOR = (1<<2);
export def MSG_OOB = (1<<3);
export def MSG_NOSIGNAL = (1<<4);
export def MSG_PEEK = (1<<5);
export def MSG_TRUNC = (1<<6);
export def MSG_WAITALL = (1<<7);
export def MSG_DONTWAIT = (1<<8);
export def MSG_CMSG_CLOEXEC = (1<<9);
export def MSG_CMSG_CLOFORK = (1<<10);

export def AF_UNSPEC = 0;
export def AF_INET = 1;
export def AF_INET6 = 2;
export def AF_UNIX = 3;

export def SHUT_RD = (1 << 0);
export def SHUT_WR = (1 << 1);
export def SHUT_RDWR = (SHUT_RD | SHUT_WR);
