export def SIGHUP = 1;
export def SIGINT = 2;
export def SIGQUIT = 3;
export def SIGILL = 4;
export def SIGTRAP = 5;
export def SIGABRT = 6;
export def SIGBUS = 7;
export def SIGFPE = 8;
export def SIGKILL = 9;
export def SIGUSR1 = 10;
export def SIGSEGV = 11;
export def SIGUSR2 = 12;
export def SIGPIPE = 13;
export def SIGALRM = 14;
export def SIGTERM = 15;
export def SIGSYS = 16;
export def SIGCHLD = 17;
export def SIGCONT = 18;
export def SIGSTOP = 19;
export def SIGTSTP = 20;
export def SIGTTIN = 21;
export def SIGTTOU = 22;
export def SIGURG = 23;
export def SIGXCPU = 24;
export def SIGXFSZ = 25;
export def SIGVTALRM = 26;
export def SIGPWR = 27;
export def SIGWINCH = 28;
export def SIGRTMIN = 64;
export def SIGRTMAX = 12;

export def SIG_ERR = -1;
export def SIG_DFL = 0;
export def SIG_IGN = 1;

export def __SIGSET_NUM_SIGNALS = 128;

export type sigset = struct {
	__val: [__SIGSET_NUM_SIGNALS / (8 * size(u64))]u64,
};

export def SA_NOCLDSTOP = 1<<0;
export def SA_ONSTACK = 1<<1;
export def SA_RESETHAND = 1<<2;
export def SA_RESTART = 1<<3;
export def SA_SIGINFO = 1<<4;
export def SA_NOCLDWAIT = 1<<5;
export def SA_NODEFER = 1<<6;
export def SA_COOKIE = 1<<7;

export type sigact = struct {
	mask: sigset,
	union {
		sa_handler: nullable *fn (_: int) void,
		sa_sigaction: nullable *fn (_: int, _: *siginfo, _: *opaque) void,
		sa_sigaction_cookie: nullable *fn (_: int, _: *siginfo, _: *opaque) void,
	},
	sa_cookie: nullable *opaque,
	sa_flags: int,
};

export type siginfo = struct {
	si_value: sigval,
	si_addr: *opaque,
	si_pid: pid_t,
	si_uid: uid_t,
	si_signo: int,
	si_code: int,
	si_errno: int,
	si_status: int,
};

export type sigval = union {
	sival_int: int,
	sival_ptr: nullable *opaque,
};

// XXX: The Sortix header says "Decide appropriate values for these constants"
// So, keep an eye out
export def ILL_ILLOPC = 1;
export def ILL_ILLOPN = 2;
export def ILL_ILLADR = 3;
export def ILL_ILLTRP = 4;
export def ILL_PRVOPC = 5;
export def ILL_PRVREG = 6;
export def ILL_COPROC = 7;
export def ILL_BADSTK = 8;
export def FPE_INTDIV = 9;
export def FPE_INTOVF = 10;
export def FPE_FLTDIV = 11;
export def FPE_FLTOVF = 12;
export def FPE_FLTUND = 13;
export def FPE_FLTRES = 14;
export def FPE_FLTINV = 15;
export def FPE_FLTSUB = 16;
export def SEGV_MAPERR = 17;
export def SEGV_ACCERR = 18;
export def BUS_ADRALN = 19;
export def BUS_ADRERR = 20;
export def BUS_OBJERR = 21;
export def TRAP_BRKPT = 22;
export def TRAP_TRACE = 23;
export def CLD_EXITED = 24;
export def CLD_KILLED = 25;
export def CLD_DUMPED = 26;
export def CLD_TRAPPED = 27;
export def CLD_STOPPED = 29;
export def CLD_CONTINUED = 30;
export def SI_USER = 31;
export def SI_QUEUE = 32;
export def SI_TIMER = 33;
export def SI_ASYNCIO = 34;
export def SI_MSGQ = 35;

export def SS_ONSTACK = (1<<0);
export def SS_DISABLE = (1<<1);

export type stack_t = struct {
	ss_sp: *opaque,
	ss_size: size,
	ss_flags: int,
};
