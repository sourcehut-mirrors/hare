// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use endian;
use errors;
use io;
use net;
use net::ip;
use net::tcp;
use net::udp;
use time;
use types;
use unix::poll;
use unix::resolvconf;

// TODO: Let user customize this?
def timeout: time::duration = 3 * time::SECOND;

// Performs a DNS query using the provided list of DNS servers. The caller must
// free the return value with [[message_free]].
//
// If no DNS servers are provided, the system default servers (if any) are used.
export fn query(query: *message, servers: ip::addr...) (*message | error | nomem) = {
	if (len(servers) == 0) {
		servers = resolvconf::load().nameservers;
	};
	if (len(servers) == 0) {
		// Fall back to localhost
		servers = [ip::LOCAL_V6, ip::LOCAL_V4];
	};

	let last_err: net::error = errors::invalid;
	let sock4: io::file = -1, sock6: io::file = -1;
	let npoll = 0z;

	const pollfd: [2]poll::pollfd = [
		poll::pollfd { ... },
		poll::pollfd { ... },
	];

	match (udp::listen(ip::ANY_V4, 0)) {
	case let sock: net::socket =>
		sock4 = sock;
		pollfd[npoll] = poll::pollfd {
			fd = sock4,
			events = poll::event::POLLIN,
			...
		};
		npoll += 1;
	case let err: net::error =>
		last_err = err;
	};
	defer if (sock4 != -1) net::close(sock4)!;

	match (udp::listen(ip::ANY_V6, 0)) {
	case let sock: net::socket =>
		sock6 = sock;
		pollfd[npoll] = poll::pollfd {
			fd = sock6,
			events = poll::event::POLLIN,
			...
		};
		npoll += 1;
	case let err: net::error =>
		last_err = err;
	};
	defer if (sock6 != -1) net::close(sock6)!;

	if (npoll == 0) {
		return last_err;
	};

	let buf: [512]u8 = [0...];
	let z = encode(buf, query)?;

	// We send requests in parallel to all configured servers and take the
	// first one which sends us a reasonable answer.
	for (let i = 0z; i < len(servers); i += 1) match (servers[i]) {
	case ip::addr4 =>
		if (sock4 == -1) continue;
		udp::sendto(sock4, buf[..z], servers[i], 53)?;
	case ip::addr6 =>
		if (sock6 == -1) continue;
		udp::sendto(sock6, buf[..z], servers[i], 53)?;
	};

	let header = header { ... };
	let src: ip::addr = ip::ANY_V4;
	for (true) {
		let nevent = match (poll::poll(pollfd[..npoll], timeout)) {
		case let nevent: uint =>
			yield nevent;
		case let e: poll::error =>
			return e: io::error;
		};
		if (nevent == 0) {
			return errors::timeout;
		};

		for (let f &.. pollfd[..npoll]) {
			if (f.revents & poll::event::POLLIN != 0) {
				z = udp::recvfrom(f.fd, buf, &src, null)?;
			};
		};

		let expected = false;
		for (let i = 0z; i < len(servers); i += 1) {
			if (ip::equal(src, servers[i])) {
				expected = true;
				break;
			};
		};
		if (!expected) {
			continue;
		};

		const dec = decoder_init(buf[..z]);
		decode_header(&dec, &header)?;
		if (header.id == query.header.id && header.op.qr == qr::RESPONSE) {
			break;
		};
	};

	if (!header.op.tc) {
		check_rcode(header.op.rcode)?;
		return match (decode(buf[..z])) {
		case let m: *message =>
			return m;
		case format =>
			return format;
		case nomem =>
			return nomem;
		};
	};

	// Response was truncated, retry over TCP. In TCP mode, the
	// query is preceded by two bytes indicating the query length
	z = encode(buf, query)?;
	if (z > types::U16_MAX) {
		return errors::overflow;
	};
	let zbuf: [2]u8 = [0...];
	endian::beputu16(zbuf, z: u16);
	let socket = tcp::connect(src, 53)?;
	defer net::close(socket)!;

	io::writeall(socket, zbuf)?;
	io::writeall(socket, buf[..z])?;

	let rz: u16 = match (io::readall(socket, zbuf)?) {
	case let s: size =>
		if (s != 2) {
			return format;
		};
		yield endian::begetu16(zbuf);
	case =>
		return format;
	};
	let tcpbuf: []u8 = alloc([0...], rz)?;
	defer free(tcpbuf);

	match (io::readall(socket, tcpbuf)?) {
	case let s: size =>
		if (s != rz) {
			return format;
		};
	case =>
		return format;
	};

	const dec = decoder_init(tcpbuf);
	decode_header(&dec, &header)?;
	if ((header.id != query.header.id) || header.op.tc) {
		return format;
	};
	check_rcode(header.op.rcode)?;
	return match (decode(tcpbuf)) {
	case let m: *message =>
		return m;
	case format =>
		return format;
	case nomem =>
		return nomem;
	};
};
