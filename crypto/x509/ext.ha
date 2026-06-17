// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::rsa;
use encoding::asn1;
use encoding::asn1::{oid};
use encoding::asn1::stdoid;
use endian;
use io;
use memio;

// Maximum number of allowed extensions per certificate.
export def MAXEXTSZ: size = 32;

fn parse_exts(c: *cert, d: *asn1::decoder) (void | _error) = {
	let h = match (asn1::trypeek(d)?) {
	case io::EOF =>
		if (c.version == version::V3) {
			// version SHOULD not be V3 if no extensions are present
			return "version 3 expects extensions": badformat;
		};
		return;
	case let h: asn1::head =>
		if (h.class != asn1::class::CONTEXT || h.tagid != 3
				|| c.version != version::V3) {
			return "bad extensions?": badformat; // TODO
		};
		yield h;
	};

	let rawoidlist: [128]u8 = [0...];

	def OIDBUFSZ: size = 64; // copied from enoding::asn1::read_rawoid
	let oidbuf: [OIDBUFSZ]u8 = [0...];

	let extpos = h.start;

	asn1::open_explicit(d, asn1::class::CONTEXT, 3)?;
	asn1::open_seq(d)?;

	for (let i = 0z; i < MAXEXTSZ; i += 1) {
		if (asn1::trypeek(d)? is io::EOF) {
			if (i == 0) {
				return "extensions expected": badformat;
			};
			break;
		};

		asn1::open_seq(d)?;

		let oidbuf: [asn1::OIDBUFSZ]u8 = [0...];
		let extid = asn1::read_rawoid(d, oidbuf)?;
		oidbuf[..len(extid)] = extid[..];
		let extid = oidbuf[..len(extid)];

		ext_checkdup(c, extpos, i, extid)?;

		let h = asn1::peek(d)?;
		const critical = if (h.tagid == asn1::utag::BOOLEAN) {
			yield asn1::read_bool(d)?;
		} else {
			yield false;
		};

		const parsed = parse_ext(c, d, extid, critical)?;

		if (!parsed && critical) {
			c.errcritext = true;
		};

		asn1::close_seq(d)?;
	};

	asn1::close_seq(d)?;
	asn1::close_explicit(d)?;
};

fn ext_checkdup(c: *cert, extpos: size, cur: size, oid: []u8) (void | error) = {
	if (len(oid) > 0xff) {
		return "oid too long": badformat;
	};
	if (cur == 0) {
		return;
	};

	let buf = memio::buffer(&c.h)[extpos..];
	let d = &asn1::derdecoder(&memio::fixed(buf));

	asn1::open_explicit(d, asn1::class::CONTEXT, 3)!;
	asn1::open_seq(d)!;

	for (let i = 0z; i < cur; i += 1) {
		asn1::open_seq(d)!;

		let oidbuf: [asn1::OIDBUFSZ]u8 = [0...];
		let refoid = asn1::read_rawoid(d, oidbuf)!;

		if (bytes::equal(refoid, oid)) {
			return "duplicate extensions": invalid;
		};

		let h = asn1::peek(d)!;
		if (h.tagid == asn1::utag::BOOLEAN) {
			asn1::read_bool(d)!;
		};

		let r = asn1::octetstrreader(d)!;
		io::copy(io::empty, &r)!;

		asn1::close_seq(d)!;
	};
};

// Parses an extension of type given by 'rawoid'. Returns true, if the
// extension is supported.
fn parse_ext(
	c: *cert,
	d: *asn1::decoder,
	rawoid: []u8,
	critical: bool
) (bool | _error) = {
	// Size limit is arbitrary.
	def MAX_UNKNOWNEXTSZ: size = 1024;
	let oid = match (asn1::oid_from_der(stdoid::db, rawoid)) {
	case let o: oid =>
		yield o;
	case void =>
		// Unknown oid.
		asn1::skip(d, asn1::utag::OCTET_STRING, 1024)?;
		return false;
	};
	let r = asn1::octetstrreader(d)?;

	switch (oid) {
	case stdoid::ID_CE_AUTHORITY_KEY_IDENTIFIER =>
		if (critical) {
			return "authority key identifier"
				" must not be critical": invalid;
		};
		ext_parse_aki(c, &r)?;
		// TODO must include this one, if not CA except self signed certs
	case stdoid::ID_CE_SUBJECT_KEY_IDENTIFIER =>
		if (critical) {
			return "subject key identifier"
				" must not be critical": invalid;
		};
		ext_parse_ski(c, &r)?;
	case stdoid::ID_CE_KEY_USAGE =>
		ext_parse_keyusage(c, &r)?;
	case stdoid::ID_CE_EXT_KEY_USAGE =>
		ext_parse_extkeyusage(c, &r)?;
	case stdoid::ID_CE_SUBJECT_ALT_NAME =>
		c.sanpos = io::tell(&c.h)!;
		ext_parse_altname(c, &r)?;
		if (len(c.subject) == 0 && !critical) {
			return "subjectAltName must be critical if "
				"subject is empty": invalid;
		};

		if (len(c.subject) != 0 && critical) {
			return "subjectAltname must not be critical if "
				"subject is not empty": invalid;
		};
	case stdoid::ID_CE_ISSUER_ALT_NAME =>
		c.ianpos = io::tell(&c.h)!;
		ext_parse_altname(c, &r)?;
	case stdoid::ID_CE_BASIC_CONSTRAINTS =>
		ext_parse_basicc(c, &r)?;
		if (c.ca && !critical) {
			c.flaws |= flaw::NONCRIT_BASICC;
			// TODO return "basic constraint must be critical for "
				//"certificate authorities": invalid;
		};
	case stdoid::ID_CE_NAME_CONSTRAINTS =>
		if (!c.ca) {
			return "NameConstraints must only be used from "
				"certificate authorities": invalid;
		};
		if (!critical) {
			return "NameConstraints extension"
				" must be critical": invalid;
		};
		io::copy(io::empty, &r)?; // TODO parse
		return false;
	case stdoid::ID_CE_POLICY_CONSTRAINTS =>
		if (c.ca && !critical) {
			return "policy constraints must be critical for "
				"certificate authorities": invalid;
		};
		io::copy(io::empty, &r)?; // TODO parse
		return false;
	case stdoid::ID_PE_AUTHORITY_INFO_ACCESS =>
		if (critical) {
			return "authority info access"
				" must not be critical": invalid;
		};
		ext_parse_aia(c, &r)?;
	case =>
		io::copy(io::empty, &io::limitreader(&r, MAX_UNKNOWNEXTSZ))?;
		return false;
	};

	return true;
};

fn ext_parse_keyusage(c: *cert, r: io::handle) (void | _error) = {
	let ed = asn1::derdecoder(r);
	let ku: [2]u8 = [0...];
	let aku = asn1::read_bitstr(&ed, ku)?;

	// check max value
	if (len(aku.0) == size(keyusage) && aku.1 != 7) {
		return "bad key usage": badformat;
	};

	let ku = endian::begetu16(ku);
	c.keyusage = ku;
	if (ku == 0) {
		return "non zero keyusage expected": invalid;
	};
};

// Returns the keyusage bitmap. See the [[keyusage]] type for possible bit
// values. Returns void, if keyusage is not available.
export fn cert_keyusage(c: *cert) (void | u16) = c.keyusage;

fn ext_parse_extkeyusage(c: *cert, r: io::handle) (void | _error) = {
	let d = &asn1::derdecoder(r);
	asn1::open_seq(d)?;

	for (let i = 0z; i < 7; i += 1) {
		if (asn1::trypeek(d)? is io::EOF) {
			if (i == 0) {
				return "empty extended key"
					" usage sequence": badformat;
			};
			break;
		};

		let oidbuf: [asn1::OIDBUFSZ]u8 = [0...];
		let raw = asn1::read_rawoid(d, oidbuf)?;
		let eki = match (asn1::oid_from_der(stdoid::db, raw)) {
		case let o: oid =>
			yield o;
		case void =>
			return "unknown extended key usage id": badformat;
		};

		c.extkeyusage |= switch (eki) {
		case stdoid::ANY_EXTENDED_KEY_USAGE =>
			yield extkeyusage::ANY;
		case stdoid::ID_KP_SERVER_AUTH =>
			yield extkeyusage::SERVER_AUTH;
		case stdoid::ID_KP_CLIENT_AUTH =>
			yield extkeyusage::CLIENT_AUTH;
		case stdoid::ID_KP_CODE_SIGNING =>
			yield extkeyusage::CODE_SIGNING;
		case stdoid::ID_KP_EMAIL_PROTECTION =>
			yield extkeyusage::EMAIL_PROTECTION;
		case stdoid::ID_KP_TIME_STAMPING =>
			yield extkeyusage::TIME_STAMPING;
		case stdoid::ID_KP_OCSPSIGNING =>
			yield extkeyusage::OCSP_SIGNING;
		case =>
			return "unknown extended key usage id": badformat;
		};

	};
	asn1::close_seq(d)?;
};


// Returns an iterator over the subject alternative names, if available.
//
// To iterate over a specific name type, use one of the following functions:
// [[gn_next_dns]], [[gn_next_ip]].
//
// To iterate over all the name use [[gn_trypeek]] combined with the previously
// mentioned functions.
//
//	for (let gn => gn_trypeek(iter)?) {
//		switch (gn) {
//		case gn::DNS =>
//			let reader = gn_next_dns(iter)? as utf8reader;
//			// ... read all of 'reader'
//		case gn::IP =>
//			let addr = gn_next_ip(iter)? as ip::addr;
//			// ...
//		case =>
//			// skip ones that aren't relevant
//			gn_skip(iter)?;
//		};
//	};
//
export fn cert_subjectan(c: *cert) (gniter | void | error) = {
	const sanpos = match (c.sanpos) {
	case void =>
		return void;
	case let s: io::off =>
		yield s;
	};

	return match (newgniter(c, sanpos)) {
	case let g: gniter =>
		return g;
	case let e: _error =>
		return norm_error(e);
	};
};

// Returns an iterator over the issuer alternative names, if available.
// See [[cert_subjectan]] for instructions on how to use it.
export fn cert_issueran(c: *cert) (gniter | void | error) = {
	const ianpos = match (c.ianpos) {
	case void =>
		return void;
	case let s: io::off =>
		yield s;
	};

	return match (newgniter(c, ianpos)) {
	case let g: gniter =>
		return g;
	case let e: _error =>
		return norm_error(e);
	};
};


fn ext_parse_altname(c: *cert, r: io::handle) (void | _error) = {
	// TODO
	// ..., if the only subject identity included in the certificate is
	// an alternative name form (e.g., an electronic mail address), then the
	// subject distinguished name MUST be empty (an empty sequence), and the
	// subjectAltName extension MUST be present.  If the subject field
	// contains an empty sequence, then the issuing CA MUST include a
	// subjectAltName extension that is marked as critical.  When including
	// the subjectAltName extension in a certificate that has a non-empty
	// subject distinguished name, conforming CAs SHOULD mark the
	// subjectAltName extension as non-critical.

	let it = asn1::derdecoder(r);
	asn1::open_seq(&it)?;
	asn1::peek(&it)?; // must have one record

	// TODO max
	for (let t => gn_trypeek(&it)?) {
		switch (t) {
		case gn::DNS =>
			let r = gn_next_dns(&it)? as utf8reader;
			validate_dnsname(&r)?;
		case gn::IP =>
			gn_next_ip(&it)?;
		case =>
			gn_skip(&it)?;
		};
	};

	gn_close(&it)?;
};

fn ext_parse_basicc(c: *cert, r: io::handle) (void | _error) = {
	let d = asn1::derdecoder(r);
	asn1::open_seq(&d)?;
	if (asn1::trypeek(&d)? is io::EOF) {
		c.ca = false;
		return;
	};
	c.ca = asn1::read_bool(&d)?;
	if (asn1::trypeek(&d)? is io::EOF) {
		return;
	};
	c.maxpathlen = asn1::read_u16(&d)?;
	asn1::close_seq(&d)?;
};

export type ia = enum {
	OCSP,
	CA_ISSUERS,
};

fn ext_parse_aia(c: *cert, r: io::handle) (void | _error) = {
	let d = asn1::derdecoder(r);
	asn1::open_seq(&d)?;
	let one = false;
	for (let h => asn1::trypeek(&d)?) {
		one = true;

		asn1::open_seq(&d)?;

		let oidbuf: [asn1::OIDBUFSZ]u8 = [0...];
		let method = asn1::read_rawoid(&d, oidbuf)?;
		let method = match (asn1::oid_from_der(stdoid::db, method)) {
		case let o: oid =>
			switch (o) {
			case stdoid::ID_AD_OCSP, stdoid::ID_AD_CA_ISSUERS => void;
			case =>
				return "authority info: invalid access method": badformat;
			};
			yield o;
		case void =>
			return "authority info: invalid access method": badformat;
		};
		let t = gn_peek(&d)?;
		switch (t) {
		case gn::URI =>
			let s = gn_uri(&d)?;
			io::copy(io::empty, &s)?;
		case gn::DNS =>
			let s = gn_dns(&d)?;
			io::copy(io::empty, &s)?;
		case =>
			return "unsupported authorty info value": badformat;
		};
		asn1::close_seq(&d)?;
	};

	if (!one) {
		return "at least one authority info access description"
			"required": badformat;
	};

	asn1::close_seq(&d)?;
	return;
};

// Arbitrary limit for maximum key identifiers to prevent misuse of this fields.
def MAXKISZ: size = 1024;

fn ext_parse_aki(c: *cert, r: io::handle) (void | _error) = {
	let d = asn1::derdecoder(r);
	let bufoff = io::seek(&c.h, 0, io::whence::CUR)!: size;
	let first = true;
	asn1::open_seq(&d)?;
	for (let i = 0z; i < 3; i += 1) {
		let pos = io::tell(&c.h)!;
		let h = asn1::trypeek(&d)?;
		if (h is io::EOF) {
			if (i == 0) return "empty aki": badformat;
			break;
		};
		let h = h as asn1::head;

		switch (h.tagid) {
		case 0 =>
			asn1::expect_implicit(&d, asn1::class::CONTEXT, 0)?;
			c.aki = borrow_data(c, &d,
				asn1::utag::OCTET_STRING, MAXKISZ, bufoff)?;
		case 1 =>
			c.flaws |= flaw::COMPLEX_AKI;
			asn1::open_explicit(&d, asn1::class::CONTEXT, 1)?;
			for (let gn => gn_trypeek(&d)?) {
				gn_skip(&d)?;
			};
			asn1::close_explicit(&d)?;
		case 2 =>
			c.flaws |= flaw::COMPLEX_AKI;
			let buf: [128]u8 = [0...];
			asn1::expect_implicit(&d, asn1::class::CONTEXT, 2)?;
			asn1::read_int(&d, buf)?;
		case =>
			return "invalid aki extension": badformat;
		};
	};
	asn1::close_seq(&d)?;
	return void;
};

fn ext_parse_ski(c: *cert, r: io::handle) (void | _error) = {
	let d = asn1::derdecoder(r);
	let bufoff = io::seek(&c.h, 0, io::whence::CUR)!: size;
	c.ski = borrow_data(c, &d, asn1::utag::OCTET_STRING, MAXKISZ, bufoff)?;
	asn1::finish(&d)?;
};

// Returns the authority key identifier. The value is borrowed from 'c'.
export fn cert_aki(c: *cert) []u8 = c.aki;

// Returns the subject key identifier. The value is borrowed from 'c'.
export fn cert_ski(c: *cert) []u8 = c.ski;
