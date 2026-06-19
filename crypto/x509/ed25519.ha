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
use encoding::asn1::stdoid;
use errors;
use hash;
use io;
use log;
use memio;

fn ed25519_parse(d: *asn1::decoder, mem: *memio::stream) ([]u8 | _error) = {
	let buf: [ed25519::PUBKEYSZ]u8 = [0...];
	asn1::close_seq(d)?;

	let h = asn1::peek(d)?;
	let k = asn1::read_bitstr(d, buf)?;
	if (k.1 != 0 || len(k.0) != ed25519::PUBKEYSZ) {
		return errors::invalid;
	};

	asn1::close_seq(d)?;

	return memio::buffer(mem)[h.data+1..h.end];
};

fn ed25519_init(p: *pubkey, d: *asn1::decoder, mem: *memio::stream) void = {
	let keybuf = ed25519_parse(d, mem)!;
	p.ed25519[..] = keybuf[..];
	p.vt = &ed25519pubkey_vtable;
};

const ed25519pubkey_vtable = pubkey_vtable {
	verify = &ed25519_verify,
};

fn ed25519_verify(
	pub: *pubkey,
	msg: io::handle,
	algo: asn1::oid,
	sig: []u8,
	params: sigparams,
) (size | badsig | io::error) = {
	if (algo != stdoid::ED25519 || !(params is void)
			|| len(sig) != ed25519::SIGNATURESZ) {
		return "invalid signature configuration": badsig;
	};


	let h = match (ed25519::verifier(pub.ed25519, sig[..ed25519::SIGNATURESZ])) {
	case let h: ed25519::hash =>
		yield h;
	case ed25519::error =>
		return "invalid siganture": badsig;
	};

	let n = io::copy(&h, msg)?;

	if (!(ed25519::verify(&h) is void)) {
		return "invalid siganture": badsig;
	};

	return n;
};

const ed25519privkey_vtable = privkey_vtable {
	sign = &ed25519_sign,
	finish = &ed25519_finish_privkey,
};

fn ed25519_sign(
	priv: *privkey,
	dest: io::handle,
	msg: []u8,
	algo: asn1::oid,
	params: sigparams,
) (size | invalid | unsupported | io::error) = {
	if (algo != stdoid::ED25519 || !(params is void)) {
		return "invalid signature params": invalid;
	};

	let rsig = ed25519::sign(priv.ed25519, msg);
	return io::writeall(dest, rsig)?;
};

fn ed25519_finish_privkey(priv: *privkey) void = bytes::zero(priv.ed25519);
