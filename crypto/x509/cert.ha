// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::rsa;
use crypto::sha256;
use encoding::asn1;
use encoding::asn1::{oid};
use encoding::asn1::stdoid;
use encoding::hex;
use encoding::pem;
use endian;
use errors;
use fmt;
use hash;
use io;
use log;
use memio;
use os;
use strings;
use time::date;
use types;

// The sizes of certificates vary and typically depend on the size of the
// public key. Certificates with RSA public keys of 4096 bits can reach
// around 2 kilobyte. With coming post quantum key algorithms in mind,
// 4096 may be a safer call.
//
// This size should only be used as a guideline, since the certificate
// sizes may also vary on the use case.
export def CERTBUFSZ: size = 4096;

export def MAXSNSZ = 20z;

// Maximum accepted size of an issuer/subject UniqueIdentifier BIT STRING.
def MAXUIDSZ: size = 1024;

export type version = enum u8 {
	V1 = 0,
	V2 = 1,
	V3 = 2,
};

export fn strsigalgo(s: asn1::oid) str = asn1::stroid(stdoid::db, s);

// Maximum size of a signature considering all supported algorithms.
def MAX_SIGSZ: size = rsa::BITSZ / 8;

// Represents a parsed certificate. For obtaining a [[cert]] take a look at
// [[parse_pemcerts]], [[parse_cert]] or [[parse_certbuf]].
export type cert = struct {
	h: memio::stream,
	sz: size,

	tbscert: []u8,
	pubkey: []u8,
	sig: []u8,

	sigalgo: asn1::oid,
	sigparams: sigparams,

	version: version,
	ca: bool,
	errcritext: bool,
	maxpathlen: (void | u16),

	keyusage: (void | u16),
	extkeyusage: u8,

	sn: []u8,

	validfrom: date::date,
	validto: date::date,

	issuer: []u8,
	subject: []u8,

	issueruid: []u8,
	subjectuid: []u8,

	selfsigned: bool,
	owned: bool,
	flaws: u32,
	err: (void | error),

	aki: []u8,
	ski: []u8,

	sanpos: (void | io::off),
	ianpos: (void | io::off),
};

// Serial number borrowed from 'c'.
export fn cert_sn(c: *cert) []u8 = c.sn;

// Writes the DER representation of 'c' to 'dest'.
export fn cert_derencode(c: *cert, dest: io::handle) (void | io::error) = {
	io::seek(&c.h, 0, io::whence::SET)!;
	io::copy(dest, &io::limitreader(&c.h, c.sz))?;
};

// Writes the cert in the PEM format to 'dest'.
export fn cert_pemencode(c: *cert, dest: io::handle) (void | io::error) = {
	let p = pem::newencoder("CERTIFICATE", dest)?;
	cert_derencode(c, &p)?;
	io::close(&p)?;
};

// Returns the DER encoded size of the cert.
export fn cert_sz(c: *cert) size = c.sz;

fn parse_sz(src: io::handle) ((size, size) | error) = {
	let d = asn1::derdecoder(src);
	match (asn1::peek(&d)) {
	case let h: asn1::head =>
		return (asn1::sz(h), asn1::dsz(h));
	case let e: asn1::error =>
		return norm_error(e);
	};
};

// Reads the entire cert from 'src'. If 'buf' is provided the cert is borrowed
// from it and the caller is responsible to free the resources after use. If
// 'buf' is not provided, this function will allocate space in order to store
// the cert. [[cert_free]] must then be called to free the memory after use.
//
// See [[CERTBUFSZ]] for a buffer size recommendation.
export fn parse_cert(src: io::handle, buf: []u8 = []) (cert | nomem | error) = {
	let (mem, owned) = if (len(buf) == 0) {
		let mem = memio::dynamic();
		yield (mem, false);
	} else {
		let mem = memio::fixed(buf);
		yield (mem, true);
	};

	let ok = false;
	defer if (!ok) {
		io::close(&mem)!;
	};

	let t = io::tee(src, &mem);
	let sz = parse_sz(&t)?;

	// read t to copy the remaining bytes to mem
	io::copy(io::empty, &io::limitreader(&t, sz.1))?;
	io::seek(&mem, 0, io::whence::SET)!;

	let c = open_cert(mem)?;
	c.owned = owned;
	ok = true;
	return c;
};

// Reads PEM encoded certificates and stores them into allocated buffers.
// [[certs_free]] must be used in order to free the used resources.
export fn parse_pemcerts(
	src: io::handle,
) ([]cert | nomem | error | io::error) = {
	let pd = pem::newdecoder(src);
	defer pem::finish(&pd);

	let certs: []cert = [];

	let ok = false;
	defer if (!ok) certs_free(certs);

	for (let p => pem::next(&pd)?) {
		if (p.0 != "CERTIFICATE") {
			return errors::invalid: error;
		};
		let crt = parse_cert(&p.1)?;
		match (append(certs, crt)) {
		case void => void;
		case nomem =>
			cert_free(&crt);
			return nomem;
		};
	};

	ok = true;
	return certs;
};

// Frees allocated buffer of 'c', if created with [[parse_cert]] or
// [[parse_certbuf]]. Has no effect otherwise.
export fn cert_free(c: *cert) void = {
	io::close(&c.h)!;
};

// Frees the allocated space of 'certs'.
export fn certs_free(certs: []cert) void = {
	for (let c &..certs) {
		cert_free(c);
	};
	free(certs);
};

// Parses and takes ownership of a cert stored in 'b'. The cert must be DER
// encoded. [[cert_free]] must be called to free resources after use, if 'b' is
// an allocated buffer.
export fn parse_certbuf(b: []u8) (cert | error) = {
	let c = open_cert(memio::dynamic_from(b))?;
	c.owned = true;
	return c;
};

// Opens a cert provided by 'h'. Does not allocate memory. 'h' must not be used
// while the cert is open.
fn open_cert(h: memio::stream) (cert | error) = {
	let c = cert {
		h = h,
		version = version::V1,
		validfrom = date::now(),
		validto = date::now(),
		ca = false,
		errcritext = false,
		maxpathlen = void,
		keyusage = void,
		sanpos = void,
		ianpos = void,
		owned = false,
		sigparams = void,
		err = void,
		...
	};

	match (read_cert(&c)) {
	case void =>
		return c;
	case let e: _error =>
		return norm_error(e);
	};
};

fn read_cert(c: *cert) (void | _error) = {
	let d = asn1::derdecoder(&c.h);

	const h = asn1::peek(&d)?;
	c.sz = asn1::sz(h);

	asn1::open_seq(&d)?;
	cert_parse(c, &d)?;
	cert_parse_sig(c, &d)?;
	asn1::close_seq(&d)?;

	c.selfsigned = cert_selfsigned(c);
	c.err = validate(c);
};

// Borrows asn1 encoded data from the cert buffer.
fn borrow_data(
	s: *memio::stream,
	d: *asn1::decoder,
	t: asn1::utag,
	maxsz: size,
	off: size = 0,
) ([]u8 | asn1::error) = {
	let h = asn1::peek(d)?;
	asn1::skip(d, t, maxsz)?;
	let buf = memio::buffer(s);
	return buf[off+h.data..off+h.end];
};

fn cert_parse(c: *cert, d: *asn1::decoder) (void | _error) = {
	const h = asn1::peek(d)?;

	asn1::open_seq(d)?;

	c.version = parse_version(d)?;
	c.sn = borrow_data(&c.h, d, asn1::utag::INTEGER, MAXSNSZ)?;

	asn1::open_seq(d)?;
	let (algo, params) = parse_sigalgo(d)?;
	c.sigalgo = algo;
	c.sigparams = params;
	asn1::close_seq(d)?;

	c.issuer = parse_dn(c, d)?;
	if (len(c.issuer) == 0) {
		return "Empty issuer": badformat;
	};

	asn1::open_seq(d)?;
	c.validfrom = read_date(d)?;
	c.validto = read_date(d)?;
	asn1::close_seq(d)?;

	c.subject = parse_dn(c, d)?;

	let pubkeyh = validate_pubkey(d, &c.h)?;

	parse_uids(c, d)?;
	parse_exts(c, d)?;
	asn1::close_seq(d)?;

	let buf = memio::buffer(&c.h);
	c.pubkey = buf[pubkeyh.start..pubkeyh.end];
	c.tbscert = buf[h.start..h.end];
};

fn parse_version(d: *asn1::decoder) (version | _error) = {
	const h = asn1::peek(d)?;
	if (h.class != asn1::class::CONTEXT) {
		return version::V1;
	};

	if (h.tagid != 0) {
		return errors::invalid;
	};

	asn1::open_explicit(d, asn1::class::CONTEXT, 0)?;
	const v = asn1::read_u8(d)?;
	if (v > version::V3) {
		return errors::invalid;
	};
	asn1::close_explicit(d)?;
	return v: version;
};

fn parse_sigalgo(d: *asn1::decoder) ((asn1::oid, sigparams) | _error) = {
	const sigid = asn1::read_oid(d, stdoid::db)?;
	switch (sigid) {
	case stdoid::RSA_ENCRYPTION,
			stdoid::SHA1_WITH_RSAENCRYPTION,
			stdoid::SHA256_WITH_RSAENCRYPTION,
			stdoid::SHA384_WITH_RSAENCRYPTION,
			stdoid::SHA512_WITH_RSAENCRYPTION =>
		asn1::read_null(d)?;
		return (sigid, void);
	case stdoid::RSASSA_PSS =>
		const params = rsa_parse_pssparams(d)?;
		return (sigid, params);
	case stdoid::ED25519,
			stdoid::ECDSA_WITH_SHA1,
			stdoid::ECDSA_WITH_SHA256,
			stdoid::ECDSA_WITH_SHA384,
			stdoid::ECDSA_WITH_SHA512 =>
		return (sigid, void);
	case =>
		return unknownalgo;
	};
};

def MAXUTCYEAR = 2049u16;

fn read_date(d: *asn1::decoder) (date::date | _error) = {
	let h = asn1::peek(d)?;
	switch (h.tagid) {
	case asn1::utag::UTC_TIME =>
		return asn1::read_utctime(d, MAXUTCYEAR)?;
	case asn1::utag::GENERALIZED_TIME =>
		let dt = asn1::read_gtime(d)?;
		if (date::nanosecond(&dt) != 0) {
			return "Nanoseconds not allowed": badformat;
		};
		return dt;
	case =>
		return "Invalid date": badformat;
	};
};

export type dniter = struct {
	h: memio::stream,
	d: asn1::decoder,
	first: bool,
};

export fn newdniter() dniter = dniter {
	h = @undefined,
	d = @undefined,
	first = true,
};

// Initialized an iterator for reading the distinguished names of 'rawdn'. Use
// [[dn_next]] to iterate over the entries.
export fn dniter_init(it: *dniter, rawdn: []u8) (void | error) = {
	it.h = memio::fixed(rawdn);
	it.d = asn1::derdecoder(&it.h);

	match (asn1::open_seq(&it.d)) {
	case void => void;
	case let e: asn1::error =>
		return norm_error(e);
	};

	match (asn1::trypeek(&it.d)) {
	case asn1::head => void;
	case io::EOF =>
		// must have at least one.
		return "empty distinguished name": badformat;
	case let e: asn1::error =>
		return norm_error(e);
	};
};

export type utf8reader = asn1::utf8stream;

// Returns the next distinguished name as a tuple of the raw oid and a value
// reader as [[io::stream]]. The value must be read before calling [[dn_next]]
// again. The raw oid is borrowed from a static buffer. The reader returns
// valid UTF-8 multi bytes [[utf8reader]] or an error on encoding failures.
export fn dn_next(iter: *dniter) (([]u8, utf8reader) | done | error) = {
	if (iter.first) {
		iter.first = false;
	} else {
		match (close_dn(&iter.d)) {
		case void => void;
		case let e: _error =>
			return norm_error(e);
		};
	};

	match (open_dn(&iter.d)) {
	case let r: ([]u8, size, utf8reader) =>
		let (oid, sz, src) = r;
		return (oid, src);
	case io::EOF =>
		return done;
	case let e: _error =>
		return norm_error(e);
	};
};

// returns the next distinguished name (oid, size and value stream) on success.
// The oid is borrowed from a static buffer.
fn open_dn(d: *asn1::decoder) (([]u8, size, utf8reader) | io::EOF | _error) = {
	if (asn1::trypeek(d)? is io::EOF) {
		return io::EOF;
	};

	asn1::open_set(d)?;
	asn1::open_seq(d)?;

	static let oidbuf: [asn1::OIDBUFSZ]u8 = [0...];
	const id = asn1::read_rawoid(d, oidbuf)?;

	let h = asn1::peek(d)?;
	let tag = switch (h.tagid) {
	case asn1::utag::PRINTABLE_STRING,
			asn1::utag::UTF8_STRING,
			asn1::utag::IA5_STRING,
			asn1::utag::UNIVERSAL_STRING,
			asn1::utag::TELETEX_STRING,
			asn1::utag::BMP_STRING =>
		yield h.tagid: asn1::utag;
	case =>
		return "invalid string format": badformat;
	};

	let ss = asn1::strreader(d, tag)?;

	// TODO validate fields, length, constrained by ISO 3166 alpha-2 codes only
	return (id, asn1::dsz(h), ss);
};

fn close_dn(d: *asn1::decoder) (void | _error) = {
	asn1::close_seq(d)?;
	asn1::close_set(d)?;
};

fn parse_dn(c: *cert, d: *asn1::decoder) ([]u8 | _error) = {
	let h = asn1::peek(d)?;
	asn1::open_seq(d)?;

	if (asn1::trypeek(d)? is io::EOF) {
		asn1::close_seq(d)?;
		return [];
	};

	// TODO max?
	for (let p => open_dn(d)?) {
		if (p.1 > types::U16_MAX) {
			return "dn type overflow": badformat;
		};
		io::copy(io::empty, &p.2)?;
		close_dn(d)?;
	};

	asn1::close_seq(d)?;
	return memio::buffer(&c.h)[h.start..h.end];
};

type tag = enum u32 {
	VERSION = 0,
	ISSUER_UID = 1,
	SUBJECT_UID = 2,
	EXTENSIONS = 3,
};

fn parse_uids(c: *cert, d: *asn1::decoder) (void | _error) = {
	for (let i: u64 = 1; i <= 2; i += 1) {
		let h = match (asn1::trypeek(d)?) {
		case io::EOF =>
			return;
		case let h: asn1::head =>
			yield h;
		};

		if (h.class != asn1::class::CONTEXT) {
			return;
		};

		if (h.tagid != i) {
			continue;
		};

		if (c.version == version::V1) {
			return "expected version > 1 when uids present": badformat;
		};

		asn1::expect_implicit(d, asn1::class::CONTEXT, i: u32)?;
		asn1::skip(d, asn1::utag::BITSTRING, MAXUIDSZ)?;

		let buf = memio::buffer(&c.h);
		switch (h.tagid) {
		case tag::ISSUER_UID =>
			// bitstr contains an unused bits field in the first
			// byte, which is not part of the actual value.
			c.issueruid = buf[h.data+1..h.end];
		case tag::SUBJECT_UID =>
			c.subjectuid = buf[h.data+1..h.end];
		case =>
			abort(); // unreachable
		};
	};
};

fn validate(c: *cert) (void | error) = {
	if (len(c.subject) == 0 && c.sanpos is void) {
		return "subjectAltName required if subject is empty": invalid;
	};

	match (c.keyusage) {
	case void => void;
	case let ku: u16 =>
		if (!c.ca && ku & keyusage::KEY_CERT_SIGN == keyusage::KEY_CERT_SIGN) {
			return "only a certificate authority may have "
				"keyCertSign set": invalid;
		};

		if (c.ca && ku & keyusage::KEY_CERT_SIGN != keyusage::KEY_CERT_SIGN) {
			return "certificate authority"
				" must have keyCertSign set": invalid;
		};
	};

	if (c.ca && len(c.ski) == 0) {
		return "certificate authority must have a ski": invalid;
	};

	if (c.selfsigned && len(c.ski) != 0 && len(c.aki) != 0) {
		let ski = cert_ski(c);
		let aki = cert_aki(c);
		if (!bytes::equal(aki, ski)) {
			return "ski aki mismatch": invalid;
		};
	};

};

fn cert_parse_sig(c: *cert, d: *asn1::decoder) (void | _error) = {
	const h = asn1::peek(d)?;

	asn1::open_seq(d)?;
	let (sigalgo, sigparams) = parse_sigalgo(d)?;
	if (c.sigalgo != sigalgo || !sigparams_equal(c.sigparams, sigparams)) {
		return "proclaimed cert signature algorithm"
			" doesn't match actual one": badsig;
	};
	asn1::close_seq(d)?;

	const h = asn1::peek(d)?;
	let sr = asn1::bytereader(d, asn1::class::UNIVERSAL,
		asn1::utag::BITSTRING)!;

	let unused: [1]u8 = [0xff...];
	io::readall(&sr, unused)?;
	if (unused[0] != 0) {
		return "bad signature format": badsig;
	};
	io::copy(io::empty, &sr)?;

	let buf = memio::buffer(&c.h);
	c.sig = buf[h.data+1..h.end];
};

fn cert_equals(a: *cert, b: *cert) bool = bytes::equal(
	memio::buffer(&a.h), memio::buffer(&b.h));

// Verifies if given signature 'sig' on message 'msg' is valid against the
// certificate 'c'.
//
// This is a low level API and only uses the public key and signature
// algorithm of 'c', without validating any certificate attributes.
export fn cert_checksig(
	c: *cert,
	algo: asn1::oid,
	msg: io::handle,
	sig: []u8,
	params: sigparams = void,
) (void | badsig | io::error) = {
	let pub: pubkey = @undefined;
	match (cert_pubkey(c, &pub)) {
	case void => void;
	case let e: error =>
		// XXX make sure this is the only error returned by cert_pubkey
		return weakparams;
	};
	pubkey_verify(&pub, msg, algo, sig, params)?;
};

fn cert_checksigfrom(c: *cert, p: *cert) (void | badsig) = {
	let tbs = memio::fixed(c.tbscert);
	match (cert_checksig(p, c.sigalgo, &tbs, c.sig, c.sigparams)) {
	case void => void;
	case let e: badsig =>
		return e;
	case io::error =>
		// reading sig from cert must not fail
		abort();
	};
};

fn selfissued(c: *cert) bool = bytes::equal(c.issuer, c.subject);

fn cert_selfsigned(c: *cert) bool = {
	if (!selfissued(c)) {
		return false;
	};

	match (cert_checksigfrom(c, c)) {
	case void =>
		return true;
	case badsig =>
		return false;
	};
};

// Loads the public key of 'c' into 'pub'.
export fn cert_pubkey(c: *cert, pub: *pubkey) (void | error) = {
	// XXX restrict possible errors. asn1 shouldn't occur here, since
	//      it's parsed already
	let m = memio::fixed(c.pubkey);
	match (pubkey_parse(pub, &m)) {
	case void => void;
	case let e: _error =>
		return norm_error(e);
	};
};
