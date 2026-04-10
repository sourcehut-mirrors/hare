// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math;
use endian;
use hash;
use io;

// BLAKE2s rotation constants.
def R2S_1: int = 16;
def R2S_2: int = 12;
def R2S_3: int = 8;
def R2S_4: int = 7;

fn blake2s_write(st: *io::stream, buf: const []u8) (size | io::error) = {
	let d = st: *digest2s;
	if (len(buf) == 0) return 0z;
	let length = len(buf);
	let buf = buf[..];

	for (d.blocklen + len(buf) > BLOCKSZ2S) {
		const n = BLOCKSZ2S - d.blocklen;
		d.block[d.blocklen..d.blocklen + n] = buf[..n];
		buf = buf[n..];

		incr_counter2s(d, BLOCKSZ2S: u32);

		compress2s(d, false);
		d.blocklen = 0;
	};
	d.block[d.blocklen..d.blocklen + len(buf)] = buf;
	d.blocklen += len(buf);
	return length;
};

fn blake2s_sum(h: *hash::hash, buf: []u8) void = {
	let d = h: *digest2s;

	// Pad the final block with zeros.
	if (d.blocklen < BLOCKSZ2S) {
		bytes::zero(d.block[d.blocklen..]);
	};

	incr_counter2s(d, d.blocklen: u32);
	compress2s(d, true);

	let full: [SZ2S_256]u8 = [0...];
	for (let i = 0z; i < 8; i += 1) {
		endian::leputu32(full[i * 4..i * 4 + 4], d.h[i]);
	};
	buf[..d.sz] = full[..d.sz];
};

fn blake2s_close(stream: *io::stream) (void | io::error) = {
	let s = stream: *digest2s;
	bytes::zero((s.h[..]: *[*]u8)[..len(s.h) * size(u32)]);
	bytes::zero(s.block);
	bytes::zero((s.h_init[..]: *[*]u8)[..len(s.h_init) * size(u32)]);
	bytes::zero(s.block_init);
};

// Increment the byte counter by inc bytes.
fn incr_counter2s(d: *digest2s, inc: u32) void = {
	const new_tlow = d.tlow + inc;
	if (new_tlow < d.tlow) {
		d.thigh += 1;
	};
	d.tlow = new_tlow;
};

// BLAKE2s compression function F.
fn compress2s(d: *digest2s, last: bool) void = {
	let v: [16]u32 = [0...];
	v[0..8] = d.h[..];
	v[8..16] = iv2s[..];

	v[12] ^= d.tlow;
	v[13] ^= d.thigh;

	if (last) {
		v[14] = ~v[14];
	};

	// Decode message block into 16 little-endian u32 words.
	let m: [16]u32 = [0...];
	for (let i = 0z; i < 16; i += 1) {
		m[i] = endian::legetu32(d.block[i * 4..i * 4 + 4]);
	};

	// 10 rounds of mixing.
	for (let i = 0z; i < 10; i += 1) {
		const s = &sigma2s[i];
		// Column step.
		mix2s(&v, 0, 4, 8, 12, m[s[0]], m[s[1]]);
		mix2s(&v, 1, 5, 9, 13, m[s[2]], m[s[3]]);
		mix2s(&v, 2, 6, 10, 14, m[s[4]], m[s[5]]);
		mix2s(&v, 3, 7, 11, 15, m[s[6]], m[s[7]]);
		// Diagonal step.
		mix2s(&v, 0, 5, 10, 15, m[s[8]], m[s[9]]);
		mix2s(&v, 1, 6, 11, 12, m[s[10]], m[s[11]]);
		mix2s(&v, 2, 7, 8, 13, m[s[12]], m[s[13]]);
		mix2s(&v, 3, 4, 9, 14, m[s[14]], m[s[15]]);
	};

	// Finalize: h[i] = h[i] ^ v[i] ^ v[i+8]
	for (let i = 0z; i < 8; i += 1) {
		d.h[i] ^= v[i] ^ v[i + 8];
	};
};

// BLAKE2s mixing function G.
fn mix2s(v: *[16]u32, a: size, b: size, c: size, d: size, x: u32, y: u32) void = {
	v[a] = v[a] + v[b] + x;
	v[d] = math::rotr32(v[d] ^ v[a], R2S_1);
	v[c] = v[c] + v[d];
	v[b] = math::rotr32(v[b] ^ v[c], R2S_2);
	v[a] = v[a] + v[b] + y;
	v[d] = math::rotr32(v[d] ^ v[a], R2S_3);
	v[c] = v[c] + v[d];
	v[b] = math::rotr32(v[b] ^ v[c], R2S_4);
};
