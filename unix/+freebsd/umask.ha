// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use rt;

// Sets the file mode creation mask for the current process and return the
// previous value of the mask.
export fn umask(mode: io::mode) io::mode = rt::umask(mode: rt::mode_t)!: io::mode;
