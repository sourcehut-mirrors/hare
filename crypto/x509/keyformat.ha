// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::rsa;
use crypto::ec;
use crypto::ecdsa;
use crypto::ed25519;
use encoding::asn1;
use encoding::asn1::stdoid;
use encoding::pem;
use io;

// Loads a PEM encoded private key from 'src' into 'priv'.
export fn privkey_load_pem(
	priv: *privkey,
	src: io::handle,
) (void | io::error | invalid | unsupported) = {
	match (_privkey_load_pem(priv, src)) {
	case void => void;
	case let e: (io::error | invalid | unsupported) =>
		return e;
	case let e: asn1::error =>
		return "invalid key format": invalid;
	};
};

export fn _privkey_load_pem(
	priv: *privkey,
	src: io::handle,
) (void | io::error | asn1::error | invalid | unsupported) = {
	let keybuf: [4096]u8 = [0...];
	defer bytes::zero(keybuf);

	let dec = pem::newdecoder(src);
	defer pem::finish(&dec);

	let p = match (pem::next(&dec)?) {
	case let p: (str, pem::pemdecoder) =>
		yield p;
	case io::EOF =>
		return "empty pem file": invalid;
	};

	switch (p.0) {
	case "EC PRIVATE KEY" =>
		ec_decode_priv(priv, &p.1, keybuf)?;
	case "RSA PRIVATE KEY" =>
		rsa_parse_pkcs1priv(priv, &p.1, keybuf, stdoid::RSA_ENCRYPTION)?;
	case "PRIVATE KEY" =>
		priv_parse_pkcs8(priv, &p.1, keybuf)?;
	case =>
		return "unsupported key": invalid;
	};
};

fn rsa_parse_pkcs1priv(
	priv: *privkey,
	src: io::handle,
	buf: []u8,
	oid: asn1::oid,
) (void | io::error | asn1::error | invalid | unsupported) = {
	let dec = asn1::derdecoder(src);

	asn1::open_seq(&dec)?;
	const version = asn1::read_u8(&dec)?;
	if (version != 0) {
		return "invalid key format": invalid;
	};

	let (n, buf) = read_uint(&dec, buf)?;
	let (e, buf) = read_uint(&dec, buf)?;
	let (d, buf) = read_uint(&dec, buf)?;
	let (p, buf) = read_uint(&dec, buf)?;
	let (q, buf) = read_uint(&dec, buf)?;
	let (dp, buf) = read_uint(&dec, buf)?;
	let (dq, buf) = read_uint(&dec, buf)?;
	let (qinvp, buf) = read_uint(&dec, buf)?;

	let params = rsa::privparams {
		p = p,
		q = q,
		dp = dp,
		dq = dq,
		iq = qinvp,
		...
	};

	priv.vt = &rsaprivkey_vtable;
	match (rsa::privkey_init(priv.rsa, params, n)) {
	case size => void;
	case let e: rsa::error =>
		return "invalid rsa key params": invalid;
	};
};

fn read_uint(d: *asn1::decoder, buf: []u8) (([]u8, []u8) | asn1::error) = {
	const n = asn1::read_uint(d, buf)?;
	return (buf[..n], buf[n..]);
};

fn priv_parse_pkcs8(
	priv: *privkey,
	src: io::handle,
	buf: []u8
) (void | io::error | asn1::error | invalid | unsupported) = {
	let dec = asn1::derdecoder(src);

	asn1::open_seq(&dec)?;
	const version = asn1::read_u8(&dec)?;
	if (version != 0) {
		return "unsupported key format version": unsupported;
	};
	asn1::open_seq(&dec)?;

	let keyoid = asn1::read_oid(&dec, stdoid::db)?;
	switch (keyoid) {
	case stdoid::RSA_ENCRYPTION =>
		asn1::read_null(&dec)?;
		asn1::close_seq(&dec)?;
		let keystream = asn1::octetstrreader(&dec)?;
		rsa_parse_pkcs1priv(priv, &keystream, buf, stdoid::RSA_ENCRYPTION)?;
		priv.t = keytype::RSA;
	case stdoid::RSASSA_PSS =>
		asn1::close_seq(&dec)?;
		let keystream = asn1::octetstrreader(&dec)?;
		rsa_parse_pkcs1priv(priv, &keystream, buf, stdoid::RSASSA_PSS)?;
		priv.t = keytype::RSAPSS;
	case stdoid::ED25519 =>
		asn1::close_seq(&dec)?;
		let keystream = asn1::octetstrreader(&dec)?;
		ed25519_parse_priv(priv, &keystream)?;
	case stdoid::ID_EC_PUBLIC_KEY =>
		const curveid = asn1::read_oid(&dec, stdoid::db)?;
		asn1::close_seq(&dec)?;
		let keystream = asn1::octetstrreader(&dec)?;
		ec_decode_priv(priv, &keystream, buf, curveid)?;
	case =>
		return "unsupported key type": unsupported;
	};

	asn1::close_seq(&dec)?;
	asn1::finish(&dec)?;
};

fn ed25519_parse_priv(priv: *privkey, src: io::handle) (void | io::error | asn1::error | invalid) = {
	let dec = asn1::derdecoder(src);

	let seed: ed25519::seed = [0...];
	defer bytes::zero(seed);

	let r = asn1::octetstrreader(&dec)?;
	match (io::readall(&r, seed)) {
	case size => void;
	case io::EOF =>
		return "invalid key format": invalid;
	case let e: io::error =>
		return e;
	};

	priv.t = keytype::ED25519;
	priv.vt = &ed25519privkey_vtable;
	ed25519::privkey_init(priv.ed25519, &seed);
};

fn ec_decode_priv(
	priv: *privkey,
	h: io::handle,
	keybuf: []u8,
	curveid: (void | asn1::oid) = void,
) (void | asn1::error | invalid) = {
	let d = asn1::derdecoder(h);
	asn1::open_seq(&d)?;
	const v = asn1::read_u8(&d)?;

	switch (v) {
	case 0 =>
		return ec_decode_priv0(priv, &d, keybuf);
	case 1 =>
		return ec_decode_priv1(priv, &d, keybuf, curveid);
	case =>
		return "unsupported ec key format version ": invalid;
	};
};

// decodes an EC key according to rfc5208
fn ec_decode_priv0(
	priv: *privkey,
	d: *asn1::decoder,
	keybuf: []u8,
) (void | asn1::error | invalid) = {

	asn1::open_seq(d)?;
	const ecid = asn1::read_oid(d, stdoid::db)?;
	if (ecid != stdoid::ID_EC_PUBLIC_KEY) {
		return "invalid key format": invalid;
	};

	const curveid = asn1::read_oid(d, stdoid::db)?;
	asn1::close_seq(d)?;

	// private key
	let or = asn1::octetstrreader(d)?;
	let kd = &asn1::derdecoder(&or);

	asn1::open_seq(kd)?;
	const v = asn1::read_u8(kd)?;

	if (v != 1) {
		return "unsupported key format": unsupported;
	};

	return ec_decode_priv1(priv, kd, keybuf, curveid);
};

// parses an EC private key according to rfc5915.
fn ec_decode_priv1(
	priv: *privkey,
	d: *asn1::decoder,
	keybuf: []u8,
	curveid: (void | asn1::oid) = void,
) (void | asn1::error | invalid) = {
	const n = asn1::read_octetstr(d, keybuf)?;
	let keybuf = keybuf[..n];
	let h = asn1::peek(d)?;

	if (h.class == asn1::class::CONTEXT && h.tagid == 0) {
		// EC PARAMETERS
		asn1::open_explicit(d, asn1::class::CONTEXT, 0)?;
		const actualcurveid = asn1::read_oid(d, stdoid::db)?;

		match (curveid) {
		case void =>
			curveid = actualcurveid;
		case let k: asn1::oid =>
			if (k != actualcurveid) {
				return "unexpected key oid": invalid;
			};
		};
	};

	if (curveid is void) {
		return "invalid key format": invalid;
	};

	ec_initby_oid(priv, curveid as asn1::oid, keybuf)?;

	let h = asn1::trypeek(d)?;
	match (h) {
	case io::EOF => void;
	case let h: asn1::head =>
		if (h.class != asn1::class::CONTEXT || h.tagid != 1) {
			return "invalid key format": invalid;
		};

		// skip the public key
		asn1::open_explicit(d, asn1::class::CONTEXT, 1)?;
		asn1::skip(d, asn1::utag::BITSTRING, ec::MAX_POINTSZ + 2)?;
	};

	asn1::close_seq(d)?;
};

fn ec_initby_oid(
	priv: *privkey,
	curveid: asn1::oid,
	keybuf: []u8
) (void | unsupported) = {
	let pk: *ecdsa::privkey = switch (curveid) {
	case stdoid::PRIME256V1, stdoid::ANSIX9P256R1 =>
		priv.t = keytype::P256;
		priv.p256 = ecdsa::p256priv();
		yield &priv.p256;
	case stdoid::ANSIX9P384R1 =>
		priv.t = keytype::P384;
		priv.p384 = ecdsa::p384priv();
		yield &priv.p384;
	case stdoid::ANSIX9P521R1 =>
		priv.t = keytype::P521;
		priv.p521 = ecdsa::p521priv();
		yield &priv.p521;
	case =>
		return "unsupported key": unsupported;
	};
	priv.vt = &ecprivkey_vtable;

	let destbuf = ecdsa::privkey_buf(pk);

	if (len(keybuf) > len(destbuf)) {
		return "invalid ec key": invalid;
	};

	let off = len(destbuf) - len(keybuf);
	destbuf[..] = [0...];
	destbuf[off..] = keybuf[..];

	match (ecdsa::privkey_validate(pk)) {
	case void => void;
	case ecdsa::invalidkey =>
		return "invalid ec key": invalid;
	};
};
