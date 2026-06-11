// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

use bytes;
use crypto::math;
use crypto::random;
use crypto::sha3;
use hash;
use io;

export type dk768_ikey = struct {
	// ByteDecode₁₂(dk[:decryptionKeySize])
	s: [K]ntt_element,
};

// Secret key used to decapsulate a shared key from a ciphertext.
export type dk768 = struct {
	d: [32]u8,
	// Decapsulation key seed

	z: [32]u8,
	// Implicit rejection sampling seed

	rho: [32]u8,
	// sample_ntt seed for A, stored for the encapsulation key

	h: [32]u8,
	// H(ek), stored for ML-KEM.Decaps_internal

	ek: ek768_ikey,
	dk: dk768_ikey,
};

// Generate a new decapsulation key, drawing random bytes from a secure source.
//
// The decapsulation key must be kept secret.
export fn dk768_gen(out: *dk768) void = {
	let seed: [SEEDSZ]u8 = @undefined;
	defer bytes::zero(seed[..]);
	random::buffer(seed[..]);
	return dk768_from_seed(out, seed[..]);
};

// Initializes a decapsulation key from a 64-byte seed. The seed must be
// uniformly random.
export fn dk768_from_seed(out: *dk768, seed: []u8) void = {
	assert(len(seed) == SEEDSZ);

	out.d[..] = seed[..len(out.d)];
	out.z[..] = seed[len(out.d)..];

	let g = sha3::sha3_512();
	defer hash::close(&g);
	hash::write(&g, out.d[..]);
	let kk: [1]u8 = [K: u8];
	hash::write(&g, kk[..]);
	let G: [sha3::SZ512]u8 = @undefined;
	defer bytes::zero(G[..]);
	hash::sum(&g, G[..]);
	out.rho[..] = G[..len(out.rho)];
	let sigma = G[len(out.rho)..];

	for (let i: u8 = 0; i < K: u8; i += 1) {
		for (let j: u8 = 0; j < K: u8; j += 1) {
			sample_ntt(&out.ek.a[(i: size) * K + (j: size)],
				out.rho[..], j, i);
		};
	};

	let e: [K]ntt_element = @undefined;
	defer zero_ntt_elements(e[..]);

	let N: u8 = 0;

	let sampled: ring_element = @undefined;
	defer zero_element(sampled[..]);

	for (let i = 0z; i < len(out.dk.s); i += 1) {
		sample_poly_cbd(&sampled, sigma, N);
		ntt(&out.dk.s[i], sampled);
		N += 1;
	};
	for (let i = 0z; i < len(e); i += 1) {
		sample_poly_cbd(&sampled, sigma, N);
		ntt(&e[i], sampled);
		N += 1;
	};

	let product: ntt_element = @undefined;
	defer zero_element(product[..]);

	for (let i = 0z; i < len(out.ek.t); i += 1) {
		out.ek.t[i] = e[i];
		for (let j = 0z; j < len(out.dk.s); j += 1) {
			ntt_mul(&product, out.ek.a[i * K + j], out.dk.s[j]);
			poly_add_ntt(&out.ek.t[i], out.ek.t[i], product);
		};
	};

	let ek: [EK768SZ]u8 = @undefined;
	let encapsulation_key: ek768 = @undefined;
	dk768_ek(out, &encapsulation_key);
	ek768_encode(&encapsulation_key, ek[..]);
	let h = sha3::sha3_256();
	defer hash::close(&h);
	hash::write(&h, ek[..]);
	hash::sum(&h, out.h[..]);
};

// Return the decapsulation key as a 64-byte seed in the "d || z" form.
//
// The decapsulation key must be kept secret.
export fn dk768_seed(key: *dk768, out: []u8) void = {
	assert(len(out) == SEEDSZ);

	out[..len(key.d)] = key.d[..];
	out[len(key.d)..] = key.z[..];
};

// Generates a secret key from a ciphertext and decapsulation key.
export fn dk768_decap(
	key: *dk768,
	ciphertext: []u8,
	out: []u8,
) void = {
	assert(len(ciphertext) == CT768SZ);
	assert(len(out) == SHAREDKEYSZ);

	// See ML-KEM.Decaps_internal (Algorithm 18).
	let m: [32]u8 = @undefined;
	defer bytes::zero(m[..]);
	pke_decrypt(&key.dk, m[..], ciphertext);
	let g = sha3::sha3_512();
	defer hash::close(&g);
	hash::write(&g, m[..]);
	hash::write(&g, key.h[..]);
	let G: [sha3::SZ512]u8 = @undefined;
	defer bytes::zero(G[..]);
	hash::sum(&g, G[..]);
	let Kprime = G[..SHAREDKEYSZ];
	let r = G[SHAREDKEYSZ..];

	let j = sha3::shake256();
	defer io::close(&j)!;
	io::write(&j, key.z[..])!;
	io::write(&j, ciphertext[..])!;
	io::read(&j, out[..])!; // implicit rejection.

	let c1: [CT768SZ]u8 = @undefined;
	ek768_pke_encrypt(&key.ek, c1[..], m[..], r);
	let eq = math::eqslice(ciphertext, c1[..]);
	crypto::math::ccopyu8((eq: u32), out[..], Kprime);
};

// Decrypt a ciphertext.
//
// It implements K-PKE.Decrypt according to FIPS 203, Algorithm 15, although s
// is retained from [[dk768_from_seed]].
fn pke_decrypt(dk: *dk768_ikey, out: []u8, c: []u8) void = {
	assert(len(out) == 32);
	assert(len(c) == CT768SZ);

	let u: [K]ring_element = @undefined;
	defer zero_ring_elements(u[..]);
	for (let i = 0z; i < K; i += 1) {
		let start = 320 * i;
		ring_decode_and_decompress_10(&u[i], c[start..start + 320]);
	};

	let v: ring_element = @undefined;
	defer zero_element(v[..]);

	ring_decode_and_decompress_4(&v, c[320 * K..]);

	// s⊺ ◦ NTT(u)
	let mask: ntt_element = [0...];
	defer zero_element(mask[..]);

	let product: ntt_element = @undefined;
	defer zero_element(product[..]);

	for (let i = 0z; i < len(dk.s); i += 1) {
		let u_ntt: ntt_element = @undefined;
		ntt(&u_ntt, u[i]);

		ntt_mul(&product, dk.s[i], u_ntt);
		poly_add_ntt(&mask, mask, product);

		zero_element(u_ntt[..]);
	};

	let inv_mask: ring_element = @undefined;
	defer zero_element(inv_mask[..]);

	inverse_ntt(&inv_mask, mask);

	let w: ring_element = @undefined;
	defer zero_element(w[..]);

	poly_sub_ring(&w, v, inv_mask);

	ring_compress_and_encode_1(out, w);
};

// Return the public encapsulation key necessary to produce ciphertexts.
export fn dk768_ek(key: *dk768, out: *ek768) void = {
	out.rho = key.rho;
	out.h = key.h;
	out.ik = key.ek;
};
