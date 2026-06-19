// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::random;
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

def MIN_RSASZ = 2048;

fn rsa_validate(d: *asn1::decoder, mem: *memio::stream) (void | _error) = {
	let h = asn1::peek(d)?;
	// len = keysize + DER overhead.
	asn1::skip(d, asn1::utag::BITSTRING, rsa::PUBKEYSZ + 4 * 3)?;
	let keybuf = memio::buffer(mem)[h.data+1..h.end];

	let buf: [rsa::PUBKEYSZ]u8 = [0...];
	rsa_parse_pub(buf, keybuf)?;

	asn1::close_seq(d)?;
};

fn rsa_parse_pub(pubkey: []u8, src: []u8) (void | _error) = {
	let mem = memio::fixed(src);
	let d = asn1::derdecoder(&mem);
	asn1::open_seq(&d)?;

	let p = rsa::pubparams { ... };
	const h = asn1::peek(&d)?;
	p.n = src[h.data..h.end];
	asn1::skip(&d, asn1::utag::INTEGER, asn1::dsz(h))?;
	if (p.n[0] & 0x80 != 0) {
		// must not be negative
		return "invalid RSA key": invalid;
	};

	const h = asn1::peek(&d)?;
	p.e = src[h.data..h.end];
	asn1::skip(&d, asn1::utag::INTEGER, asn1::dsz(h))?;
	if (p.e[0] & 0x80 != 0) {
		// must not be negative
		return "invalid RSA key": invalid;
	};

	if (p.e[len(p.e)-1] & 1 != 1) {
		return "weak public RSA exponent": invalid;
	};

	asn1::close_seq(&d)?;

	if (rsa::pubkey_init(pubkey, p) is rsa::error) {
		return "unable to load RSA key": badformat;
	};

};

fn rsa_init(p: *pubkey, d: *asn1::decoder, mem: *memio::stream) (void | _error) = {
	// len = keysize + DER overhead.
	let h = asn1::peek(d)!;
	asn1::skip(d, asn1::utag::BITSTRING, rsa::PUBKEYSZ + 4 * 3)!;
	let keybuf = memio::buffer(mem)[h.data+1..h.end];

	p.vt = &rsapubkey_vtable;
	rsa_parse_pub(p.rsa, keybuf)?;

	const nbitlen = rsa::pubkey_nbitlen(p.rsa);
	if (nbitlen < MIN_RSASZ || nbitlen & 0x7 != 0) {
		return weakkey;
	};

	asn1::close_seq(d)!;
};

const rsapubkey_vtable = pubkey_vtable {
	verify = &rsa_verify,
};

// Parameters for the RSA PSS signature scheme.
// According to RFC 4055: When signing it is recommended that the parameters
// except for the 'saltsz' remain fixed fol all usages of a given RSA key pair.
export type rsapssparams = struct {
	hashfn: oid,
	maskgenfn: oid,
	maskgenhashfn: oid,
	saltsz: u16,
};

type pssparam = enum u32 {
	HASH = 0,
	MASKGEN = 1,
	SALTSZ = 2,
	TRAILER = 3,
};

fn rsapssparams_equal(a: rsapssparams, b: rsapssparams) bool =
	a.hashfn == b.hashfn && a.maskgenfn == b.maskgenfn
		&& a.maskgenhashfn == b.maskgenhashfn && a.saltsz == b.saltsz;

fn rsa_parse_pssparams(d: *asn1::decoder) (rsapssparams | _error) = {
	let p = rsapssparams {
		hashfn = stdoid::ID_SHA256,
		maskgenfn = stdoid::ID_MGF1,
		maskgenhashfn = stdoid::ID_SHA256,
		saltsz = 20,
	};

	let next = 0u32;

	asn1::open_seq(d)?;

	for (let i = 0z; i < 4; i += 1) {
		const h = match (asn1::trypeek(d)?) {
		case io::EOF =>
			break;
		case let h: asn1::head =>
			yield h;
		};
		if (h.class != asn1::class::CONTEXT || h.tagid < next
				|| h.tagid > pssparam::TRAILER) {
			return "invalid RSA PSS parameter format": badformat;
		};

		next = h.tagid + 1;
		asn1::open_explicit(d, asn1::class::CONTEXT, h.tagid)?;

		switch (h.tagid) {
		case pssparam::HASH =>
			asn1::open_seq(d)?;
			p.hashfn = asn1::read_oid(d, stdoid::db)?;
			asn1::read_null(d)?;
			asn1::close_seq(d)?;
		case pssparam::MASKGEN =>
			asn1::open_seq(d)?;
			p.maskgenfn = asn1::read_oid(d, stdoid::db)?;
			asn1::open_seq(d)?;
			p.maskgenhashfn = asn1::read_oid(d, stdoid::db)?;
			asn1::read_null(d)?;
			asn1::close_seq(d)?;
			asn1::close_seq(d)?;
		case pssparam::SALTSZ =>
			p.saltsz = asn1::read_u16(d)?;
		case pssparam::TRAILER =>
			const t = asn1::read_u8(d)?;
			if (t != 1) {
				return "invalid RSA PSS"
					" parameter format": badformat;
			};
		case =>
			return "invalid RSA PSS parameter format": badformat;
		};
		asn1::close_explicit(d)?;
	};

	asn1::close_seq(d)?;
	return p;
};

fn rsa_verify(
	pub: *pubkey,
	msg: io::handle,
	algo: asn1::oid,
	sig: []u8,
	params: sigparams,
) (size | badsig | io::error) = {
	let (h, hashid): (*hash::hash, rsa::pkcs1_hashalgo) = switch (algo) {
	case stdoid::SHA1_WITH_RSAENCRYPTION =>
		return weaksig;
	case stdoid::SHA256_WITH_RSAENCRYPTION =>
		yield (&sha256::sha256(), rsa::pkcs1_hashalgo::SHA256);
	case stdoid::SHA384_WITH_RSAENCRYPTION =>
		yield (&sha512::sha384(), rsa::pkcs1_hashalgo::SHA384);
	case stdoid::SHA512_WITH_RSAENCRYPTION =>
		yield (&sha512::sha512(), rsa::pkcs1_hashalgo::SHA512);
	case stdoid::RSASSA_PSS =>
		return rsa_verify_pss(pub, msg, algo, sig, params);
	case =>
		return "unsupported signature type": badsig;
	};

	let n = io::copy(h, msg)?;

	let msghash: [sha512::SZ]u8 = [0...];
	assert(hash::sz(h) <= len(msghash));
	hash::sum(h, msghash);
	let msghash = msghash[..hash::sz(h)];

	let buf: [rsa::PKCS1_VERIFYBUFSZ]u8 = [0...];
	match (rsa::pkcs1_verify(pub.rsa, msghash, sig, hashid, buf)) {
	case void => void;
	case rsa::error =>
		return invalidsig;
	};

	return n;
};

fn rsa_verify_pss(
	pub: *pubkey,
	msg: io::handle,
	algo: asn1::oid,
	sig: []u8,
	params: sigparams,
) (size | badsig | io::error) = {
	const params = match (params) {
	case let p: rsapssparams =>
		yield p;
	case =>
		return "missing pss parameters": badsig;
	};

	if (params.maskgenfn != stdoid::ID_MGF1) {
		return "unsupported pss mask function": badsig;
	};

	let h: *hash::hash = switch (params.hashfn) {
	case stdoid::ID_SHA1 =>
		return weaksig;
	case stdoid::ID_SHA256 =>
		yield &sha256::sha256();
	case stdoid::ID_SHA384 =>
		yield &sha512::sha384();
	case stdoid::ID_SHA512 =>
		yield &sha512::sha512();
	case =>
		return unknownhash;
	};

	let n = io::copy(h, msg)?;

	let msghash: [sha512::SZ]u8 = [0...];
	assert(hash::sz(h) <= len(msghash));
	hash::sum(h, msghash);
	let msghash = msghash[..hash::sz(h)];

	let mh: *hash::hash = switch (params.maskgenhashfn) {
	case stdoid::ID_SHA1 =>
		return weaksig;
	case stdoid::ID_SHA256 =>
		yield &sha256::sha256();
	case stdoid::ID_SHA384 =>
		yield &sha512::sha384();
	case stdoid::ID_SHA512 =>
		yield &sha512::sha512();
	case =>
		return unknownhash;
	};

	let buf: [rsa::PSS_VERIFYBUFSZ]u8 = [0...];
	match (rsa::pss_verify(pub.rsa, msghash, sig, mh, buf, params.saltsz)) {
	case void => void;
	case rsa::error =>
		return invalidsig;
	};

	return n;
};

const rsaprivkey_vtable = privkey_vtable {
	sign = &rsa_sign,
	finish = &rsa_finish_privkey,
};

fn rsa_finish_privkey(priv: *privkey) void = bytes::zero(priv.rsa);

fn rsa_sign(
	priv: *privkey,
	dest: io::handle,
	msg: []u8,
	algo: asn1::oid,
	params: sigparams
) (size | invalid | unsupported | io::error) = {
	let (h, hashid): (*hash::hash, rsa::pkcs1_hashalgo) = switch (algo) {
	case stdoid::SHA1_WITH_RSAENCRYPTION =>
		return "weak hash algorithm": unsupported;
	case stdoid::SHA256_WITH_RSAENCRYPTION =>
		yield (&sha256::sha256(), rsa::pkcs1_hashalgo::SHA256);
	case stdoid::SHA384_WITH_RSAENCRYPTION =>
		yield (&sha512::sha384(), rsa::pkcs1_hashalgo::SHA384);
	case stdoid::SHA512_WITH_RSAENCRYPTION =>
		yield (&sha512::sha512(), rsa::pkcs1_hashalgo::SHA512);
	case stdoid::RSASSA_PSS =>
		return rsa_sign_pss(priv, dest, msg, algo, params);
	case =>
		return "unsupported signature algorithm": unsupported;
	};

	io::write(h, msg)!;
	let msghash: [sha512::SZ]u8 = [0...];
	assert(hash::sz(h) <= len(msghash));
	hash::sum(h, msghash);
	let msghash = msghash[..hash::sz(h)];

	let sigbuf: [rsa::BITSZ/8]u8 = [0...];
	let sigbuf = sigbuf[..rsa::privkey_nsize(priv.rsa)];

	let buf: [rsa::PKCS1_SIGNBUFSZ]u8 = [0...];
	if (rsa::pkcs1_sign(priv.rsa, msghash, sigbuf,
			hashid, buf) is rsa::error) {
		return "rsa signature creation failed": invalid;
	};

	return io::writeall(dest, sigbuf)?;
};

fn rsa_sign_pss(
	priv: *privkey,
	dest: io::handle,
	msg: []u8,
	algo: asn1::oid,
	params: sigparams
) (size | invalid | unsupported | io::error) = {
	const params = match (params) {
	case let p: rsapssparams =>
		yield p;
	case =>
		return "invalid signature params": invalid;
	};

	if (params.maskgenfn != stdoid::ID_MGF1) {
		return "unsupported maskgenfn": invalid;
	};

	let h: *hash::hash = switch (params.hashfn) {
	case stdoid::ID_SHA1 =>
		return "weak hash function": unsupported;
	case stdoid::ID_SHA256 =>
		yield &sha256::sha256();
	case stdoid::ID_SHA384 =>
		yield &sha512::sha384();
	case stdoid::ID_SHA512 =>
		yield &sha512::sha512();
	case =>
		return "unsupported hash function": unsupported;
	};

	hash::write(h, msg);
	let msghash: [sha512::SZ]u8 = [0...];
	assert(hash::sz(h) <= len(msghash));
	hash::sum(h, msghash);
	let msghash = msghash[..hash::sz(h)];

	let mh: *hash::hash = switch (params.maskgenhashfn) {
	case stdoid::ID_SHA1 =>
		yield &sha1::sha1();
	case stdoid::ID_SHA256 =>
		yield &sha256::sha256();
	case stdoid::ID_SHA384 =>
		yield &sha512::sha384();
	case stdoid::ID_SHA512 =>
		yield &sha512::sha512();
	case =>
		return "unsupported maskgen hash function": unsupported;
	};
	let sigbuf: [rsa::BITSZ/8]u8 = [0...];
	let sigbuf = sigbuf[..rsa::privkey_nsize(priv.rsa)];

	let buf: [rsa::PSS_SIGNBUFSZ]u8 = [0...];
	match (rsa::pss_sign(priv.rsa, msghash, sigbuf,
		mh, random::stream, buf, params.saltsz)) {
	case void => void;
	case rsa::error =>
		return "rsa signature creation failed": invalid;
	};
	return io::writeall(dest, sigbuf)?;
};
