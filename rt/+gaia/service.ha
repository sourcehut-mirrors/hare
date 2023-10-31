// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf::{at};

// Looks up a service by its given ID and returns a capability for it from the
// auxillary vector.
export fn service(id: u64) cap = {
	return try_service(id) as cap;
};

// Tries to locate a service given its ID and returns a capability for it from
// the auxillary vector (or void if there is no such service).
export fn try_service(id: u64) (cap | void) = {
	for (let i = 0z; auxv[i].a_type != at::NULL; i += 1) {
		if (auxv[i].a_type != at::CAP_IFACE) {
			continue;
		};
		const iface = auxv[i].a_val;
		assert(auxv[i+1].a_type == at::CAP_ENDPOINT);
		if (iface == id) {
			return auxv[i+1].a_val: cap;
		};
		i += 1;
	};
};
