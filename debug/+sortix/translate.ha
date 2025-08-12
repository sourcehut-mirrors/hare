// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Tries to translate a pointer into an ELF address of the currently running
// binary.
export fn translate(ptr: uintptr) (uintptr | void) = {
	// Sortix does not do PIE w/ASLR or the like.
	return ptr;
};
