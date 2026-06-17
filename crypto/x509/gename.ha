// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use bufio;
use encoding::asn1;
use io;
use memio;
use net::ip;
use strings;

// Iterator over general names like Subject Alternative name.
export type gniter = asn1::decoder;

fn newgniter(c: *cert, pos: io::off) (gniter | _error) = {
	io::seek(&c.h, pos, io::whence::SET)?;
	let d = asn1::derdecoder(&c.h);
	asn1::open_seq(&d)?;
	asn1::peek(&d)?; // must have one record
	return d;
};

// Closes the iterator. Returns an error, if the iterator is not fully read.
export fn gn_close(it: *gniter) (void | error) = {
	match (asn1::close_seq(it: *asn1::decoder)) {
	case void => void;
	case let e: asn1::badformat =>
		return norm_error(e);
	};
};

fn gn_trypeek_head(it: *asn1::decoder) (asn1::head | done | error) = {
	const h = match (asn1::trypeek(it)) {
	case let h: asn1::head =>
		yield h;
	case io::EOF =>
		return done;
	case let e: asn1::error =>
		return norm_error(e);
	};

	if (h.class != asn1::class::CONTEXT || h.tagid > gn::REGISTERED_ID) {
		return "bad gn part": badformat;
	};

	return h;
};

fn gn_peek_head(it: *asn1::decoder) (asn1::head | error) = {
	match (gn_trypeek_head(it)?) {
	case done =>
		return "missing gn": badformat;
	case let h: asn1::head =>
		return h;
	};
};

// Peeks the type of the next name and returns done, if none available.
export fn gn_trypeek(it: *gniter) (gn | done | error) = {
	match (gn_trypeek_head(it: *asn1::decoder)?) {
	case done =>
		return done;
	case let h: asn1::head =>
		return h.tagid: gn;
	};
};

// Peeks the type of the next name. Returns an error, if not available.
export fn gn_peek(it: *gniter) (gn | error) = {
	match (gn_trypeek_head(it: *asn1::decoder)?) {
	case done =>
		return "gn expected": badformat;
	case let h: asn1::head =>
		return h.tagid: gn;
	};
};

fn gn_str(d: *asn1::decoder, h: asn1::head, strt: asn1::utag) (utf8reader | error) = {

	match (asn1::expect_implicit(d, h.class, h.tagid)) {
	case void => void;
	case let e: asn1::error =>
		return norm_error(e);
	};
	match (asn1::strreader(d, strt)) {
	case let u: asn1::utf8stream =>
		return u;
	case let e: asn1::error =>
		return norm_error(e);
	};
};

// Reads current name as DNS from an [[gniter]].
export fn gn_dns(d: *asn1::decoder) (utf8reader | error) = {
	let h = gn_peek_head(d)?;
	if (h.tagid != gn::DNS) {
		return "unexpected gn": badformat;
	};

	return gn_str(d, h, asn1::utag::IA5_STRING);
};

// Reads current name as URI from an [[gniter]].
export fn gn_uri(d: *asn1::decoder) (utf8reader | error) = {
	let h = gn_peek_head(d)?;
	if (h.tagid != gn::URI) {
		return "unexpected gn": badformat;
	};

	return gn_str(d, h, asn1::utag::IA5_STRING);
};

// Reads current name as an RFC822 E-Mail from an [[gniter]].
export fn gn_rfc822(d: *asn1::decoder) (utf8reader | error) = {
	// TODO validate
	let h = gn_peek_head(d)?;
	if (h.tagid != gn::RFC822) {
		return "unexpected gn": badformat;
	};

	return gn_str(d, h, asn1::utag::IA5_STRING);
};

fn _gn_next_dns(it: *gniter) (utf8reader | done | _error) = {
	for (let h => gn_trypeek_head(it: *asn1::decoder)?) {
		if (h.tagid != gn::DNS) {
			gn_skip(it)?;
			continue;
		};

		let d = it: *asn1::decoder;
		asn1::expect_implicit(d, h.class, h.tagid)?;
		return asn1::strreader(d, asn1::utag::IA5_STRING)?;
	};

	return done;
};

// Get the next name of type [[gn::DNS]] (dNSName).
export fn gn_next_dns(it: *gniter) (utf8reader | done | error) = {
	match (_gn_next_dns(it)) {
	case let r: utf8reader =>
		return r;
	case done =>
		return done;
	case let e: _error =>
		return norm_error(e);
	};
};

fn _gn_next_ip(it: *gniter) (ip::addr | done | _error) = {
	for (let h => gn_trypeek_head(it: *asn1::decoder)?) {
		if (h.tagid != gn::IP) {
			gn_skip(it)?;
			continue;
		};

		let d = it: *asn1::decoder;
		asn1::expect_implicit(d, h.class, h.tagid)?;
		let r = asn1::octetstrreader(d)?;

		switch (asn1::dsz(h)) {
		case size(ip::addr4) =>
			let addr: ip::addr4 = [0...];
			io::readall(&r, addr)?;
			return addr;
		case size(ip::addr6) =>
			let addr: ip::addr6 = [0...];
			io::readall(&r, addr)?;
			return addr;
		case =>
			return "bad ip address type": badformat;
		};
	};

	return done;
};

// Get the next name of type [[gn::IP]] (ipAddress).
export fn gn_next_ip(it: *gniter) (ip::addr | done | error) = {
	match (_gn_next_ip(it)) {
	case let addr: ip::addr =>
		return addr;
	case done =>
		return done;
	case let e: _error =>
		return norm_error(e);
	};
};

fn _gn_skip(it: *gniter) (void | done | _error) = {
	let h = match (gn_trypeek_head(it: *asn1::decoder)?) {
	case done =>
		return done;
	case let h: asn1::head =>
		yield h;
	};

	let br = asn1::bytereader(it: *asn1::decoder, h.class, h.tagid)?;
	io::copy(io::empty, &br)?;
	return done;
};

// Skips the next name.
export fn gn_skip(it: *gniter) (void | done | error) = {
	match (_gn_skip(it)) {
	case void =>
		return;
	case done =>
		return done;
	case let e: _error =>
		return norm_error(e);
	};
};

fn validate_dnsnamestr(name: str) (void | error) = {
	let b = strings::toutf8(name);
	let r = memio::fixed(b);
	match (validate_dnsname(&r)) {
	case void => void;
	case let e: _error =>
		return norm_error(e);
	};
};

fn validate_dnsname(r: io::handle) (void | _error) = {
	let buf: [256]u8 = [0...];
	let s = bufio::newscanner_buf(r, buf);

	let prev = ' ';
	let init_char = false;

	for (let c => bufio::read_byte(&s)?) {
		let c = c: rune;
		if (c == '*') {
			if (prev != ' ') {
				return "invalid dnsname": badformat;
			};
		} else if (c == '-') {
			if (prev == ' ' || prev == '.' || prev == '*'
					|| !init_char) {
				return "invalid dnsname": badformat;
			};
		} else if (c == '.') {
			if (prev == ' ' || prev == '-' || prev == '.') {
				return "invalid dnsname": badformat;
			};
			init_char = false;
		} else {
			if (!ascii::isalnum(c: rune) || prev == '*') {
				return "invalid dnsname": badformat;
			};
			init_char = true;
		};
		prev = c;
	};

	if (prev == ' ' || prev == '.' || prev == '-' || prev == '*') {
		return "invalid dnsname": badformat;
	};
};

@test fn validate_dns() void = {
	let cases: [](str, bool) = [
		(" ", false),
		("-", false),
		(".", false),
		("a", true),
		("1", true),
		("a.", false),
		("1-", false),
		("a-b", true),
		("a.b", true),
		("a--", false),
		("a.-", false),
		("a..", false),
		("a-.", false),
		("*", false),
		("harelang.org", true),
		("HARELANG.ORG", true),
		("hare-lang.org", true),
		("xn--abcdef-qua4k", true),
		("1.2.3.4", true),
		("*.harelang.org", true),
		("*harelang.org", false),
		("docs.*.harelang.org", false),
		("*.local", true),
	];

	for (let c .. cases) {
		let r = memio::fixed(strings::toutf8(c.0));
		match (validate_dnsname(&r)) {
		case void =>
			assert(c.1);
		case badformat =>
			assert(!c.1);
		case io::error =>
			abort();
		};
	};
};
