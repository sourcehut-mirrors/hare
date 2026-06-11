// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

use bytes;
use crypto::random;
use crypto::sha3;
use errors;
use hash;

export type ek768_ikey = struct {
	// ByteDecode₁₂(ek[:384k])
	t: [K]ntt_element,

	// A[i*K+j] = sample_ntt(ρ, j, i)
	a: [K * K]ntt_element,
};

// Public key used to produce ciphertexts to be decapsulated by the
// corresponding [[dk768]].
export type ek768 = struct {
	rho: [32]u8,
	// sample_ntt seed for A

	h: [32]u8,
	// H(ek)

	ik: ek768_ikey,
};

// Parse an encapsulation key from its encoded form.
export fn ek768_decode(key: *ek768, encoded: []u8)
		(void | errors::invalid) = {
	assert(len(encoded) == EK768SZ);

	let h = sha3::sha3_256();
	defer hash::close(&h);
	hash::write(&h, encoded[..]);
	hash::sum(&h, key.h[..]);

	for (let i = 0z; i < len(key.ik.t); i += 1) {
		let start = i * 384;
		poly_byte_decode_ntt(&key.ik.t[i],
			encoded[start..start + 384])?;
	};
	key.rho[..] = encoded[EK768SZ - len(key.rho)..];

	for (let i: u8 = 0; i < K: u8; i += 1) {
		for (let j: u8 = 0; j < K: u8; j += 1) {
			sample_ntt(&key.ik.a[(i: size) * K + (j: size)],
				key.rho[..], j, i);
		};
	};
};

// Return the encapsulation key as serialized bytes.
export fn ek768_encode(key: *ek768, out: []u8) void = {
	assert(len(out) == EK768SZ);

	for (let i = 0z; i < len(key.ik.t); i += 1) {
		let start = i * 384;
		poly_byte_encode_ntt(out[start..start + 384], key.ik.t[i]);
	};
	out[EK768SZ - len(key.rho)..] = key.rho[..];
};

// Generate a shared key and an associated ciphertext from an encapsulation key,
// drawing random bytes from a secure source.
//
// The shared key must be kept secret.
export fn ek768_encap(
	key: *ek768,
	ciphertext: []u8,
	out: []u8,
) void = {
	assert(len(ciphertext) == CT768SZ);
	assert(len(out) == SHAREDKEYSZ);

	// Note that the modulus check (step 2 of the encapsulation key check
	// from FIPS 203, Section 7.2) is performed by [[poly_byte_decode_ntt]]
	// in [[ek768_decode]].

	let m: [32]u8 = @undefined;
	defer bytes::zero(m[..]);

	random::buffer(m[..]);

	ek768_encap_internal(key, ciphertext, out, m[..]);
};

// Derandomized version of [[ek768_encap]].
//
// It implements ML-KEM.Encaps_internal according to FIPS 203, Algorithm 17.
fn ek768_encap_internal(
	key: *ek768,
	ciphertext: []u8,
	shared_key: []u8,
	m: []u8,
) void = {
	assert(len(ciphertext) == CT768SZ);
	assert(len(shared_key) == SHAREDKEYSZ);
	assert(len(m) == 32);

	let g = sha3::sha3_512();
	defer hash::close(&g);
	hash::write(&g, m[..]);
	hash::write(&g, key.h[..]);
	let G: [sha3::SZ512]u8 = @undefined;
	defer bytes::zero(G[..]);
	hash::sum(&g, G[..]);

	shared_key[..] = G[..SHAREDKEYSZ];
	let r = G[SHAREDKEYSZ..];

	ek768_pke_encrypt(&key.ik, ciphertext, m, r);
};

// Encrypt a plaintext message,
//
// It implements K-PKE.Encrypt according to FIPS 203, Algorithm 14, although the
// computation of t and AT is done in [[ek768_decode]].
fn ek768_pke_encrypt(
	ik: *ek768_ikey,
	out: []u8,
	m: []u8,
	rnd: []u8,
) void = {
	assert(len(out) == CT768SZ);
	assert(len(m) == 32);

	let n: u8 = 0;

	let r: [K]ntt_element = @undefined;
	defer zero_ntt_elements(r[..]);

	let e1: [K]ring_element = @undefined;
	defer zero_ring_elements(e1[..]);

	let sampled: ring_element = @undefined;
	defer zero_element(sampled[..]);

	for (let i = 0z; i < K; i += 1) {
		sample_poly_cbd(&sampled, rnd, n);
		ntt(&r[i], sampled);
		n += 1;
	};

	for (let i = 0z; i < K; i += 1) {
		sample_poly_cbd(&e1[i], rnd, n);
		n += 1;
	};

	let e2: ring_element = @undefined;
	defer zero_element(e2[..]);

	sample_poly_cbd(&e2, rnd, n);

	// NTT⁻¹(AT ◦ r) + e1

	let u: [K]ring_element = @undefined;
	defer zero_ring_elements(u[..]);

	let product: ntt_element = @undefined;
	defer zero_element(product[..]);

	let u_hat: ntt_element = @undefined;
	defer zero_element(u_hat[..]);

	let inv: ring_element = @undefined;
	zero_element(inv[..]);

	for (let i = 0z; i < K; i += 1) {
		u_hat = [0...];

		for (let j = 0z; j < K; j += 1) {
			// i and j are inverted since we need AT.
			ntt_mul(&product, ik.a[j*K + i], r[j]);
			poly_add_ntt(&u_hat, u_hat, product);
		};

		inverse_ntt(&inv, u_hat);
		poly_add_ring(&u[i], e1[i], inv);
	};

	let mu: ring_element = @undefined;
	defer zero_element(mu[..]);

	ring_decode_and_decompress_1(&mu, m);

	// t⊺ ◦ r

	let v_ntt: ntt_element = [0...];
	defer zero_element(v_ntt[..]);

	let inv_v: ring_element = @undefined;
	defer zero_element(inv_v[..]);

	let v_e: ring_element = @undefined;
	defer zero_element(v_e[..]);

	let v: ring_element = @undefined;
	defer zero_element(v[..]);

	for (let i = 0z; i < K; i += 1) {
		ntt_mul(&product, ik.t[i], r[i]);
		poly_add_ntt(&v_ntt, v_ntt, product);
	};

	inverse_ntt(&inv_v, v_ntt);
	poly_add_ring(&v_e, inv_v, e2);
	poly_add_ring(&v, v_e, mu);

	for (let i = 0z; i < K; i += 1) {
		let start = i * 320;
		ring_compress_and_encode_10(out[start..start + 320], u[i]);
	};

	ring_compress_and_encode_4(out[K * 320..], v);
};
