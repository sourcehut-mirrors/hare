// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fs;
use io;

// Not implemented on Hermes (yet)
export fn self() (image | io::error | fs::error) = {
	return errors::noentry: io::error;
};
