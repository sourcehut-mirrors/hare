// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Builds a message tag.
export fn mktag(label: u64, nparam: u8, ncap: u8) u64 = {
	assert(label & ~((1 << 48) - 1) == 0); // Labels are 48 bits
	return (label << 16) | (ncap: u64 << 8) | nparam: u64;
};

// Returns the number of parameters in a message tag.
export fn nparam(tag: u64) u8 = {
	return (tag & 0xFF): u8;
};

// Returns the number of capabilities in a message tag.
export fn ncap(tag: u64) u16 = {
	return (tag >> 8): u8;
};

// Returns the label for a message tag.
export fn label(tag: u64) u64 = {
	return tag >> 16;
};
