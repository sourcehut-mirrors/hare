// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Forward declared
fn rt::call(cap: cap, tag: u64, a1: u64, a2: u64, a3: u64) (u64, u64);

// Performs an IPC call against the provided capability, using the given tag and
// sending the provided list of parameters. The user must have configured the
// IPC buffer's capability list to transfer caps during the call if appropriate.
//
// This is a low-level function; most users should access endpoints via ipcgen.
export fn call(cap: cap, tag: u64, params: u64...) (u64, u64) = {
	// XXX: Arch-specific
	assert(len(params) <= MAX_PARAM, "Excess parameters in rt::call");
	const a1 = if (len(params) > 0) params[0] else 0u64;
	const a2 = if (len(params) > 1) params[1] else 0u64;
	const a3 = if (len(params) > 2) params[2] else 0u64;
	for (let i = 3z; i < len(params); i += 1) {
		ipcbuf.params[i] = params[i];
	};
	return rt::call(cap, tag, a1, a2, a3);
};
