// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use bytes;
use encoding::hex;
use fmt;
use io;
use os;
use memio;
use encoding::pem;
use encoding::asn1::stdoid;
use time::date;

@test fn parse_v1() void = {
	let c = open_cert(memio::fixed(ed25519cert.cert))!;

	assert(c.version == version::V1);
	let sn: [_]u8 = [
		0x72, 0x1f, 0x7b, 0x55, 0x95, 0x61, 0x9a, 0xa2, 0xa2, 0x3d,
		0x62, 0xc6, 0x4c, 0x8f, 0xce, 0xe6, 0x5b, 0xcb, 0x94, 0x7b
	];
	assert(bytes::equal(sn[..], cert_sn(&c)));
	assert(c.sigalgo == stdoid::ED25519);

	let from = date::new(date::UTC, 0, 2022, 12, 7, 16, 31, 5)!;
	assert(date::coincident(&from, &c.validfrom));

	let to = date::new(date::UTC, 0, 2024, 11, 6, 16, 31, 5)!;
	assert(date::coincident(&to, &c.validto));

// TODO check
//	Issuer: C=DE, CN=www.example.com
//      Subject: C=DE, CN=www.example.com
//      Subject Public Key Info:
//          Public Key Algorithm: ED25519
//              ED25519 Public-Key:
//              pub:
//                  72:0d:30:f0:88:d6:38:19:21:b8:c0:bc:a5:36:fa:
//                  d7:4f:06:10:db:c0:10:fb:fa:43:0e:0a:56:eb:5d:
//                  87:80

};

@test fn verify_sig() void = {
	let c = open_cert(memio::fixed(ed25519cert.cert))!;
	cert_checksigfrom(&c, &c)!;

	let c = open_cert(memio::fixed(rsapkcs1v3cert.cert))!;
	cert_checksigfrom(&c, &c)!;
};
