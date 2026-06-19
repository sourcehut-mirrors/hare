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
use errors;
use hash;
use io;
use log;
use memio;

fn ec_validate(d: *asn1::decoder) (void | _error) = {
	let kid = asn1::read_oid(d, stdoid::db: *asn1::oiddb)?;
	asn1::close_seq(d)?;

	let ecpub: *ecdsa::pubkey = switch (kid) {
	case stdoid::PRIME256V1 =>
		yield &ecdsa::p256pub();
	case stdoid::ANSIX9P384R1 =>
		yield &ecdsa::p384pub();
	case stdoid::ANSIX9P521R1 =>
		yield &ecdsa::p521pub();
	case =>
		return "unsupported ec curve": unsupported;
	};

	let pubkeybuf = ecpub.get_q(ecpub);
	let h = asn1::peek(d)?;
	let k = asn1::read_bitstr(d, pubkeybuf)?;
	if (k.1 != 0) {
		return "bad ec pubkey": badformat;
	};
	if (len(k.0) != len(pubkeybuf)
			|| !(ecdsa::pubkey_validate_format(ecpub) is void)) {
		return "bad ec pubkey": badformat;
	};

	asn1::close_seq(d)?;
};

fn ec_init(p: *pubkey, d: *asn1::decoder, mem: *memio::stream) void = {
	let kid = asn1::read_oid(d, stdoid::db: *asn1::oiddb)!;
	asn1::close_seq(d)!;

	p.vt = &ecpubkey_vtable;
	p.ec.id = kid;

	switch (kid) {
	case stdoid::PRIME256V1 =>
		p.ec.p256 = ecdsa::p256pub();
	case stdoid::ANSIX9P384R1 =>
		p.ec.p384 = ecdsa::p384pub();
	case stdoid::ANSIX9P521R1 =>
		p.ec.p521 = ecdsa::p521pub();
	case =>
		abort();
	};
	let ecpub = ec_get_eckey(p);

	let pubkeybuf = ecpub.get_q(ecpub);
	let k = asn1::read_bitstr(d, pubkeybuf)!;
	if (k.1 != 0) {
		abort();
	};
	asn1::close_seq(d)!;
};

fn ec_get_eckey(p: *pubkey) *ecdsa::pubkey = {
	switch (p.ec.id) {
	case stdoid::PRIME256V1 =>
		return &p.ec.p256;
	case stdoid::ANSIX9P384R1 =>
		return &p.ec.p384;
	case stdoid::ANSIX9P521R1 =>
		return &p.ec.p521;
	case =>
		abort();
	};
};

const ecpubkey_vtable = pubkey_vtable {
	verify = &ec_verify,
};

fn ec_verify(
	pub: *pubkey,
	msg: io::handle,
	algo: asn1::oid,
	sig: []u8,
	params: sigparams,
) (size | badsig | io::error) = {
	if (!(params is void)) {
		return "invalid params": badsig;
	};

	let h: *hash::hash = switch (algo) {
	case stdoid::ECDSA_WITH_SHA1 =>
		return weaksig;
	case stdoid::ECDSA_WITH_SHA256 =>
		yield &sha256::sha256();
	case stdoid::ECDSA_WITH_SHA384 =>
		yield &sha512::sha384();
	case stdoid::ECDSA_WITH_SHA512 =>
		yield &sha512::sha512();
	case =>
		return unknownhash;
	};
	let n = io::copy(h, msg)?;
	let msghash: [sha512::SZ]u8 = [0...];
	let msghash = msghash[..hash::sz(h)];
	hash::sum(h, msghash);

	let pub = ec_get_eckey(pub);

	let sigbuf: [ecdsa::MAX_SIGSZ]u8 = [0...];
	let sig = match (ec_parse_sig(sigbuf, sig)) {
	case let s: []u8 =>
		yield s;
	case badformat =>
		return invalidsig;
	case let e: asn1::error =>
		return invalidsig;
	};

	match (ecdsa::verify(pub, msghash, sig)) {
	case void => void;
	case ecdsa::error =>
		return invalidsig;
	};

	return n;
};

fn ec_parse_sig(dest: []u8, asn1sig: []u8) ([]u8 | asn1::error | badformat) = {
	let r: [ec::MAX_POINTSZ]u8 = [0...];
	let s: [ec::MAX_POINTSZ]u8 = [0...];

	let mem = memio::fixed(asn1sig);
	let d = asn1::derdecoder(&mem);
	asn1::open_seq(&d)?;

	// read r + s. both need to be of same size
	let rsz = asn1::read_int(&d, r)?;
	if (rsz > ec::MAX_POINTSZ) {
		return "invalid ecdsa signature": badformat;
	};
	let start = 0z;
	for (start < len(r); start += 1) {
		if (r[start] != 0) {
			break;
		};
	};
	if (start >= rsz) {
		return "invalid ecdsa signature": badformat;
	};
	let r = r[start..rsz];

	let ssz = asn1::read_int(&d, s)?;
	if (ssz > ec::MAX_POINTSZ) {
		return "invalid ecdsa signature": badformat;
	};
	let start = 0z;
	for (start < len(s); start += 1) {
		if (s[start] != 0) {
			break;
		};
	};
	if (start >= ssz) {
		return "invalid ecdsa signature": badformat;
	};

	asn1::close_seq(&d)?;
	asn1::finish(&d)?;
	let s = s[start..ssz];

	let sz = if (len(r) > len(s)) len(r) else len(s);
	let soff = sz - len(s);
	let roff = sz - len(r);

	let sig = dest[..2 * sz];
	sig[roff..sz] = r[..];
	sig[sz + soff..] = s[..];

	return sig;
};

const ecprivkey_vtable = privkey_vtable {
	sign = &ec_sign,
	finish = &ec_finish_privkey,
};

fn ec_finish_privkey(priv: *privkey) void = {
	let pk: *ecdsa::privkey = switch (priv.t) {
	case keytype::P256 =>
		yield &priv.p256;
	case keytype::P384 =>
		yield &priv.p384;
	case keytype::P521 =>
		yield &priv.p521;
	case =>
		abort();
	};

	ecdsa::privkey_finish(pk);
};

def EC_HASHBUFSZ = sha512::SZ * 2 + sha512::BLOCKSZ;

fn ec_sign(
	priv: *privkey,
	dest: io::handle,
	msg: []u8,
	algo: asn1::oid,
	params: sigparams
) (size | invalid | unsupported | io::error) = {
	assert(params is void);

	let pk: *ecdsa::privkey = switch (priv.t) {
	case keytype::P256 =>
		yield &priv.p256;
	case keytype::P384 =>
		yield &priv.p384;
	case keytype::P521 =>
		yield &priv.p521;
	case =>
		abort();
	};

	let h: *hash::hash = switch (algo) {
	case stdoid::ECDSA_WITH_SHA1 =>
		yield &sha1::sha1();
	case stdoid::ECDSA_WITH_SHA256 =>
		yield &sha256::sha256();
	case stdoid::ECDSA_WITH_SHA384 =>
		yield &sha512::sha384();
	case stdoid::ECDSA_WITH_SHA512 =>
		yield &sha512::sha512();
	case =>
		return "unsupported hash function": unsupported;
	};

	hash::write(h, msg);
	let msghash: [sha512::SZ]u8 = [0...];
	let msghash = msghash[..hash::sz(h)];
	hash::sum(h, msghash);

	let hashbuf: [EC_HASHBUFSZ]u8 = [0...];
	let sigbuf: [ecdsa::MAX_SIGSZ]u8 = [0...];

	let ssz = match (ecdsa::sign(pk, msghash, h, hashbuf, sigbuf)) {
	case let s: u32 =>
		if (s == 0) {
			return "ecdsa siganture creation failed": invalid;
		};
		yield s;
	case ecdsa::invalidkey =>
		return "invalid ecdsa key": invalid;
	};

	match (ec_encode_sig(dest, sigbuf[..ssz])) {
	case let s: size =>
		return s;
	case let e: io::error =>
		return e;
	case let e: asn1::error =>
		// must not happen
		return "asn1 encoding of signature failed": invalid;
	};
};

fn ec_encode_sig(
	dest: io::handle,
	sig: []u8
) (size | io::error | asn1::error) = {
	// Size of the asn1 headers. Three bytes for the sequence. Two bytes
	// for the header of each uint and one byte for uint for the leading
	// zero of the uint.
	def ASN1HEADSZ: size = 3 + (2 * 2) + 2;
	let derbuf: [ecdsa::MAX_SIGSZ + ASN1HEADSZ]u8 = [0...];

	let ssz = len(sig);
	let enc = asn1::derencoder(&memio::fixed(derbuf));
	asn1::create_seq(&enc)?;
	asn1::write_uint(&enc, sig[..ssz/2])?;
	asn1::write_uint(&enc, sig[ssz/2..ssz])?;
	asn1::finish_seq(&enc);
	return asn1::encodeto(&enc, dest)?;
};
