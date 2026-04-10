// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::math;
use endian;
use hash;
use io;

// The size, in bytes, of a BLAKE2b-256 digest.
export def SZ2B_256: size = 32;

// The size, in bytes, of a BLAKE2b-512 digest.
export def SZ2B_512: size = 64;

// The block size, in bytes, of a BLAKE2b hash.
export def BLOCKSZ2B: size = 128;

// The maximum key size, in bytes, for BLAKE2b keyed hashing.
export def MAXKEYSZ2B: size = 64;

// The size, in bytes, of a BLAKE2s-128 digest.
export def SZ2S_128: size = 16;

// The size, in bytes, of a BLAKE2s-256 digest.
export def SZ2S_256: size = 32;

// The block size, in bytes, of a BLAKE2s hash.
export def BLOCKSZ2S: size = 64;

// The maximum key size, in bytes, for BLAKE2s keyed hashing.
export def MAXKEYSZ2S: size = 32;

// BLAKE2b initialization vector.
const iv2b: [8]u64 = [
	0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
	0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
	0x510e527fade682d1, 0x9b05688c2b3e6c1f,
	0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
];

// BLAKE2s initialization vector.
const iv2s: [8]u32 = [
	0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
	0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

// Message word schedule for BLAKE2b (12 rounds).
const sigma2b: [12][16]u8 = [
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
	[11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
	[7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
	[9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
	[2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
	[12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
	[13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
	[6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
	[10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
];

// Message word schedule for BLAKE2s (10 rounds).
const sigma2s: [10][16]u8 = [
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
	[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
	[11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
	[7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
	[9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
	[2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
	[12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
	[13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
	[6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
	[10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
];

// BLAKE2b digest state.
export type digest2b = struct {
	hash::hash,
	h: [8]u64,
	tlow: u64,
	thigh: u64,
	block: [BLOCKSZ2B]u8,
	blocklen: size,
	// Saved initial state for reset.
	h_init: [8]u64,
	block_init: [BLOCKSZ2B]u8,
	blocklen_init: size,
};

// BLAKE2s digest state.
export type digest2s = struct {
	hash::hash,
	h: [8]u32,
	tlow: u32,
	thigh: u32,
	block: [BLOCKSZ2S]u8,
	blocklen: size,
	// Saved initial state for reset.
	h_init: [8]u32,
	block_init: [BLOCKSZ2S]u8,
	blocklen_init: size,
};

const blake2b_vtable: io::vtable = io::vtable {
	writer = &blake2b_write,
	closer = &blake2b_close,
	...
};

const blake2s_vtable: io::vtable = io::vtable {
	writer = &blake2s_write,
	closer = &blake2s_close,
	...
};

// Creates a [[hash::hash]] which computes a BLAKE2b hash with a given key and a
// given hash size. The size must be between 1 and [[SZ2B_512]], inclusive. The
// key must be at most [[MAXKEYSZ2B]] bytes. If this function is used to hash
// sensitive information, the caller should call [[hash::close]] to erase
// sensitive data from memory after use; if not, the use of [[hash::close]] is
// optional.
export fn blake2b(key: []u8, sz: size) digest2b = {
	assert(len(key) <= MAXKEYSZ2B, "blake2b: invalid key size");
	assert(1 <= sz && sz <= SZ2B_512, "blake2b: invalid hash size");

	let d = digest2b {
		stream = &blake2b_vtable,
		sum = &blake2b_sum,
		reset = &blake2b_reset,
		sz = sz,
		bsz = BLOCKSZ2B,
		h = [0...],
		tlow = 0,
		thigh = 0,
		block = [0...],
		blocklen = 0,
		h_init = [0...],
		block_init = [0...],
		blocklen_init = 0,
		...
	};

	d.h[..] = iv2b[..];

	// XOR with parameter block: p[0] = 0x01010000 ^ (kk << 8) ^ nn
	d.h[0] ^= 0x01010000 ^ (len(key) << 8) ^ sz;

	// If keyed, pad the key to a full block and process it as the
	// first data block.
	if (len(key) > 0) {
		d.block[..len(key)] = key[..];
		d.blocklen = BLOCKSZ2B;
	};

	// Save initial state for reset.
	d.h_init[..] = d.h[..];
	d.block_init[..] = d.block[..];
	d.blocklen_init = d.blocklen;

	return d;
};

// Creates a [[hash::hash]] which computes a BLAKE2s hash with a given key and a
// given hash size. The size must be between 1 and [[SZ2S_256]], inclusive. The
// key must be at most [[MAXKEYSZ2S]] bytes. If this function is used to hash
// sensitive information, the caller should call [[hash::close]] to erase
// sensitive data from memory after use; if not, the use of [[hash::close]] is
// optional.
export fn blake2s(key: []u8, sz: size) digest2s = {
	assert(len(key) <= MAXKEYSZ2S, "blake2s: invalid key size");
	assert(1 <= sz && sz <= SZ2S_256, "blake2s: invalid hash size");

	let d = digest2s {
		stream = &blake2s_vtable,
		sum = &blake2s_sum,
		reset = &blake2s_reset,
		sz = sz,
		bsz = BLOCKSZ2S,
		h = [0...],
		tlow = 0,
		thigh = 0,
		block = [0...],
		blocklen = 0,
		h_init = [0...],
		block_init = [0...],
		blocklen_init = 0,
		...
	};

	d.h[..] = iv2s[..];

	// XOR with parameter block: p[0] = 0x01010000 ^ (kk << 8) ^ nn
	let kk = len(key): u32;
	d.h[0] ^= 0x01010000 ^ (kk << 8) ^ (sz: u32);

	// If keyed, pad the key to a full block and process it as the
	// first data block.
	if (len(key) > 0) {
		let padded: [BLOCKSZ2S]u8 = [0...];
		padded[..len(key)] = key[..];
		d.block[..] = padded[..];
		d.blocklen = BLOCKSZ2S;
		bytes::zero(padded);
	};

	// Save initial state for reset.
	d.h_init[..] = d.h[..];
	d.block_init[..] = d.block[..];
	d.blocklen_init = d.blocklen;

	return d;
};

fn blake2b_reset(h: *hash::hash) void = {
	let d = h: *digest2b;
	d.h[..] = d.h_init[..];
	d.tlow = 0;
	d.thigh = 0;
	d.block[..] = d.block_init[..];
	d.blocklen = d.blocklen_init;
};

fn blake2s_reset(h: *hash::hash) void = {
	let d = h: *digest2s;
	d.h[..] = d.h_init[..];
	d.tlow = 0;
	d.thigh = 0;
	d.block[..] = d.block_init[..];
	d.blocklen = d.blocklen_init;
};
