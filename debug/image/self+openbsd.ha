// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;

// Opens the executing process's binary image.
export fn self() (image | io::error | errors::error) = {
	// OpenBSD only supports the fallback approach.
	return self_argv();
};
