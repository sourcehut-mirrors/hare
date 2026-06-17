// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use bufio;
use errors;
use io;
use memio;
use net::ip;
use strings;

// checks if 'hostname' matches to 'pattern'. Both must be valid dns names.
// [[validate_dnsname]] is available to check them.
fn dns_match(pattern: io::handle, hostname: str) (bool | io::error) = {
	let first = true;
	let r = memio::fixed(strings::toutf8(hostname));

	for (let b => bufio::read_byte(pattern)?) {
		if (b == '*': u8) {
			assert(first, "pattern is not valid");

			first = false;
			for (let c => bufio::read_byte(&r)?) {
				if (c == '*': u8) {
					return false;
				};
				if (c == '.': u8) {
					match (bufio::read_byte(pattern)?) {
					case io::EOF =>
						return false;
					case let b: u8 =>
						assert(b == '.': u8,
							"pattern is not valid");
					};
					break;
				};
			};

			continue;
		};
		first = false;

		match (bufio::read_byte(&r)?) {
		case io::EOF =>
			return false;
		case let c: u8 =>
			if (c == '*': u8) {
				return false;
			};
			if (ascii::tolower(b: rune)
					!= ascii::tolower(c: rune)) {
				return false;
			};
		};
	};

	return bufio::read_byte(&r)? is io::EOF;
};

@test fn dns_match() void = {
	let cases = [
		("id.org", "id.org", true),
		("id.org", "ID.org", true),
		("id.org.com", "id.org", false),
		("id.org", "id.org.com", false),
		("noid.org", "id.org", false),
		("*.local", "test.local", true),
		("*.local", "local", false),
		("*.local", "*.local", false),
		("*.local", "dev.localb", false),
		("*.local", "dev.loca", false),
		("*.local", "dev.local.b", false),
	];

	for (let c .. cases) {
		let s = memio::fixed(strings::toutf8(c.0));
		assert(dns_match(&s, c.1)! == c.2);
	};
};

// Verifies if given the certificate 'c' matches 'host'. Does not verify
// the certificate itself. See [[verify]] or [[verifier]] for how to find
// a trust path for 'c'.
//
// If the name is a [[dnsname]], it must be provided as A-label according to
// RFC 6125. Wildcards are allowed but only on the leftmost part.
export fn cert_verify_hostname(c: *cert, host: name) (void | error) = {
	match (host) {
	case let d: dnsname =>
		return cert_verify_dnsname(c, d);
	case let addr: ip::addr =>
		return cert_verify_ip(c, addr);
	case =>
		return "not implemented": unsupported;
	};
};


fn cert_verify_dnsname(c: *cert, host: dnsname) (void | error) = {
	let r = memio::fixed(strings::toutf8(host));
	match (validate_dnsname(&r)) {
	case void => void;
	case let e: _error =>
		return norm_error(e);
	};

	let it = match (cert_subjectan(c)?) {
	case void =>
		return errors::invalid;
	case let it: gniter =>
		yield it;
	};

	def NAMEBUFSZ: size = 256;
	let buf: [NAMEBUFSZ]u8 = [0...];
	for (let p => gn_next_dns(&it)?) {
		let s = bufio::newscanner_buf(&p, buf);
		match (dns_match(&s, host)) {
		case let valid: bool =>
			if (valid) return;
		case io::error =>
			// buffered read won't throw an io::error
			abort();
		};
	};

	return "no matching dnsname in cert": invalid;
};

fn cert_verify_ip(c: *cert, addr: ip::addr) (void | error) = {
	let it = match (cert_subjectan(c)?) {
	case void =>
		return errors::invalid;
	case let it: gniter =>
		yield it;
	};

	for (let caddr => gn_next_ip(&it)?) {
		if (ip::equal(caddr, addr)) {
			return;
		};
	};

	return "no matching ip in cert": invalid;
};
