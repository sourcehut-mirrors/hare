// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type DIR = opaque;

// opendir

@symbol("fdopendir") fn libc_fdopendir(fd: int) nullable *DIR;

export fn fdopendir(dirfd: int) (*DIR | errno) = {
	match (libc_fdopendir(dirfd)) {
	case let d: *DIR =>
		return d;
	case null =>
		return *__errno(): errno;
	};
};

@symbol("closedir") fn libc_closedir(dir: *DIR) int;

export fn closedir(dir: *DIR) (int | errno) = {
	let res = libc_closedir(dir);
	if (res == -1) {
		return *__errno(): errno;
	};
	return res;
};

@symbol("readdir") fn libc_readdir(dir: *DIR) nullable *dirent;

export fn readdir(dir: *DIR) (nullable *dirent | errno) = {
	match (libc_readdir(dir)) {
	case let d: *dirent =>
		return d;
	case null =>
		let err = *__errno(): errno;
		if (err != 0) {
			return err;
		};
		return null;
	};
};

export def DT_UNKNOWN = 0x0;
export def DT_FIFO = 0x1;
export def DT_CHR = 0x2;
export def DT_DIR = 0x4;
export def DT_BLK = 0x6;
export def DT_REG = 0x8;
export def DT_LNK = 0xA;
export def DT_SOCK = 0xC;
export def DT_BITS = 0xF;

export type dirent = struct {
	d_reclen: size,
	d_namlen: size,
	d_ino: ino_t,
	d_dev: dev_t,
	d_type: u8,
	d_name: [*]u8,
};
