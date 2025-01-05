// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt::malloc; // link

fn realloc_glue(p: nullable *opaque, n: size) nullable *opaque = {
	return malloc::realloc(p, n);
};
