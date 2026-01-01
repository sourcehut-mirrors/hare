// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Error number returned from the kernel.
export type errno = !uint;

export def EWRONGTYPE: errno = 1;
export def ENOMEM: errno = 2;
export def EINVAL: errno = 3;
export def EINVALCADDR: errno = 4;
export def ERANGE: errno = 5;
export def EEXIST: errno = 6;
export def ENOENT: errno = 7;
export def EBUSY: errno = 8;
export def ENOTSUP: errno = 9;
export def ENOSYS: errno = 10;
export def EFAULT: errno = 11;
export def EL1PT: errno = 12;
export def EL2PT: errno = 13;
export def EL3PT: errno = 14;
export def EL4PT: errno = 15;
export def EDESTROYED: errno = 16;

// User errno range is from 128+

export def ECONNREFUSED: errno = 128;
export def ECANCELED: errno = 129;
export def EOVERFLOW: errno = 130;
export def EACCES: errno = 131;
export def ETIMEDOUT: errno = 132;
export def EINTR: errno = 133;
export def EAGAIN: errno = 134;
export def ENETUNREACH: errno = 135;

// Converts an [[errno]] to a user-friendly string.
export fn strerror(err: errno) const str = {
	switch (err) {
	case EWRONGTYPE =>
		return "An incorrect resource type was used in an operation.";
	case ENOMEM =>
		return "Insufficient memory available for requested operation.";
	case EINVAL =>
		return "An invalid parameter was supplied for an operation.";
	case EINVALCADDR =>
		return "An invalid capability address was used.";
	case ERANGE =>
		return "A parameter exceeds the permissible range.";
	case EEXIST =>
		return "A resource already exists at the given address.";
	case ENOENT =>
		return "A required resource does not exist.";
	case EBUSY =>
		return "A required resource is currently in use.";
	case ENOTSUP =>
		return "The requested operation is not supported for this resource type.";
	case ENOSYS =>
		return "Invalid syscall.";
	case EFAULT =>
		return "Use of invalid address.";
	case EL1PT =>
		return "VSpace mapping is missing a required level 1 page table.";
	case EL2PT =>
		return "VSpace mapping is missing a required level 2 page table.";
	case EL3PT =>
		return "VSpace mapping is missing a required level 3 page table.";
	case EL4PT =>
		return "VSpace mapping is missing a required level 4 page table.";
	case EDESTROYED =>
		return "A required resource was destroyed during the requested operation.";
	case =>
		return "Unknown error";
	};
};

// Gets the programmer-friendly name for an [[errno]] (e.g. EPERM). The return
// value may be statically allocated.
export fn errname(err: errno) str = {
	switch (err) {
	case EWRONGTYPE =>
		return "EWRONGTYPE";
	case ENOMEM =>
		return "ENOMEM";
	case EINVAL =>
		return "EINVAL";
	case EINVALCADDR =>
		return "EINVALCADDR";
	case ERANGE =>
		return "ERANGE";
	case EEXIST =>
		return "EEXIST";
	case ENOENT =>
		return "ENOENT";
	case EBUSY =>
		return "EBUSY";
	case ENOTSUP =>
		return "ENOTSUP";
	case ENOSYS =>
		return "ENOSYS";
	case EFAULT =>
		return "EFAULT";
	case EL1PT =>
		return "EL1PT";
	case EL2PT =>
		return "EL2PT";
	case EL3PT =>
		return "EL3PT";
	case EL4PT =>
		return "EL4PT";
	case EDESTROYED =>
		return "EDESTROYED";
	case =>
		return unknown_errno(err);
	};
};
