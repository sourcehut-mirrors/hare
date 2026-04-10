// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use encoding::hex;
use fmt;
use hash;
use io;
use memio;
use strings;

@test fn blake2s_vectors() void = {
	for (let vector .. blake2s_vectors) {
		let key = hex::decodestr(vector.key)!;
		defer free(key);

		let out = hex::decodestr(vector.out)!;
		defer free(out);

		let in = hex::decodestr(vector.in)!;
		defer free(in);

		let blake = blake2s(key, len(out));
		defer hash::close(&blake);
		hash::write(&blake, in);

		let sum: []u8 = alloc([0...], len(out))!;
		defer free(sum);
		hash::sum(&blake, sum);

		let out = memio::dynamic();
		defer io::close(&out)!;

		let enc = hex::newencoder(&out);
		io::write(&enc, sum)!;

		assert(memio::string(&out)! == vector.out);
	};
};

// Test with data that spans multiple blocks (> 64 bytes).
@test fn blake2s_multiple_writes() void = {
	// 72 bytes of zeros.
	let data: [72]u8 = [0...];

	// Compute via single write.
	let h1 = blake2s([], SZ2S_256);
	hash::write(&h1, data);
	let r1: [SZ2S_256]u8 = [0...];
	hash::sum(&h1, r1);

	// Compute via two writes (split at block boundary).
	let h2 = blake2s([], SZ2S_256);
	hash::write(&h2, data[..64]);
	hash::write(&h2, data[64..]);
	let r2: [SZ2S_256]u8 = [0...];
	hash::sum(&h2, r2);

	assert(bytes::equal(r1, r2));
};
