// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::ec;
use crypto::ecdsa;
use crypto::ed25519;
use crypto::rsa;
use crypto::sha1;
use crypto::sha256;
use crypto::sha512;
use encoding::asn1;
use encoding::asn1::{oid};
use encoding::asn1::stdoid;
use encoding::pem;
use errors;
use hash;
use io;
use log;
use memio;


// Additional signature parameters.
export type sigparams = (void | rsapssparams);

fn sigparams_equal(a: sigparams, b: sigparams) bool = {
	match (a) {
	case let p: void =>
		return b is void;
	case let p: rsapssparams =>
		if (!(b is rsapssparams)) {
			return false;
		};
		return rsapssparams_equal(p, b as rsapssparams);
	};
};

export type verifyfn = fn(
	pub: *pubkey,
	msg: io::handle,
	algo: asn1::oid,
	sig: []u8,
	params: sigparams,
) (size | badsig | io::error);

export type pubkey_vtable = struct {
	verify: *verifyfn,
};

export type signfn = fn(
	priv: *privkey,
	sink: io::handle,
	msg: []u8,
	algo: asn1::oid,
	params: sigparams
) (size | invalid | unsupported | io::error);


export type privkey_vtable = struct {
	sign: *signfn,
};

fn invalidverify(
	pub: *pubkey,
	msg: io::handle,
	algo: asn1::oid,
	sig: []u8,
	params: sigparams,
) (size | badsig | io::error) = "undefined verification function": badsig;

const invalidpubkey_vtable = pubkey_vtable {
	verify = &invalidverify,
};

export type ec_pubkey = struct {
	id: oid,
	union {
		p256: ecdsa::p256pubkey,
		p384: ecdsa::p384pubkey,
		p521: ecdsa::p521pubkey,
	},
};

export type pubkey = struct {
	vt: *pubkey_vtable,
	union {
		rsa: [rsa::PUBKEYSZ]u8,
		ed25519: [ed25519::PUBKEYSZ]u8,
		ec: ec_pubkey,
	},
};

// Creates an uninitialized public key.
export fn newpubkey() pubkey = pubkey {
	vt = &invalidpubkey_vtable,
};

// Verifies a signature with given public key 'p'. Returns the number of bytes
// read from 'msg' on success.
export fn pubkey_verify(
	p: *pubkey,
	msg: io::handle,
	algo: asn1::oid,
	sig: []u8,
	params: sigparams = void
) (size | badsig | io::error) = p.vt.verify(p, msg, algo, sig, params);

// Validates the public key structure, but doesn't check if it's a weak
// public key.
fn validate_pubkey(
	d: *asn1::decoder,
	mem: *memio::stream
) (asn1::head | _error) = {
	let h = asn1::peek(d)?;
	asn1::open_seq(d)?;

	asn1::open_seq(d)?;
	let keyoid = asn1::read_oid(d, stdoid::db)?;

	switch (keyoid) {
	case stdoid::ED25519 =>
		ed25519_parse(d, mem)?;
	case stdoid::RSA_ENCRYPTION =>
		asn1::read_null(d)?;
		asn1::close_seq(d)?;
		rsa_validate(d, mem)?;
	case stdoid::RSASSA_PSS =>
		asn1::close_seq(d)?;
		rsa_validate(d, mem)?;
	case stdoid::ID_EC_PUBLIC_KEY =>
		ec_validate(d)?;
	case =>
		return errors::unsupported;
	};

	return h;
};

// Must only be called after the input in 'd' has been validated with
// [[validate_pubkey]]
fn pubkey_parse(p: *pubkey, mem: *memio::stream) (void | _error) = {
	let d = &asn1::derdecoder(mem);

	// since the format is already validated, we can assert results here.
	asn1::open_seq(d)!;

	asn1::open_seq(d)!;
	let keyoid = asn1::read_oid(d, stdoid::db)!;

	switch (keyoid) {
	case stdoid::ED25519 =>
		ed25519_init(p, d, mem);
	case stdoid::RSA_ENCRYPTION =>
		asn1::read_null(d)!;
		asn1::close_seq(d)!;
		rsa_init(p, d, mem)?;
	case stdoid::RSASSA_PSS =>
		asn1::close_seq(d)!;
		rsa_init(p, d, mem)?;
		// XXX store key params to pubkey?
	case stdoid::ID_EC_PUBLIC_KEY =>
		ec_init(p, d, mem);
	case =>
		abort(); // would've failed already in validate_pubkey
	};

	asn1::finish(d)!;
};

export type keytype = enum {
	RSA,
	RSAPSS,
	ED25519,
	P256,
	P384,
	P521,
};

export type privkey = struct {
	vt: *privkey_vtable,
	t: keytype,
	union {
		rsa: [rsa::PRIVKEYSZ]u8,
		ed25519: [ed25519::PRIVKEYSZ]u8,
		p256: ecdsa::p256privkey,
		p384: ecdsa::p384privkey,
		p521: ecdsa::p521privkey,
	},
};

fn invalidsign(
	priv: *privkey,
	sink: io::handle,
	msg: []u8,
	algo: asn1::oid,
	params: sigparams,
) (size | invalid | unsupported | io::error) = "invalid sigfn": invalid;

const invalidprivkey_vtable = privkey_vtable {
	sign = &invalidsign,
};

// Creates an uninitialized private key.
export fn newprivkey() privkey = privkey {
	vt = &invalidprivkey_vtable,
	...
};

export fn privkey_sign(
	p: *privkey,
	dest: io::handle,
	a: asn1::oid,
	msg: []u8,
	params: sigparams = void,
) (size | invalid | unsupported | io::error) = p.vt.sign(p, dest, msg, a, params);
