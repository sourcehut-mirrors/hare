// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

// Wraps an [[sys::errno]] to produce an [[error]], which may be [[opaque_]].
// This is a non-portable interface which is mainly provided to support internal
// stdlib requirements.
export fn errno(errno: sys::errno) error = {
	switch (errno) {
	case sys::ECONNREFUSED =>
		return refused;
	case sys::ECANCELED =>
		return cancelled;
	case sys::EOVERFLOW =>
		return overflow;
	case sys::EACCES =>
		return noaccess;
	case sys::EINVAL =>
		return invalid;
	case sys::EEXIST =>
		return exists;
	case sys::ENOENT =>
		return noentry;
	case sys::ETIMEDOUT =>
		return timeout;
	case sys::EBUSY =>
		return busy;
	case sys::EINTR =>
		return interrupted;
	case sys::EAGAIN =>
		return again;
	case sys::ENETUNREACH =>
		return netunreachable;
	case => void;
	};

	static assert(size(sys::errno) <= size(opaque_data));
	let err = opaque_ { strerror = &rt_strerror, ... };
	let ptr = &err.data: *sys::errno;
	*ptr = errno;
	return err;
};

fn rt_strerror(err: *opaque_data) const str = {
	let err = err: *sys::errno;
	return sys::strerror(*err);
};
