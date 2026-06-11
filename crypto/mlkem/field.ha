// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

use bytes;
use crypto::math;
use crypto::sha3;
use endian;
use errors;
use io;

export type field_element = u16;
// An integer modulo Q, an element of ℤ_q. It is always reduced.

// Check that a value a is < Q.
//
// Only for public values as the comparison is non-constant-time and the caller
// necessarily branches.
fn field_check_reduced(a: u16) (field_element | errors::invalid) = {
	if (a >= Q) {
		return errors::invalid;
	};
	return a: field_element;
};

// Reduce a value a < 2q.
fn field_reduce_once(a: u16) field_element = {
	let x: u16 = a - Q;
	x += math::mulu16(x >> 15, Q): u16;
	return x: field_element;
};

fn field_add(a: field_element, b: field_element) field_element = {
	return field_reduce_once((a + b): u16);
};

fn field_sub(a: field_element, b: field_element) field_element = {
	return field_reduce_once((a - b + Q): u16);
};

// Reduce a value a < 2q² using Barrett reduction, to avoid potentially
// variable-time division.
fn field_reduce(a: u32) field_element = {
	assert(a < 2u32 * (Q: u32) * (Q: u32));

	const quotient: u32 =
		(math::mulu32(a, BARRETT_MULTIPLIER: u32)
			>> BARRETT_SHIFT): u32;
	return field_reduce_once(
		(a - math::mulu32(Q: u32, quotient): u32): u16,
	);
};

fn field_mul(a: field_element, b: field_element) field_element = {
	return field_reduce(math::mulu16(a: u16, b: u16));
};

// Return a * (b - c). This operation is fused to save a field_reduce_once after
// the subtraction.
fn field_mul_sub(a: field_element, b: field_element, c: field_element)
		field_element = {
	return field_reduce(math::mulu16(a: u16, (b - c + Q): u16));
};

// Return a * b + c * d. This operation is fused to save a field_reduce_once and
// a field_reduce.
fn field_add_mul(a: field_element, b: field_element,
		c: field_element, d: field_element) field_element = {
	return field_reduce(
		math::mulu16(a: u16, b: u16) + math::mulu16(c: u16, d: u16)
	);
};

// Map a field element uniformly to the range 0 to 2ᵈ-1, according to FIPS 203,
// Definition 4.7.
fn compress(x: field_element, d: u8) u16 = {
	// We want to compute (x * 2ᵈ) / Q, rounded to nearest integer, with 1/2
	// rounding up (see FIPS 203, Section 2.3).

	// Barrett reduction produces a quotient and a remainder in the range
	// [0, 2q), such that dividend = quotient * Q + remainder.
	let dividend: u32 = (x: u32) << d; // x * 2ᵈ
	let quotient: u32 =
		(math::mulu32(dividend, BARRETT_MULTIPLIER: u32)
			>> BARRETT_SHIFT): u32;
	let remainder: u32 = dividend - math::mulu32(quotient, Q: u32): u32;

	// Since the remainder is in the range [0, 2q), not [0, Q), we need to
	// portion it into three spans for rounding.
	//
	//     [ 0,       Q/2     ) -> round to 0
	//     [ Q/2,     Q + Q/2 ) -> round to 1
	//     [ Q + Q/2, 2q      ) -> round to 2
	//
	// We can convert that to the following logic: add 1 if remainder > Q/2,
	// then add 1 again if remainder > Q + Q/2.
	//
	// Note that if remainder > x, then ⌊x⌋ - remainder underflows, and the
	// top bit of the difference will be set.
	quotient += ((Q >> 1) - remainder) >> 31 & 1;
	quotient += (Q + (Q >> 1) - remainder) >> 31 & 1;

	// quotient might have overflowed at this point, so reduce it by
	// masking.
	let mask: u32 = (1u32 << d) - 1;
	return (quotient & mask): u16;
};

// Map a number x between 0 and 2ᵈ-1 uniformly to the full range of field
// elements, according to FIPS 203, Definition 4.8.
fn decompress(y: u16, d: u8) field_element = {
	// We want to compute (y * Q) / 2ᵈ, rounded to nearest integer, with 1/2
	// rounding up (see FIPS 203, Section 2.3).

	let dividend: u32 = math::mulu16(y, Q);
	let quotient: u32 = dividend >> d; // (y * Q) / 2ᵈ

	// The d'th least-significant bit of the dividend (the most significant
	// bit of the remainder) is 1 for the top half of the values that divide
	// to the same quotient, which are the ones that round up.
	quotient += dividend >> (d - 1) & 1;

	// quotient is at most (2¹¹-1) * Q / 2¹¹ + 1 = 3328, so it didn't
	// overflow.
	return quotient: field_element;
};

export type ring_element = [N]field_element;
// A polynomial, an element of R_q, represented as an array according to FIPS
// 203, Section 2.4.4.

export type ntt_element = [N]field_element;
// An NTT representation, an element of T_q, represented as an array according
// to FIPS 203, Section 2.4.4.

fn zero_element(e: []field_element) void =
	bytes::zero((e: *[*]u8)[..len(e) * size(field_element)]);

fn zero_ring_elements(e: []ring_element) void =
	bytes::zero((e: *[*]u8)[..len(e) * size(ring_element)]);

fn zero_ntt_elements(e: []ntt_element) void =
	bytes::zero((e: *[*]u8)[..len(e) * size(ntt_element)]);

// Add two [[ring_element]]s.
fn poly_add_ring(out: *ring_element, a: ring_element, b: ring_element) void = {
	for (let i = 0z; i < len(out); i += 1) {
		out[i] = field_add(a[i], b[i]);
	};
};

// Add two [[ntt_element]]s.
fn poly_add_ntt(out: *ntt_element, a: ntt_element, b: ntt_element) void = {
	for (let i = 0z; i < len(out); i += 1) {
		out[i] = field_add(a[i], b[i]);
	};
};


// Subtract two [[ring_element]]s.
fn poly_sub_ring(out: *ring_element, a: ring_element, b: ring_element) void = {
	for (let i = 0z; i < len(out); i += 1) {
		out[i] = field_sub(a[i], b[i]);
	};
};

// Subtract two [[ntt_element]]s.
fn poly_sub_ntt(out: *ntt_element, a: ntt_element, b: ntt_element) void = {
	for (let i = 0z; i < len(out); i += 1) {
		out[i] = field_sub(a[i], b[i]);
	};
};

// Compute the 384-byte encoding of f, for NTT elements.
//
// It implements ByteEncode₁₂, according to FIPS 203, Algorithm 5.
fn poly_byte_encode_ntt(out: []u8, f: ntt_element) void = {
	assert(len(out) == 384);

	for (let i = 0z; i < (N>>1); i += 1) {
		let x = (f[i*2]: u32) | (((f[i*2+1]): u32) << 12);
		out[3*i + 0] = x: u8;
		out[3*i + 1] = (x >> 8): u8;
		out[3*i + 2] = (x >> 16): u8;
	};
};

// Decode the 384-byte encoding of a NTT polynomial, checking that all the
// coefficients are properly reduced. This fulfills the "Modulus check" step of
// ML-KEM Encapsulation.
//
// It implements ByteDecode₁₂, according to FIPS 203, Algorithm 6.
fn poly_byte_decode_ntt(out: *ntt_element, b: []u8)
		(void | errors::invalid) = {
	assert(len(b) == 384);

	for (let i = 0z; i < (N >> 1); i += 1) {
		let d: u32 = (b[3*i + 0]: u32)
			| (b[3*i + 1]: u32) << 8
			| (b[3*i + 2]: u32) << 16;
		const mask12: u32 = 0b1111_1111_1111;
		out[2*i + 0] = field_check_reduced((d & mask12): u16)?;
		out[2*i + 1] = field_check_reduced((d >> 12): u16)?;
	};
};

// Compute a 32-byte encoding of a ring element, compressing one coefficients
// per bit.
//
// It implements Compress₁, according to FIPS 203, Definition 4.7, followed by
// ByteEncode₁, according to FIPS 203, Algorithm 5.
fn ring_compress_and_encode_1(out: []u8, f: ring_element) void = {
	assert(len(out) == 32);

	out[..] = [0...];
	for (let i = 0z; i < len(f); i += 1) {
		out[i >> 3] |= (compress(f[i], 1) << (i & 7)): u8;
	};
};

// Decode a 32-byte slice to a ring element where each bit is mapped to 0 or
// ⌈Q/2⌋.
//
// It implements ByteDecode₁, according to FIPS 203, Algorithm 6, followed by
// Decompress₁, according to FIPS 203, Definition 4.8.
fn ring_decode_and_decompress_1(out: *ring_element, b: []u8) void = {
	assert(len(b) == 32);

	for (let i = 0z; i < len(out); i += 1) {
		let b_i = b[i >> 3] >> (i & 7) & 1;

		// ⌈Q/2⌋, rounded up per FIPS 203, Section 2.3
		const half_q: field_element = ((Q + 1) >> 1): field_element;

		// 0 decompresses to 0, and 1 to ⌈Q/2⌋
		out[i] = math::mulu16(b_i: u16, half_q: u16): field_element;
	};
};

// Compute a 128-byte encoding of a ring element, compressing two coefficients
// per byte.
//
// It implements Compress₄, according to FIPS 203, Definition 4.7, followed by
// ByteEncode₄, according to FIPS 203, Algorithm 5.
fn ring_compress_and_encode_4(out: []u8, f: ring_element) void = {
	assert(len(out) == 128);

	for (let i = 0z; i < N; i += 2) {
		out[i >> 1] =
			(compress(f[i], 4) | compress(f[i+1], 4) << 4): u8;
	};
};

// Decode a 128-byte encoding of a ring element where each four bits are mapped
// to an equidistant distribution.
//
// It implements ByteDecode₄, according to FIPS 203, Algorithm 6, followed by
// Decompress₄, according to FIPS 203, Definition 4.8.
fn ring_decode_and_decompress_4(out: *ring_element, b: []u8) void = {
	assert(len(b) == 128);

	for (let i = 0z; i < N; i += 2) {
		out[i] = decompress((b[i >> 1] & 0b1111): u16, 4):
			field_element;
		out[i+1] = decompress((b[i >> 1] >> 4): u16, 4): field_element;
	};
};

// Compute a 320-byte encoding of a ring element, compressing four coefficients
// per five bytes.
//
// It implements Compress₁₀, according to FIPS 203, Definition 4.7, followed by
// ByteEncode₁₀, according to FIPS 203, Algorithm 5.
fn ring_compress_and_encode_10(out: []u8, f: ring_element) void = {
	assert(len(out) == 320);

	for (let i = 0z; i < (N >> 2); i += 1) {
		let x: u64 = 0;
		x |= compress(f[4*i + 0], 10): u64;
		x |= (compress(f[4*i + 1], 10): u64) << 10;
		x |= (compress(f[4*i + 2], 10): u64) << 20;
		x |= (compress(f[4*i + 3], 10): u64) << 30;
		out[5*i + 0] = x: u8;
		out[5*i + 1] = (x >> 8): u8;
		out[5*i + 2] = (x >> 16): u8;
		out[5*i + 3] = (x >> 24): u8;
		out[5*i + 4] = (x >> 32): u8;
	};
};

// Decode a 320-byte encoding of a ring element where each ten bits are mapped
// to an equidistant distribution.
//
// It implements ByteDecode₁₀, according to FIPS 203, Algorithm 6, followed by
// Decompress₁₀, according to FIPS 203, Definition 4.8.
fn ring_decode_and_decompress_10(out: *ring_element, bb: []u8) void = {
	assert(len(bb) == 320);

	for (let i = 0z; i < (N >> 2); i += 1) {
		let x: u64 = (bb[5*i + 0]: u64)
			| (bb[5*i + 1]: u64) << 8
			| (bb[5*i + 2]: u64) << 16
			| (bb[5*i + 3]: u64) << 24
			| (bb[5*i + 4]: u64) << 32;

		out[4*i + 0] = decompress((x >> 0  & 0b11_1111_1111): u16, 10):
			field_element;
		out[4*i + 1] = decompress((x >> 10 & 0b11_1111_1111): u16, 10):
			field_element;
		out[4*i + 2] = decompress((x >> 20 & 0b11_1111_1111): u16, 10):
			field_element;
		out[4*i + 3] = decompress((x >> 30 & 0b11_1111_1111): u16, 10):
			field_element;
	};
};

// Draw a ring_element from the special Dη distribution given a stream of random
// bytes generated by the PRF function, according to FIPS 203, Algorithm 8 and
// Definition 4.3.
//
// Only ML-KEM 512 needs η = 3, and we aren't implementing that. 768 and 1024
// both use η = 2.
fn sample_poly_cbd(out: *ring_element, s: []u8, b: u8) void = {
	let prf = sha3::shake256();
	defer io::close(&prf)!;
	io::write(&prf, s)!;
	let bb: [1]u8 = [b];
	io::write(&prf, bb[..])!;

	let buf: [64 * 2]u8 = @undefined; // η = 2
	defer bytes::zero(buf[..]);
	io::read(&prf, buf[..])!;

	// Simply draw four (2η) bits for each coefficient, and adds the first
	// two and subtracts the last two.

	for (let i = 0z; i < (N >> 1); i += 1) {
		let x = buf[i];
		let b_7 =  x >> 7;
		let b_6 = (x >> 6) & 1;
		let b_5 = (x >> 5) & 1;
		let b_4 = (x >> 4) & 1;
		let b_3 = (x >> 3) & 1;
		let b_2 = (x >> 2) & 1;
		let b_1 = (x >> 1) & 1;
		let b_0 =  x & 1;
		out[2*i + 0] = field_sub(
			(b_0 + b_1): field_element,
			(b_2 + b_3): field_element,
		);
		out[2*i + 1] = field_sub(
			(b_4 + b_5): field_element,
			(b_6 + b_7): field_element,
		);
	};
};


// Multiply two [[ntt_element]]s.
//
// It implements MultiplyNTTs, according to FIPS 203, Algorithm 11.
fn ntt_mul(out: *ntt_element, f: ntt_element, g: ntt_element) void = {
	for (let i = 0z; i < 128; i += 1) {
		let a0 = f[2*i + 0], a1 = f[2*i + 1];
		let b0 = g[2*i + 0], b1 = g[2*i + 1];
		out[2*i + 0] = field_add_mul(a0, b0, field_mul(a1, b1),
			GAMMAS[i]);
		out[2*i + 1] = field_add_mul(a0, b1, a1, b0);
	};
};


// Map a [[ring_element]] to its [[ntt_element]] representation.
//
// It implements NTT, according to FIPS 203, Algorithm 9.
fn ntt(out: *ntt_element, f: ring_element) void = {
	out[..] = f[..];
	let k = 1z;
	for (let ln = 128z; ln >= 2; ln >>= 1) {
		for (let start = 0z; start < 256; start += 2 * ln) {
			let zeta = ZETAS[k];
			k += 1;

			// Bind f after fln since we aren't doing simultaneous.
			let fln = out[start+ln..start+ln+ln];
			let f = out[start..start+ln];
			for (let j = 0z; j < ln; j += 1) {
				let t = field_mul(zeta, fln[j]);
				fln[j] = field_sub(f[j], t);
				f[j] = field_add(f[j], t);
			};
		};
	};
};

// Map a [[ntt_element]] back to the [[ring_element]] it represents.
//
// It implements NTT⁻¹, according to FIPS 203, Algorithm 10.
fn inverse_ntt(out: *ring_element, f: ntt_element) void = {
	out[..] = f[..];
	let k = 127z;
	for (let ln = 2z; ln <= 128; ln *= 2) {
		for (let start = 0z; start < 256; start += 2 * ln) {
			let zeta = ZETAS[k];
			k -= 1;
			let fln = out[start+ln..start+ln+ln];
			let f = out[start..start+ln];
			for (let j = 0z; j < ln; j += 1) {
				let t = f[j];
				f[j] = field_add(t, fln[j]);
				fln[j] = field_mul_sub(zeta, fln[j], t);
			};
		};
	};
	for (let i = 0z; i < len(out); i += 1) {
		out[i] = field_mul(out[i], 3303); // 3303 = 128⁻¹ mod Q
	};
};

// Draw a uniformly random nttElement from a stream of uniformly random bytes
// generated by the XOF function, according to FIPS 203, Algorithm 7.
fn sample_ntt(out: *ntt_element, rho: []u8, ii: u8, jj: u8) void = {
	let xof = sha3::shake128();
	defer io::close(&xof)!;
	io::write(&xof, rho)!;
	let header: [2]u8 = [ii, jj];
	io::write(&xof, header[..])!;

	// SampleNTT essentially draws 12 bits at a time from r, interprets them
	// in little-endian, and rejects values higher than Q, until it drew 256
	// values. (The rejection rate is approximately 19%.)
	//
	// To do this from a bytes stream, it draws three bytes at a time, and
	// splits them into two uint16 appropriately masked.
	//
	//               r₀              r₁              r₂
	//       |- - - - - - - -|- - - - - - - -|- - - - - - - -|
	//
	//               Uint16(r₀ || r₁)
	//       |- - - - - - - - - - - - - - - -|
	//       |- - - - - - - - - - - -|
	//                   d₁
	//
	//                                Uint16(r₁ || r₂)
	//                       |- - - - - - - - - - - - - - - -|
	//                               |- - - - - - - - - - - -|
	//                                           d₂
	//
	// Note that in little-endian, the rightmost bits are the most
	// significant bits (dropped with a mask) and the leftmost bits are the
	// least significant bits (dropped with a right shift).

	// Index into out
	let j = 0z;

	let buf: [24]u8 = @undefined;

	// Index into buf, starts in a "fully consumed" state
	let off = len(buf);
	for (true) {
		if (off >= len(buf)) {
			io::read(&xof, buf[..])!;
			off = 0;
		};

		let d1 = endian::legetu16(buf[off..]) & 0b1111_1111_1111;
		let d2 = endian::legetu16(buf[off+1..]) >> 4;

		off += 3;

		if (d1 < Q) {
			out[j] = d1: field_element;
			j += 1;
		};

		if (j >= len(out))
			break;

		if (d2 < Q) {
			out[j] = d2: field_element;
			j += 1;
		};

		if (j >= len(out))
			break;
	};
};
