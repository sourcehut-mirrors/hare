// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fs;
use sys;

// Sets the file mode creation mask for the current process and return the
// previous value of the mask.
export fn umask(mode: fs::mode) fs::mode = sys::umask(mode)!: fs::mode;
