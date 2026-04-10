// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math;
use endian;
use hash;
use io;

// BLAKE2b rotation constants.
def R2B_1: int = 32;
def R2B_2: int = 24;
def R2B_3: int = 16;
def R2B_4: int = 63;

fn blake2b_write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let d = st: *digest2b;
	if (len(buf) == 0) return 0z;
	let length = len(buf);
	let buf = buf[..];

	for (d.blocklen + len(buf) > BLOCKSZ2B) {
		const n = BLOCKSZ2B - d.blocklen;
		d.block[d.blocklen..d.blocklen + n] = buf[..n];
		buf = buf[n..];

		incr_counter2b(d, BLOCKSZ2B: u64);

		compress2b(d, false);
		d.blocklen = 0;
	};
	d.block[d.blocklen..d.blocklen + len(buf)] = buf;
	d.blocklen += len(buf);
	return length;
};

fn blake2b_sum(h: *hash::hash, buf: []u8) void = {
	let d = h: *digest2b;

	// Pad the final block with zeros.
	if (d.blocklen < BLOCKSZ2B) {
		bytes::zero(d.block[d.blocklen..]);
	};

	incr_counter2b(d, d.blocklen: u64);
	compress2b(d, true);

	let full: [SZ2B_512]u8 = [0...];
	for (let i = 0z; i < 8; i += 1) {
		endian::leputu64(full[i * 8..i * 8 + 8], d.h[i]);
	};
	buf[..d.sz] = full[..d.sz];
};

fn blake2b_close(stream: *io::stream) (void | io::error) = {
	let s = stream: *digest2b;
	bytes::zero((s.h[..]: *[*]u8)[..len(s.h) * size(u64)]);
	bytes::zero(s.block);
	bytes::zero((s.h_init[..]: *[*]u8)[..len(s.h_init) * size(u64)]);
	bytes::zero(s.block_init);
};

// Increment the byte counter by inc bytes.
fn incr_counter2b(d: *digest2b, inc: u64) void = {
	const new_tlow = d.tlow + inc;
	if (new_tlow < d.tlow) {
		d.thigh += 1;
	};
	d.tlow = new_tlow;
};

// BLAKE2b compression function F.
fn compress2b(d: *digest2b, last: bool) void = {
	let v: [16]u64 = [0...];
	v[..8] = d.h[..];
	v[8..] = iv2b;
	v[12] ^= d.tlow;
	v[13] ^= d.thigh;
	if (last) v[14] = ~v[14];
	let m: [16]u64 = [0...];
	for (let i = 0z; i < len(m); i += 1) {
		m[i] = endian::legetu64(d.block[i * 8..i * 8 + 8]);
	};
	for (let i = 0z; i < 12; i += 1) {
		const s = &sigma2b[i];
		// Column step.
		mix2b(&v, 0, 4, 8, 12, m[s[0]], m[s[1]]);
		mix2b(&v, 1, 5, 9, 13, m[s[2]], m[s[3]]);
		mix2b(&v, 2, 6, 10, 14, m[s[4]], m[s[5]]);
		mix2b(&v, 3, 7, 11, 15, m[s[6]], m[s[7]]);
		// Diagonal step.
		mix2b(&v, 0, 5, 10, 15, m[s[8]], m[s[9]]);
		mix2b(&v, 1, 6, 11, 12, m[s[10]], m[s[11]]);
		mix2b(&v, 2, 7, 8, 13, m[s[12]], m[s[13]]);
		mix2b(&v, 3, 4, 9, 14, m[s[14]], m[s[15]]);
	};

	for (let i = 0; i < 8; i += 1) {
		d.h[i] ^= v[i] ^ v[i + 8];
	};
};

// BLAKE2b mixing function G.
fn mix2b(v: *[16]u64, a: size, b: size, c: size, d: size, x: u64, y: u64) void = {
	v[a] = v[a] + v[b] + x;
	v[d] = math::rotr64(v[d] ^ v[a], R2B_1);
	v[c] = v[c] + v[d];
	v[b] = math::rotr64(v[b] ^ v[c], R2B_2);
	v[a] = v[a] + v[b] + y;
	v[d] = math::rotr64(v[d] ^ v[a], R2B_3);
	v[c] = v[c] + v[d];
	v[b] = math::rotr64(v[b] ^ v[c], R2B_4);
};
