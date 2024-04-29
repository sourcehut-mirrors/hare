// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

fn syscall(sysno: u64, ...) (u64, u64);

export fn readv(fd: int, vec: const *[*]iovec, iovcnt: int) (size | errno) = {
	return syswrap(syscall(sys::READV,
			fd: i64, &vec[0], iovcnt: i64))?: size;
};

export fn read(fd: int, buf: *opaque, count: size) (size | errno) = {
	const vec = [
		iovec {
			iov_base = buf,
			iov_len = count,
		},
	];
	return readv(fd, &vec, 1);
};

export fn writev(fd: int, vec: const *[*]iovec, iovcnt: int) (size | errno) = {
	return syswrap(syscall(sys::WRITEV,
			fd: i64, &vec[0], iovcnt: i64))?: size;
};

export fn write(fd: int, buf: *opaque, count: size) (size | errno) = {
	const vec = [
		iovec {
			iov_base = buf,
			iov_len = count,
		},
	];
	return writev(fd, &vec, 1);
};

export fn exit(status: int) never = {
	syscall(sys::EXIT, status: u64);
	abort();
};
