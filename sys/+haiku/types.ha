// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type time_t = i64;
export type clock_t = i32;
export type clockid_t = i32;
export type suseconds_t = i32;
export type dev_t = i32;
export type ino_t = i64;
export type nlink_t = i32;
export type id_t = i32;
export type pid_t = i32;
export type uid_t = u32;
export type gid_t = u32;
export type off_t = i64;
export type blkcnt_t = i64;
export type blksize_t = i32;
export type nfds_t = u64;
export type mode_t = u32;
export type sigset = u64;
export type rlim_t = uintptr;

// Maximum length of a file path including the NUL terminator.
export def PATH_MAX: size = 1024;

export def NAME_MAX: size = 256;

export def S_ISUID: mode_t = 0o4000;
export def S_ISGID: mode_t = 0o2000;
export def S_ISTXT: mode_t = 0o1000;
export def S_IRWXU: mode_t = 0o700;
export def S_IRUSR: mode_t = 0o400;
export def S_IWUSR: mode_t = 0o200;
export def S_IXUSR: mode_t = 0o100;
export def S_IRWXG: mode_t = 0o070;
export def S_IRGRP: mode_t = 0o040;
export def S_IWGRP: mode_t = 0o020;
export def S_IXGRP: mode_t = 0o010;
export def S_IRWXO: mode_t = 0o007;
export def S_IROTH: mode_t = 0o004;
export def S_IWOTH: mode_t = 0o002;
export def S_IXOTH: mode_t = 0o001;
export def S_IFMT: mode_t = 0o170000;
export def S_IFIFO: mode_t = 0o010000;
export def S_IFCHR: mode_t = 0o020000;
export def S_IFDIR: mode_t = 0o040000;
export def S_IFBLK: mode_t = 0o060000;
export def S_IFREG: mode_t = 0o100000;
export def S_IFLNK: mode_t = 0o120000;
export def S_IFSOCK: mode_t = 0o140000;
export def S_ISVTX: mode_t = 0o001000;

export def O_RDONLY: int = 0x0;
export def O_WRONLY: int = 0x1;
export def O_RDWR: int = 0x2;
export def O_ACCMODE: int = 0x3;
export def O_EXCL: int = 0x0100;
export def O_CREAT: int = 0x0200;
export def O_TRUNC: int = 0x0400;
export def O_NOCTTY: int = 0x100;
export def O_NOTRAVERSE: int = 0x2000;
export def O_CLOEXEC: int = 0x00000040;
export def O_NONBLOCK: int = 0x00000080;
export def O_NDELAY: int = O_NONBLOCK;
export def O_APPEND: int = 0x00000800;
export def O_SYNC: int = 0x00010000;
export def O_RSYNC: int = 0x00020000;
export def O_DSYNC: int = 0x00040000;
export def O_NOFOLLOW: int = 0x00080000;
export def O_DIRECT: int = 0x00100000;
export def O_NOCACHE: int = O_DIRECT;
export def O_DIRECTORY: int = 0x00200000;

export def WAIT_ANY: pid_t = -1;
export def WAIT_MYPGRP: pid_t = 0;

export def WNOHANG: int = 0x1;
export def WUNTRACED: int = 0x2;
export def WCONTINUED: int = 0x4;
export def WEXITED: int = 0x8;
export def WSTOPPED: int = 0x10;
export def WNOWAIT: int = 0x20;

export fn wtermsig(status: int) int = (status >> 8) & 0xff;
export fn wifexited(status: int) bool = status & ~0xff == 0;
export fn wexitstatus(status: int) int = status & 0xff;
export fn wifsignaled(status: int) bool = (status >> 8) & 0xff != 0;

export type rusage = struct {
	ru_utime: timeval,
	ru_stime: timeval,
	ru_maxrss: i64,
	ru_ixrss: i64,
	ru_idrss: i64,
	ru_isrss: i64,
	ru_minflt: i64,
	ru_majflt: i64,
	ru_nswap: i64,
	ru_inblock: i64,
	ru_oublock: i64,
	ru_msgsnd: i64,
	ru_msgrcv: i64,
	ru_nsignals: i64,
	ru_nvcsw: i64,
	ru_nivcsw: i64,
};

export def RUSAGE_SELF: int = 0;
export def RUSAGE_CHILDREN: int = -1;

export def F_OK: int = 0;
export def X_OK: int = 0x1;
export def W_OK: int = 0x2;
export def R_OK: int = 0x4;

export def AT_FDCWD: int = -100;
export def AT_SYMLINK_NOFOLLOW: int = 0x1;
export def AT_SYMLINK_FOLLOW: int = 0x2;
export def AT_REMOVEDIR: int = 0x4;
export def AT_EACCESS: int = 0x8;

export def PROT_NONE: int = 0x0;
export def PROT_READ: int = 0x1;
export def PROT_WRITE: int = 0x2;
export def PROT_EXEC: int = 0x4;

export def MAP_SHARED: int = 0x01;
export def MAP_PRIVATE: int = 0x02;
export def MAP_FIXED: int = 0x04;
export def MAP_ANONYMOUS: int = 0x08;
export def MAP_ANON: int = MAP_ANONYMOUS;
export def MAP_NORESERVE: int = 0x10;
export def MAP_FAILED: *opaque = -1: uintptr: *opaque;

export def NGROUPS_MAX: size = 32;

export type timespec = struct {
	tv_sec: time_t,
	tv_nsec: i64,
};

export def UTIME_OMIT = 1000000001;

export def CLOCK_MONOTONIC: clockid_t = 0;
export def CLOCK_REALTIME: clockid_t = -1;
export def CLOCK_PROCESS_CPUTIME_ID: clockid_t = -2;
export def CLOCK_THREAD_CPUTIME_ID: clockid_t = -3;

export def F_DUPFD: int = 0x0001;
export def F_GETFD: int = 0x0002;
export def F_SETFD: int = 0x0004;
export def F_GETFL: int = 0x0008;
export def F_SETFL: int = 0x0010;
export def F_GETLK: int = 0x0020;
export def F_SETLK: int = 0x000;
export def F_SETLKW: int = 0x0100;
export def F_DUPFD_CLOEXEC: int = 0x0200;

export def FD_CLOEXEC: int = 1;

export def F_RDLCK: i16 = 0x0040;
export def F_UNLCK: i16 = 0x0200;
export def F_WRLCK: i16 = 0x0400;

export type st_flock = struct {
	l_type: i16,
	l_whence: i16,
	l_start: off_t,
	l_len: off_t,
	l_pid: pid_t,
};

export type dirent = struct {
	d_dev: dev_t,
	d_pdev: dev_t,
	d_ino: ino_t,
	d_pino: ino_t,
	d_reclen: u16,
	d_name: [*]u8,
};

export def MAXNAMLEN: size = 256;
export def MAXHOSTNAMELEN: size = 256;

export type pollfd = struct {
	fd: int,
	events: i16,
	revents: i16,
};

export def POLLIN: i16 = 0x0001;
export def POLLOUT: i16 = 0x0002;
export def POLLRDNORM: i16 = POLLIN;
export def POLLWRNORM: i16 = POLLOUT;
export def POLLRDBAND: i16 = 0x0008;
export def POLLWRBAND: i16 = 0x0010;
export def POLLPRI: i16 = 0x0020;
export def POLLERR: i16 = 0x0004;
export def POLLHUP: i16 = 0x0080;
export def POLLNVAL: i16 = 0x1000;

export type iovec = struct {
	iov_base: nullable *opaque,
	iov_len: size,
};

export def NSIG: int = 32;

export type sigact = struct {
	union {
		sa_handler: nullable *fn (_: int) void,
		sa_sigaction: nullable *fn (_: int, _: *siginfo, _: *opaque) void,
	},
	sa_mask: sigset,
	sa_flags: int,
	sa_userdata: *opaque,
};

export type siginfo = struct {
	si_signo: int,
	si_code: int,
	si_errno: int,
	si_pid: pid_t,
	si_uid: uid_t,
	si_addr: nullable *opaque,
	si_status: int,
	si_band: i64,
	si_value: sigval,
};

export type sigval = union {
	sival_int: int,
	sival_ptr: *opaque,
};

export type stack_t = struct {
	ss_sp: *opaque,
	ss_size: size,
	ss_flags: int,
};

export type timeval = struct {
	tv_sec: time_t,
	tv_usec: suseconds_t,
};

export type stat = struct {
	st_dev: dev_t,
	st_ino: ino_t,
	st_mode: mode_t,
	st_nlink: nlink_t,
	st_uid: uid_t,
	st_gid: gid_t,
	st_size: off_t,
	st_rdev: dev_t,
	st_blksize: blksize_t,
	st_atim: timespec,
	st_mtim: timespec,
	st_ctim: timespec,
	st_crtim: timespec,
	st_type: u32,
	st_blocks: blkcnt_t,
};

export type winsize = struct {
	ws_row: u16,
	ws_col: u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
};

export type termios = struct {
	c_iflag: tcflag,
	c_oflag: tcflag,
	c_cflag: tcflag,
	c_lflag: tcflag,
	c_line: u8,
	c_ispeed: int,
	c_ospeed: int,
	c_cc: [NCCS]cc,
};

export def NCCS: size = 11;

export type tcflag = enum uint {
	// c_iflag bits
	IGNBRK = 0x1,
	BRKINT = 0x2,
	IGNPAR = 0x4,
	PARMRK = 0x8,
	INPCK = 0x10,
	ISTRIP = 0x20,
	INLCR = 0x40,
	IGNCR = 0x80,
	ICRNL = 0x100,
	IUCLC = 0x200,
	IXON = 0x400,
	IXANY = 0x800,
	IXOFF = 0x1000,

	// c_oflag bits
	OPOST = 0x01,
	OLCUC = 0x02,
	ONLCR = 0x04,
	OCRNL = 0x08,
	ONOCR = 0x10,
	ONLRET = 0x20,
	OFILL = 0x40,
	OFDEL = 0x80,
	NLDLY = 0x100,
	NL0 = 0x000,
	NL1 = 0x100,
	CRDLY = 0x600,
	CR0 = 0x000,
	CR1 = 0x200,
	CR2 = 0x400,
	CR3 = 0x600,
	TABDLY = 0x1800,
	TAB0 = 0x0000,
	TAB1 = 0x0800,
	TAB2 = 0x1000,
	TAB3 = 0x1800,
	BSDLY = 0x2000,
	BS0 = 0x0000,
	BS1 = 0x2000,
	VTDLY = 0x4000,
	VT0 = 0x0000,
	VT1 = 0x4000,
	FFDLY = 0x8000,
	FF0 = 0x0000,
	FF1 = 0x8000,

	// c_cflag bits
	CSIZE = 0x20,
	CS5 = 0x00,
	CS6 = 0x00,
	CS7 = 0x00,
	CS8 = 0x20,
	CSTOPB = 0x40,
	CREAD = 0x80,
	PARENB = 0x100,
	PARODD = 0x200,
	HUPCL = 0x400,
	CLOCAL = 0x800,
	XLOBLK = 0x1000,
	CTSFLOW = 0x2000,
	RTSFLOW = 0x4000,
	CRTSCTS = (RTSFLOW | CTSFLOW),

	// c_lflag bits
	ISIG = 0x01,
	ICANON = 0x02,
	XCASE = 0x04,
	ECHO = 0x08,
	ECHOE = 0x10,
	ECHOK = 0x20,
	ECHONL = 0x40,
	NOFLSH = 0x80,
	TOSTOP = 0x100,
	IEXTEN = 0x200,
	ECHOCTL = 0x400,
	ECHOPRT = 0x800,
	ECHOKE = 0x1000,
	FLUSHO = 0x2000,
	PENDIN = 0x4000,
};

export type cc = enum u8 {
	VINTR = 0,
	VQUIT = 1,
	VERASE = 2,
	VKILL = 3,
	VEOF = 4,
	VEOL = 5,
	VMIN = 4,
	VTIME = 5,
	VEOL2 = 6,
	VSWTCH = 7,
	VSTART = 8,
	VSTOP = 9,
	VSUSP = 10,
};

export def TCGETA: u64 = 0x8000;
export def TCSETA: u64 = (TCGETA + 1);
export def TCSETAF: u64 = (TCGETA + 2);
export def TCSETAW: u64 = (TCGETA + 3);
export def TCWAITEVENT: u64 = (TCGETA + 4);
export def TCSBRK: u64 = (TCGETA + 5);
export def TCFLSH: u64 = (TCGETA + 6);
export def TCXONC: u64 = (TCGETA + 7);
// TCQUERYCONNECTED			(TCGETA + 8)
export def TCGETBITS: u64 = (TCGETA + 9);
export def SETDIR: u64 = (TCGETA + 10);
export def TCSETRTS: u64 = (TCGETA + 11);
export def TIOCGWINSZ: u64 = (TCGETA + 12);
export def TIOCSWINSZ: u64 = (TCGETA + 13);
// TCVTIME				(TCGETA + 14)
export def TIOCGPGRP: u64 = (TCGETA + 15);
export def TIOCSPGRP: u64 = (TCGETA + 16);
export def TIOCSCTTY: u64 = (TCGETA + 17);
export def TIOCMGET: u64 = (TCGETA + 18);
export def TIOCMSET: u64 = (TCGETA + 19);
export def TIOCSBRK: u64 = (TCGETA + 20);
export def TIOCCBRK: u64 = (TCGETA + 21);
export def TIOCMBIS: u64 = (TCGETA + 22);
export def TIOCMBIC: u64 = (TCGETA + 23);
export def TIOCGSID: u64 = (TCGETA + 24);
export def TIOCOUTQ: u64 = (TCGETA + 25);
export def TIOCEXCL: u64 = (TCGETA + 26);
export def TIOCNXCL: u64 = (TCGETA + 27);

export def SIG_DFL: uintptr = 0;
export def SIG_IGN: uintptr = 1;
export def SIG_ERR: uintptr = -1: uintptr;

export def SIG_BLOCK: int = 1;
export def SIG_UNBLOCK: int = 2;
export def SIG_SETMASK: int = 3;

export def SA_NOCLDSTOP: int = 0x1;
export def SA_NOCLDWAIT: int = 0x2;
export def SA_RESETHAND: int = 0x4;
export def SA_NODEFER: int = 0x8;
export def SA_RESTART: int = 0x10;
export def SA_ONSTACK: int = 0x20;
export def SA_SIGINFO: int = 0x40;
export def SA_NOMASK: int = SA_NODEFER;
export def SA_STACK: int = SA_ONSTACK;
export def SA_ONESHOT: int = SA_RESETHAND;

export def SIGHUP: int = 1;
export def SIGINT: int = 2;
export def SIGQUIT: int = 3;
export def SIGILL: int = 4;
export def SIGCHLD: int = 5;
export def SIGABRT: int = 6;
export def SIGPIPE: int = 7;
export def SIGFPE: int = 8;
export def SIGKILL: int = 9;
export def SIGSTOP: int = 10;
export def SIGSEGV: int = 11;
export def SIGCONT: int = 12;
export def SIGTSTP: int = 13;
export def SIGALRM: int = 14;
export def SIGTERM: int = 15;
export def SIGTTIN: int = 16;
export def SIGTTOU: int = 17;
export def SIGUSR1: int = 18;
export def SIGUSR2: int = 19;
export def SIGWINCH: int = 20;
export def SIGKILLTHR: int = 21;
export def SIGTRAP: int = 22;
export def SIGPOLL: int = 23;
export def SIGPROF: int = 24;
export def SIGSYS: int = 25;
export def SIGURG: int = 26;
export def SIGVTALRM: int = 27;
export def SIGXCPU: int = 28;
export def SIGXFSZ: int = 29;
export def SIGBUS: int = 30;

export def PRIO_PROCESS: int = 0;
export def PRIO_PGRP: int = 1;
export def PRIO_USER: int = 2;

export def STDIN_FILENO: int = 0;
export def STDOUT_FILENO: int = 1;
export def STDERR_FILENO: int = 2;

export def SEEK_SET: int = 0;
export def SEEK_CUR: int = 1;
export def SEEK_END: int = 2;
export def SEEK_DATA: int = 3;
export def SEEK_HOLE: int = 4;

export def LOCK_SH: int = 1;
export def LOCK_EX: int = 2;
export def LOCK_NB: int = 4;
export def LOCK_UN: int = 8;

export type rlimit = struct {
	rlim_cur: rlim_t,
	rlim_max: rlim_t,
};

export def RLIM_INFINITY: rlim_t = -1;

export def RLIMIT_CORE: int = 0;
export def RLIMIT_CPU: int = 1;
export def RLIMIT_DATA: int = 2;
export def RLIMIT_FSIZE: int = 3;
export def RLIMIT_NOFILE: int = 4;
export def RLIMIT_STACK: int = 5;
export def RLIMIT_AS: int = 6;
export def RLIMIT_NOVMON: int = 7;
