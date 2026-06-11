// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

use bytes;
use crypto::random;
use math::random;

@test fn field_reduce() void = {
	const limit: u32 = 2u32 * (Q: u32) * (Q: u32);

	for (let a: u32 = 0; a < limit; a += 1) {
		const got = field_reduce(a);
		const exp: field_element = (a % Q: u32): field_element;

		assert(got == exp);
	};
};

@test fn field_add() void = {
	for (let a: field_element = 0: field_element;
			a < Q: field_element; a += 1) {
		for (let b: field_element = 0: field_element;
				b < Q: field_element; b += 1) {
			const got = field_add(a, b);
			const exp: field_element =
				((a + b): u16 % Q: u16): field_element;

			assert(got == exp);
		};
	};
};

@test fn field_sub() void = {
	for (let a: field_element = 0:
			field_element; a < Q: field_element; a += 1) {
		for (let b: field_element = 0: field_element;
				b < Q: field_element; b += 1) {
			const got = field_sub(a, b);
			const exp: field_element =
				((a - b + Q: field_element): u16
					% Q: u16): field_element;

			assert(got == exp);
		};
	};
};

@test fn field_mul() void = {
	for (let a: field_element = 0: field_element;
			a < Q: field_element; a += 1) {
		for (let b: field_element = 0: field_element;
				b < Q: field_element; b += 1) {
			const got = field_mul(a, b);
			const exp: field_element =
				(((a: u32) * (b: u32)) % Q: u32): field_element;

			assert(got == exp);
		};
	};
};

@test fn decompress_compress() void = {
	const bits_values: [3]u8 = [1, 4, 10];

	for (let bits .. bits_values) {
		for (let a: u16 = 0; a < (1u16 << bits); a += 1) {
			const f = decompress(a, bits);
			assert(f < Q: field_element);
			const got = compress(f, bits);
			assert(got == a);
		};

		for (let a: field_element = 0: field_element;
				a < Q: field_element; a += 1) {

			const c = compress(a, bits);
			assert(c < (1u16 << bits));

			const got = decompress(c, bits);

			const diff = {
				const x1 = a - got;
				const x2 = got - a;
				const x3 = a - got + Q: field_element;
				const x4 = got - a + Q: field_element;
				const y1 = if (x1 < x2) x1 else x2;
				const y2 = if (x3 < x4) x3 else x4;
				yield if (y1 < y2) y1 else y2;
			}: field_element;

			const ceil: field_element =
				(Q / (1u16 << bits): u16): field_element;

			assert(diff <= ceil);
		};
	};
};

fn compress_rat(x: field_element, d: u8) u16 = {
	assert(x < Q: field_element);
	assert(d > 0 && d < 12);

	const numerator: u64 = (1u64 << d) * (x: u64);
	const rounded: u64 = (2 * numerator + Q: u64) / (2 * Q: u64);

	return (rounded % (1u64 << d)): u16;
};

@test fn compress() void = {
	for (let d: u8 = 1; d < 12; d += 1) {
		for (let n: u16 = 0; n < Q: u16; n += 1) {
			const expected = compress_rat(n: field_element, d);
			const result = compress(n: field_element, d);

			assert(result == expected);
		};
	};
};

fn decompress_rat(y: u16, d: u8) field_element = {
	assert(y < (1u16 << d));
	assert(d > 0 && d < 12);

	const numerator: u64 = (Q: u64) * (y: u64);
	const rounded: u64 = (2 * numerator + (1u64 << d)) / (2 * (1u64 << d));

	return (rounded % (Q: u64)): field_element;
};

@test fn decompress() void = {
	for (let d: u8 = 1; d < 12; d += 1) {
		for (let n: u16 = 0; n < (1u16 << d); n += 1) {
			const expected = decompress_rat(n, d);
			const result = decompress(n, d);

			assert(result == expected);
		};
	};
};

@test fn encode_decode() void = {
	let rand = math::random::init(1);

	let f: ring_element = @undefined;
	for (let i = 0z; i < len(f); i += 1) {
		f[i] = math::random::u32n(&rand, Q: u32): field_element;
	};

	let b: [384]u8 = [0...];
	crypto::random::buffer(b[..]);

	let g10: ring_element = @undefined;
	ring_decode_and_decompress_10(&g10, b[..320]);
	let out10: [320]u8 = @undefined;
	ring_compress_and_encode_10(out10[..], g10);
	assert(bytes::equal(out10[..], b[..320]));

	let g4: ring_element = @undefined;
	ring_decode_and_decompress_4(&g4, b[..128]);
	let out4: [128]u8 = @undefined;
	ring_compress_and_encode_4(out4[..], g4);
	assert(bytes::equal(out4[..], b[..128]));

	let g1: ring_element = @undefined;
	ring_decode_and_decompress_1(&g1, b[..32]);
	let out1: [32]u8 = @undefined;
	ring_compress_and_encode_1(out1[..], g1);
	assert(bytes::equal(out1[..], b[..32]));

	let e10: [320]u8 = @undefined;
	ring_compress_and_encode_10(e10[..], f);
	let d10: ring_element = @undefined;
	ring_decode_and_decompress_10(&d10, e10[..]);
	let e10_rt: [320]u8 = @undefined;
	ring_compress_and_encode_10(e10_rt[..], d10);
	assert(bytes::equal(e10_rt[..], e10[..]));

	let e4: [128]u8 = @undefined;
	ring_compress_and_encode_4(e4[..], f);
	let d4: ring_element = @undefined;
	ring_decode_and_decompress_4(&d4, e4[..]);
	let e4_rt: [128]u8 = @undefined;
	ring_compress_and_encode_4(e4_rt[..], d4);
	assert(bytes::equal(e4_rt[..], e4[..]));

	let e1: [32]u8 = @undefined;
	ring_compress_and_encode_1(e1[..], f);
	let d1: ring_element = @undefined;
	ring_decode_and_decompress_1(&d1, e1[..]);
	let e1_rt: [32]u8 = @undefined;
	ring_compress_and_encode_1(e1_rt[..], d1);
	assert(bytes::equal(e1_rt[..], e1[..]));
};

fn bit_rev7(n: u8) u8 = {
	assert(n >> 7 == 0);
	let r: u8 = 0;
	r |= n >> 6 & 0b0000_0001;
	r |= n >> 4 & 0b0000_0010;
	r |= n >> 2 & 0b0000_0100;
	r |= n      & 0b0000_1000;
	r |= n << 2 & 0b0001_0000;
	r |= n << 4 & 0b0010_0000;
	r |= n << 6 & 0b0100_0000;
	return r;
};

@test fn zetas() void = {
	const zeta: u32 = 17;

	for (let k = 0z; k < len(ZETAS); k += 1) {
		const exponent: u8 = bit_rev7(k: u8);
		const exp: field_element = {
			let x: u32 = 1;
			for (let i: u8 = 0; i < exponent; i += 1) {
				x = (x * zeta) % Q: u32;
			};
			yield x: field_element;
		}: field_element;

		assert(ZETAS[k] == exp);
	};
};

@test fn gammas() void = {
	const zeta: u32 = 17;

	for (let k = 0z; k < len(GAMMAS); k += 1) {
		const exponent: u16 = (bit_rev7(k: u8): u16) * 2 + 1;
		const exp: field_element = {
			let x: u32 = 1;
			for (let i: u16 = 0; i < exponent; i += 1) {
				x = (x * zeta) % Q: u32;
			};
			yield x: field_element;
		}: field_element;

		assert(GAMMAS[k] == exp);
	};
};
