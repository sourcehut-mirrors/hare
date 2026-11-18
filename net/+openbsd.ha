// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use net::ip;
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
	flags ^= sys::SOCK_CLOEXEC: sockflag; // invert CLOEXEC
	const fd = match (sys::accept4(sock, null, null, flags)) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let fd: int =>
		yield fd;
	};
	return io::fdopen(fd);
};

fn msg_to_native(msg: *msghdr) *sys::msghdr = {
	let native = &msg.native;
	native.msg_iov = if (len(msg.vectors) != 0) {
	        yield msg.vectors: *[*]sys::iovec;
	} else {
	        yield null;
	};
	native.msg_iovlen = len(msg.vectors): uint; // XXX: may overflow

	native.msg_control = if (len(msg.control) != 0) {
	        yield msg.control: *[*]u8;
	} else {
	        yield null;
	};
	native.msg_controllen = len(msg.control): uint; // XXX: may overflow
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
// On OpenBSD, this function is an alias for [[io::close]].
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

// Joins an IPv4 multicast group. "group" must be a valid multicast address, and
// "iface" is the local interface address which shall join the group, or
// [[net::ip::ANY_V4]] to allow the system to choose a suitable default.
//
// See also [[leave_multicast_v4]].
export fn join_multicast_v4(
	sock: socket,
	group: ip::addr4,
	iface: ip::addr4,
) (void | error) = {
	const group = ip::to_native(group, 0).in.sin_addr;
	const iface = ip::to_native(iface, 0).in.sin_addr;
	return do_mreq(sock, sys::IPPROTO_IP, sys::IP_ADD_MEMBERSHIP,
		&sys::ip_mreq {
			imr_multiaddr = group,
			imr_interface = iface,
		}, size(sys::ip_mreq));
};

// Joins an IPv6 multicast group. "group" must be a valid multicast address, and
// "iface" is the local interface index which shall join the group, or 0 to
// allow the system to choose a suitable default.
//
// See also [[leave_multicast_v6]].
export fn join_multicast_v6(
	sock: socket,
	group: ip::addr6,
	iface: uint,
) (void | error) = {
	const group = ip::to_native(group, 0).in6.sin6_addr;
	return do_mreq(sock, sys::IPPROTO_IPV6, sys::IPV6_JOIN_GROUP,
		&sys::ipv6_mreq {
			ipv6mr_multiaddr = group,
			ipv6mr_interface = iface,
		}, size(sys::ipv6_mreq));
};

// Leaves an IPv4 multicast group. "group" must be a valid multicast address,
// and "iface" is the local interface address which shall join the group, or
// [[net::ip::ANY_V4]] to allow the system to choose a suitable default.
//
// See also [[join_multicast_v4]].
export fn leave_multicast_v4(
	sock: socket,
	group: ip::addr4,
	iface: ip::addr4,
) (void | error) = {
	const group = ip::to_native(group, 0).in.sin_addr;
	const iface = ip::to_native(iface, 0).in.sin_addr;
	return do_mreq(sock, sys::IPPROTO_IP, sys::IP_DROP_MEMBERSHIP,
		&sys::ip_mreq {
			imr_multiaddr = group,
			imr_interface = iface,
		}, size(sys::ip_mreq));
};

// Leaves an IPv6 multicast group. "group" must be a valid multicast address,
// and "iface" is the local interface index which shall join the group, or 0 to
// allow the system to choose a suitable default.
//
// See also [[join_multicast_v6]].
export fn leave_multicast_v6(
	sock: socket,
	group: ip::addr6,
	iface: uint,
) (void | error) = {
	const group = ip::to_native(group, 0).in6.sin6_addr;
	return do_mreq(sock, sys::IPPROTO_IPV6, sys::IPV6_LEAVE_GROUP,
		&sys::ipv6_mreq {
			ipv6mr_multiaddr = group,
			ipv6mr_interface = iface,
		}, size(sys::ipv6_mreq));
};

fn do_mreq(
	sock: socket,
	proto: int,
	optname: int,
	optval: *opaque,
	optlen: size,
) (void | error) = {
	match (sys::setsockopt(sock, proto, optname, optval, optlen: u32)) {
	case int =>
		return;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};
