// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// The error numbers returned from syscalls.
export type errno = enum u64 {
	NONE,
	NOMEM,
	INVALID_CADDR,
	INVALID_CSLOT,
	INVALID_CTYPE,
	INVALID_PARAM,
	INVALID_CAP,
	UNSUPPORTED,
	MISSING_TABLE,
	ALREADY_MAPPED,
	INVALID_ASID,
	ACCESS,
	OBJECT_DESTROYED,
	WOULD_BLOCK,
};

// Tagged union of all possible syscall errors.
export type syserror = !(
	nomem |
	invalid_caddr |
	invalid_cslot |
	invalid_ctype |
	invalid_param |
	invalid_cap |
	unsupported |
	missing_table |
	already_mapped |
	invalid_asid |
	access |
	object_destroyed |
	would_block |
);

// Insufficient memory is available to allocate a resource.
export type nomem = !void;

// The given capability address exceeds the bounds of its cspace.
export type invalid_caddr = !void;

// The desired cslot is already occupied by another capability.
export type invalid_cslot = !void;

// A provided capability is not the expected type for the requested operation.
export type invalid_ctype = !void;

// One of the parameters was invalid.
export type invalid_param = !void;

// A capability is required for the requested operation, but was not provided,
// or a capability was provided when none was expected.
export type invalid_cap = !void;

// The desired operation is not supported by this capability type.
export type unsupported = !void;

// A mapping operation was requested but the required page tables are absent.
// The value of this error is the page table capability type required to
// complete the mapping.
export type missing_table = !u64;

// An attempt was made to map a page table into two different vspaces.
export type already_mapped = !void;

// An attempt was made to use an unmapped vspace, or to map an already-mapped
// vspace.
export type invalid_asid = !void;

// An attempt was made to use a capability in a manner not permitted by its set
// of rights.
export type access = !void;

// An object was destroyed while a blocking operation against it was pending.
export type object_destroyed = !void;

// A non-blocking operation was requested, but would block.
export type would_block = !void;

export fn check(ret: (u64, u64)) (u64 | syserror) = {
	switch (ret.0: errno) {
	case errno::NONE =>
		return ret.1;
	case errno::NOMEM =>
		return nomem;
	case errno::INVALID_CADDR =>
		return invalid_caddr;
	case errno::INVALID_CSLOT =>
		return invalid_cslot;
	case errno::INVALID_CTYPE =>
		return invalid_ctype;
	case errno::INVALID_PARAM =>
		return invalid_param;
	case errno::INVALID_CAP =>
		return invalid_cap;
	case errno::UNSUPPORTED =>
		return unsupported;
	case errno::MISSING_TABLE =>
		return ret.1: missing_table: syserror;
	case errno::ALREADY_MAPPED =>
		return already_mapped;
	case errno::INVALID_ASID =>
		return invalid_asid;
	case errno::ACCESS =>
		return access;
	case errno::OBJECT_DESTROYED =>
		return object_destroyed;
	case errno::WOULD_BLOCK =>
		return would_block;
	case =>
		// XXX: For future proofing we should probably stow this
		// somewhere and move on
		abort("Unknown response from kernel");
	};
};

// Converts a [[syserror]] into a human-friendly string.
export fn strerror(err: syserror) str = {
	match (err) {
	case nomem =>
		return "Out of memory";
	case invalid_caddr =>
		return "Invalid capability address";
	case invalid_cslot =>
		return "Invalid capability slot";
	case invalid_ctype =>
		return "Invalid capability type";
	case invalid_param =>
		return "Invalid parameter";
	case invalid_cap =>
		return "Invalid capability usage";
	case unsupported =>
		return "Kernel does not support the requested feature";
	case missing_table =>
		return "Missing page tables";
	case already_mapped =>
		return "Page or page table already mapped";
	case invalid_asid =>
		return "Invalid ASID";
	case access =>
		return "Insufficient rights to invoke capability";
	case object_destroyed =>
		return "The underlying object was destroyed while blocking";
	case would_block =>
		return "Non-blocking operation was requested, but it would block";
	};
};
