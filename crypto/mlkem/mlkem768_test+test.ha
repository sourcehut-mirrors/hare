// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

use bytes;
use crypto::sha3;
use encoding::hex;
use fmt;
use io;
use test;

@test fn cast() void = {
	let seed: [SEEDSZ]u8 = [
		0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
		0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10,
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
		0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20,
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28,
		0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30,
		0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
		0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40,
	];
	let m: [32]u8 = [
		0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
		0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50,
		0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
		0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60,
	];
	const expected_k: [SHAREDKEYSZ]u8 = [
		0x55, 0x01, 0xfc, 0x52, 0x3b, 0x74, 0x5f, 0x41,
		0x76, 0x2a, 0x18, 0x8d, 0xe4, 0x4a, 0x59, 0xb9,
		0x20, 0xf4, 0x30, 0x14, 0x62, 0x04, 0xee, 0x4e,
		0x79, 0x37, 0x32, 0x39, 0x6d, 0xf7, 0xaa, 0x48,
	];

	let dk: dk768 = @undefined;
	dk768_from_seed(&dk, seed[..]);

	let ek: ek768 = @undefined;
	dk768_ek(&dk, &ek);

	let ke: [SHAREDKEYSZ]u8 = @undefined;
	let c: [CT768SZ]u8 = @undefined;

	ek768_encap_internal(&ek, c[..], ke[..], m[..]);
	assert(bytes::equal(ke[..], expected_k[..]));

	let kd: [SHAREDKEYSZ]u8 = @undefined;
	dk768_decap(&dk, c[..], kd[..]);
	assert(bytes::equal(kd[..], expected_k[..]));
};

// Accumulates random vectors and checks the hash of the result.
fn accumulated(n: size, expected: str) void = {
	let s = sha3::shake128(); // PRG for determ seeds, msg, ct;
	defer io::close(&s)!;

	let o = sha3::shake128(); // accum
	defer io::close(&o)!;

	let seed: [SEEDSZ]u8 = [0...];
	let msg: [32]u8 = [0...];
	let ct1: [CT768SZ]u8 = [0...];

	for (let i = 0z; i < n; i += 1) {
		io::read(&s, seed[..])!;
		let dk: dk768 = @undefined;
		dk768_from_seed(&dk, seed[..]);
		let ek: ek768 = @undefined;
		dk768_ek(&dk, &ek);
		let ek_bytes: [EK768SZ]u8 = @undefined;
		ek768_encode(&ek, ek_bytes[..]);
		io::write(&o, ek_bytes[..])!;

		io::read(&s, msg[..])!;
		let K: [SHAREDKEYSZ]u8 = @undefined;
		let ct: [CT768SZ]u8 = @undefined;
		ek768_encap_internal(&ek, ct[..], K[..], msg[..]);
		io::write(&o, ct[..])!;
		io::write(&o, K[..])!;

		let kk: [SHAREDKEYSZ]u8 = @undefined;
		dk768_decap(&dk, ct[..], kk[..]);
		assert(bytes::equal(kk[..], K[..]));

		io::read(&s, ct1[..])!;
		let k1: [SHAREDKEYSZ]u8 = @undefined;
		dk768_decap(&dk, ct1[..], k1[..]);
		io::write(&o, k1[..])!;
	};

	let sum: [32]u8 = [0...];
	io::read(&o, sum[..])!;
	let got = hex::encodestr(sum[..])!;
	defer free(got);
	assert(got == expected);
};

@test fn accumulated_100() void = {
	accumulated(100, "1114b1b6699ed191734fa339376afa7e285c9e6acf6ff0177d346696ce564415");
};

@test fn accumulated_10000() void = {
	test::require("slow");
	accumulated(10000, "8a518cc63da366322a8e7a818c7a0d63483cb3528d34a4cf42f35d5ad73f22fc");
};

@test fn accumulated_1000000() void = {
	test::require("very_slow");
	accumulated(1000000, "424bf8f0e8ae99b78d788a6e2e8e9cdaf9773fc0c08a6f433507cb559edfd0f0");
};

@test fn round_trip() void = {
	let seed: [SEEDSZ]u8 = [
		0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
		0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
		0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
		0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
		0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
		0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
		0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
		0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
	];
	let dk: dk768 = @undefined;
	dk768_from_seed(&dk, seed[..]);
	let ek: ek768 = @undefined;
	dk768_ek(&dk, &ek);
	let ke: [SHAREDKEYSZ]u8 = @undefined;
	let c: [CT768SZ]u8 = @undefined;
	ek768_encap(&ek, c[..], ke[..]);
	let kd: [SHAREDKEYSZ]u8 = @undefined;
	dk768_decap(&dk, c[..], kd[..]);
	assert(bytes::equal(ke[..], kd[..]));

	// ek bytes
	let ek_bytes: [EK768SZ]u8 = @undefined;
	ek768_encode(&ek, ek_bytes[..]);
	let ek1: ek768 = @undefined;
	ek768_decode(&ek1, ek_bytes[..])!;
	let ek1_bytes: [EK768SZ]u8 = @undefined;
	ek768_encode(&ek1, ek1_bytes[..]);
	assert(bytes::equal(ek_bytes[..], ek1_bytes[..]));

	// dk seed
	let dk_seed: [SEEDSZ]u8 = @undefined;
	dk768_seed(&dk, dk_seed[..]);
	let dk1: dk768 = @undefined;
	dk768_from_seed(&dk1, dk_seed[..]);
	let dk1_seed: [SEEDSZ]u8 = @undefined;
	dk768_seed(&dk1, dk1_seed[..]);
	assert(bytes::equal(dk_seed[..], dk1_seed[..]));

	let ke1: [SHAREDKEYSZ]u8 = @undefined;
	let c1: [CT768SZ]u8 = @undefined;
	ek768_encap(&ek1, c1[..], ke1[..]);
	let kd1: [SHAREDKEYSZ]u8 = @undefined;
	dk768_decap(&dk1, c1[..], kd1[..]);
	assert(bytes::equal(ke1[..], kd1[..]));

	// differing fresh key
	let dk2: dk768 = @undefined;
	dk768_gen(&dk2);
	let ek2: ek768 = @undefined;
	dk768_ek(&dk2, &ek2);
	let ek2_bytes: [EK768SZ]u8 = @undefined;
	ek768_encode(&ek2, ek2_bytes[..]);
	assert(!bytes::equal(ek_bytes[..], ek2_bytes[..]));
	let dk2_seed: [SEEDSZ]u8 = @undefined;
	dk768_seed(&dk2, dk2_seed[..]);
	assert(!bytes::equal(dk_seed[..], dk2_seed[..]));

	// encap should be random
	let ke3: [SHAREDKEYSZ]u8 = @undefined;
	let c3: [CT768SZ]u8 = @undefined;
	ek768_encap(&ek, c3[..], ke3[..]);
	assert(!bytes::equal(c[..], c3[..]));
	assert(!bytes::equal(ke[..], ke3[..]));
};
