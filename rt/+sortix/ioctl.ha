export def __IOCTL_TYPE_EXP = 3;
export def __IOCTL_TYPE_MASK = ((1 << __IOCTL_TYPE_EXP) - 1);
export def __IOCTL_TYPE_VOID = 0;
export def __IOCTL_TYPE_INT = 1;
export def __IOCTL_TYPE_LONG = 2;
export def __IOCTL_TYPE_PTR = 3;

export def TIOCGWINSZ = 1 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_PTR;
export def TIOCSWINSZ = 2 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_PTR;
export def TIOCSCTTY = 3 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_INT;
export def TIOCSPTLCK = 4 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_PTR;
export def TIOCGPTLCK = 5 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_PTR;
export def TIOCGNAME = 6 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_PTR;
export def TIOCGPTN = 7 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_PTR;
export def TIOCGDISPLAYS = 8 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_PTR;
export def TIOCUCTTY = 9 << __IOCTL_TYPE_EXP | __IOCTL_TYPE_INT;

@symbol("ioctl") fn libc_ioctl(fd: int, req: u64, arg: u64) int;

export type ioctl_arg = (nullable *opaque | u64);

export fn ioctl(fd: int, req: u64, arg: ioctl_arg) (int | errno) = {
	let res = match (arg) {
	case let u: u64 =>
		yield libc_ioctl(fd, req, u);
	case let ptr: nullable *opaque =>
		yield libc_ioctl(fd, req, ptr: uintptr: u64);
	};
	if (res == -1) {
		return __errno();
	};
	return res;
};
