// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use memio;
use strings;
use encoding::asn1;
use encoding::asn1::stdoid;

fn test_sign(key: str, cert: str, algo: asn1::oid, params: sigparams = void) void = {
	let pk = newprivkey();
	let buf = memio::fixed(strings::toutf8(key));
	privkey_load_pem(&pk, &buf)!;

	let certbuf = memio::fixed(strings::toutf8(cert));
	let certs = parse_pemcerts(&certbuf)!;
	defer certs_free(certs);
	let crt = certs[0];

	cert_checksigfrom(&crt, &crt)!;

	const msg: [_]u8 = [1, 2, 3, 4, 5];
	let sigbuf = memio::dynamic();
	privkey_sign(&pk, &sigbuf, algo, msg, params)!;

	let msgb = memio::fixed(msg);

	cert_checksig(&crt, algo, &msgb, memio::buffer(&sigbuf), params)!;
};
