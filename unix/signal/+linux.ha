// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;
use time;
use unix;

// Requests that [[sig::ALRM]] is delivered to the calling process in (about)
// "sec" seconds. Returns the number of seconds until the previously scheduled
// alarm, or zero if none was scheduled.
export fn alarm(sec: uint) uint = {
	return sys::alarm(sec);
};

// Configures a new signal handler, returning the old details (which can be
// passed to [[restore]] to restore its behavior).
export fn handle(
	signum: sig,
	handler: *handler,
	flags: flag = flag::NONE,
	mask: nullable *sigset = null,
) sigaction = {
	flags |= sys::SA_SIGINFO: flag;
	let mask = match (mask) {
	case null =>
		yield newsigset();
	case let set: *sigset =>
		yield *set;
	};

	let new = sys::sigact {
		sa_sigaction = handler: *fn(_: int,
			_: *sys::siginfo, _: *opaque) void,
		sa_mask = mask,
		sa_flags = flags,
		// Filled in by rt
		sa_restorer = @undefined,
	};
	let old = sys::sigact { @undefined... };
	match (sys::sigaction(signum, &new, &old)) {
	case sys::errno =>
		abort("sigaction failed (invalid signal?)");
	case int => void;
	};
	return old;
};

// Restores previous signal behavior following [[handle]].
export fn restore(signum: sig, action: *sigaction) void = {
	match (sys::sigaction(signum, action: *sys::sigact, null)) {
	case sys::errno =>
		abort("sigaction failed (invalid signal?)");
	case int => void;
	};
};

// Unregisters signal handlers for the specified signal.
export fn reset(signum: sig) void = {
	handle(signum, sys::SIG_DFL: *handler);
};

// Unregisters all signal handlers.
export fn resetall() void = {
	// sig::KILL and sig::STOP deliberately omitted; see sigaction(2)
	reset(sig::HUP);
	reset(sig::INT);
	reset(sig::QUIT);
	reset(sig::ILL);
	reset(sig::TRAP);
	reset(sig::ABRT);
	reset(sig::BUS);
	reset(sig::FPE);
	reset(sig::USR1);
	reset(sig::SEGV);
	reset(sig::USR2);
	reset(sig::PIPE);
	reset(sig::ALRM);
	reset(sig::TERM);
	reset(sig::STKFLT);
	reset(sig::CHLD);
	reset(sig::CONT);
	reset(sig::TSTP);
	reset(sig::TTIN);
	reset(sig::TTOU);
	reset(sig::URG);
	reset(sig::XCPU);
	reset(sig::XFSZ);
	reset(sig::VTALRM);
	reset(sig::PROF);
	reset(sig::WINCH);
	reset(sig::POLL);
	reset(sig::PWR);
	reset(sig::SYS);
};

// Prevents given signal from arriving to the current process.
// One common use case is to ignore SIGCHLD to avoid zombie child processes.
export fn ignore(signum: sig) void = {
	handle(signum, sys::SIG_IGN: *handler);
};

// Adds the given list of signals to the process's current signal mask,
// returning the old signal mask. This is a convenience function around
// [[setprocmask]].
export fn block(signals: sig...) sigset = {
	let new = newsigset(signals...);
	return setprocmask(how::BLOCK, &new);
};

// Removes the given list of signals from the process's current signal mask,
// returning the old signal mask. This is a convenience function around
// [[setprocmask]].
export fn unblock(signals: sig...) sigset = {
	let new = newsigset(signals...);
	return setprocmask(how::UNBLOCK, &new);
};

// Sets the process's signal mask, returning the previous mask.
export fn setprocmask(how: how, mask: *sigset) sigset = {
	let old = sigset { ... };
	sys::sigprocmask(how, mask: *sys::sigset, &old)!;
	return old;
};

// Gets the current process's signal mask.
export fn getprocmask() sigset = {
	let old = sigset { ... };
	sys::sigprocmask(how::SETMASK, null, &old)!;
	return old;
};

// Defines the modes of operation for [[setprocmask]].
export type how = enum int {
	// Adds the given set of signals to the current mask.
	BLOCK = sys::SIG_BLOCK,
	// Removes the given set of signals from the current mask.
	UNBLOCK = sys::SIG_UNBLOCK,
	// Sets the process mask to the given set.
	SETMASK = sys::SIG_SETMASK,
};

export type sigaction = sys::sigact;

export type sigset = sys::sigset;

// Creates a new signal set filled in with the provided signals (or empty if
// none are provided).
export fn newsigset(items: sig...) sigset = {
	let set = sigset { ... };
	sys::sigemptyset(&set);
	sigset_add(&set, items...);
	return set;
};

// Sets a [[sigset]] to empty.
export fn sigset_empty(set: *sigset) void = {
	sys::sigemptyset(set: *sys::sigset);
};

// Adds signals to a [[sigset]].
export fn sigset_add(set: *sigset, items: sig...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		sys::sigaddset(set: *sys::sigset, items[i])!;
	};
};

// Removes signals from a [[sigset]].
export fn sigset_del(set: *sigset, items: sig...) void = {
	for (let i = 0z; i < len(items); i += 1) {
		sys::sigdelset(set: *sys::sigset, items[i])!;
	};
};

// Adds all platform-defined signals to a [[sigset]].
export fn sigset_fill(set: *sigset) void = {
	sys::sigfillset(set: *sys::sigset);
};

// Returns true if the given signal is a member of this [[sigset]].
export fn sigset_member(set: *sigset, item: sig) bool = {
	return sys::sigismember(set: *sys::sigset, item)!;
};

// Waits for a signal among the given [[sigset]] to be delivered, then returns
// the signal number.
//
// If a signal is received while waiting, [[errors::interrupted]] is returned.
// Most consumers of this function will likely wish to block all signals and
// handle them exclusively through [[wait]] et al, in which case this error
// cannot occur.
//
// See also [[waitinfo]] and [[timedwait]].
export fn wait(set: *sigset) (sig | errors::interrupted) = {
	let signal = 0i;
	match (sys::sigwait(set: *sys::sigset, &signal)) {
	case let err: sys::errno =>
		assert(err == sys::EINTR);
		return errors::interrupted;
	case void =>
		return signal: sig;
	};
};

// Waits for a signal among the given [[sigset]] to be delivered, then returns
// the corresponding [[siginfo]] data.
//
// See notes on [[wait]] regarding the [[errors::interrupted]] case.
//
// This function is designed to provide the portable subset of the semantics of
// sigwaitinfo(3) as defined by POSIX.1-2008. To access the complete siginfo_t
// structure provided by the underlying platform, use [[sys::sigwaitinfo]] and
// [[sys::siginfo_t]] directly.
//
// Note that this function is not supported on OpenBSD.
export fn waitinfo(set: *sigset) (siginfo | errors::interrupted) = {
	let info = sys::siginfo { ... };
	match (sys::sigwaitinfo(set: *sys::sigset, &info)) {
	case let err: sys::errno =>
		assert(err == sys::EINTR);
		return errors::interrupted;
	case int =>
		return *(&info: *siginfo);
	};
};

// Waits for a signal among the given [[sigset]] to be delivered, then returns
// the corresponding [[siginfo]] data.
//
// Returns a [[siginfo]] if a signal is successfully processed through this
// function, or [[errors::again]] if the timeout expired. See notes on [[wait]]
// regarding the [[errors::interrupted]] case.
//
// This function is designed to provide the portable subset of the semantics of
// sigtimedwait(3) as defined by POSIX.1-2008. To access the complete siginfo_t
// structure provided by the underlying platform, use [[sys::sigtimedwait]] and
// [[sys::siginfo_t]] directly.
//
// Note that this function is not supported on OpenBSD.
export fn timedwait(
	set: *sigset,
	timeout: time::duration,
) (siginfo | errors::interrupted | errors::again) = {
	let info = sys::siginfo { ... };
	let to = time::duration_to_timeval(timeout);
	match (sys::sigwaitinfo(set: *sys::sigset, &info)) {
	case let err: sys::errno =>
		switch (err) {
		case sys::EINTR =>
			return errors::interrupted;
		case sys::EAGAIN =>
			return errors::again;
		case => abort();
		};
	case int =>
		return *(&info: *siginfo);
	};
};

// Provides additional information about signal deliveries. Only the members
// defined by POSIX are available here; cast to [[sys::siginfo]] to access
// non-portable members.
export type siginfo = union {
	struct {
		// The signal number being delivered.
		signo: sig,
		// The errno, if any, associated with this signal. See
		// [[errors::errno]] to convert to a Hare-native error.
		errno: sys::errno,
		// The signal code, if any.
		code: code,

		union {
			struct {
				// Process ID of the sender.
				pid: unix::pid,
				// Real user ID of the sending process.
				uid: unix::uid,
				// Exit value or signal.
				status: int,
			},
			struct {
				// Address of the faulting instruction.
				addr: *opaque,
			},
		},
	},
	_: [128 - 3 * size(int)]u8, // padding
};

// A code indicating why a signal was sent.
export type code = enum int {
	USER = 0, // sent by userspace program (kill)
	KERNEL = 128, // sent by kernel
	QUEUE = -1, // sent by sigqueue
	TIMER = -2, // generated by expiration of a timer
	MESQ = -3, // generated by arrival of a message on an empty queue
	ASYNCIO = -4, // generated by completion of an asynchronous I/O request
	SIGIO = -5,
	TKILL = -6, // sent by userspace program (tkill, tgkill)
	ASYNCNL = -60,

	ILLOPC = 1, // sig::ILL: illegal opcode
	ILLOPN = 2, // sig::ILL: illegal operand
	ILLADR = 3, // sig::ILL: illegal addressing mode
	ILLTRP = 4, // sig::ILL: illegal trap
	PRVOPC = 5, // sig::ILL: privileged opcode
	PRVREG = 6, // sig::ILL: privileged register
	COPROC = 7, // sig::ILL: coprocessor error
	BADSTK = 8, // sig::ILL: internal stack error

	INTDIV = 1, // sig::FPE: integer divide by zero
	INTOVF = 2, // sig::FPE: integer overflow
	FLTDIV = 3, // sig::FPE: floating-point divide by zero
	FLTOVF = 4, // sig::FPE: floating-point overflow
	FLTUND = 5, // sig::FPE: floating-point underflow
	FLTRES = 6, // sig::FPE: floating-point inexact result
	FLTINV = 7, // sig::FPE: invalid floating-point operation
	FLTSUB = 8, // sig::FPE: subscript out of range

	MAPERR = 1, // sig::SEGV: address not mapped to object
	ACCERR = 2, // sig::SEGV: invalid permissions for mapped object
	BNDERR = 3, // sig::SEGV: failed address bound checks
	PKUERR = 4, // sig::SEGV: access was denied by memory protection keys
	MTEAERR = 8, // sig::SEGV
	MTESERR = 9, // sig::SEGV

	ADRALN = 1, // sig::BUS: invalid address alignment
	ADRERR = 2, // sig::BUS: nonexistent physical address
	OBJERR = 3, // sig::BUS: object-specific hardware error
	MCEERR_AR = 4, // sig::BUS: hardware memory error consumed on a machine check; action required
	MCEERR_AO = 5, // sig::BUS: hardware memory error detected in process but not consumed; action optional

	BRKPT = 1, // sig::TRAP: process breakpoint
	TRACE = 2, // sig::TRAP: process trace trap
	BRANCH = 3, // sig::TRAP: process taken branch trap
	HWBKPT = 4, // sig::TRAP: hardware breakpoint/watchpoint
	UNK = 5, // sig::TRAP

	EXITED = 1, // sig::CHLD: child exited
	KILLED = 2, // sig::CHLD: child terminated abnormally without a core file
	DUMPED = 3, // sig::CHLD: child terminated abnormally with a core file
	TRAPPED = 4, // sig::CHLD: traced child has trapped
	STOPPED = 5, // sig::CHLD: child has stopped
	CONTINUED = 6, // sig::CHLD: stopped child has continued

	IN = 1, // sig::POLL: data input available
	OUT = 2, // sig::POLL: output buffers available
	MSG = 3, // sig::POLL: input message available
	ERR = 4, // sig::POLL: I/O error
	PRI = 5, // sig::POLL: high priority input available
	HUP = 6, // sig::POLL: device disconnected
};

// Flags used to configure the behavior of a signal handler.
export type flag = enum u64 {
	NONE = 0,
	// For use with sig::CHLD. Prevents notifications when child processes
	// stop (e.g. via sig::STOP) or resume (i.e. sig::CONT).
	NOCLDSTOP = sys::SA_NOCLDSTOP,
	// For use with sig::CHLD. Do not transform children into zombies when
	// they terminate. Note that POSIX leaves the delivery of sig::CHLD
	// unspecified when this flag is present; some systems will still
	// deliver a signal and others may not.
	NOCLDWAIT = sys::SA_NOCLDWAIT,
	// Uses an alternate stack when handling this signal. See
	// [[setaltstack]] and [[getaltstack]] for details.
	ONSTACK = sys::SA_ONSTACK,
	// Makes certain system calls restartable across signals. See signal(7)
	// or similar documentation for your local system for details.
	RESTART = sys::SA_RESTART,
	// Do not add the signal to the signal mask while executing the signal
	// handler. This can cause the same signal to be delivered again during
	// the execution of the signal handler.
	NODEFER = sys::SA_NODEFER,
	// Restore the signal handler to the default behavior upon entering the
	// signal handler.
	RESETHAND = sys::SA_RESETHAND,
};

// All possible signals.
export type sig = enum int {
	HUP = sys::SIGHUP, // Hangup.
	INT = sys::SIGINT, // Terminal interrupt.
	QUIT = sys::SIGQUIT, // Terminal quit.
	ILL = sys::SIGILL, // Illegal instruction.
	TRAP = sys::SIGTRAP, // Trace/breakpoint trap.
	ABRT = sys::SIGABRT, // Process abort.
	BUS = sys::SIGBUS, // Access to an undefined portion of a memory object.
	FPE = sys::SIGFPE, // Erroneous arithmetic operation.
	KILL = sys::SIGKILL, // Kill (cannot be caught or ignored).
	USR1 = sys::SIGUSR1, // User-defined signal 1.
	SEGV = sys::SIGSEGV, // Invalid memory reference.
	USR2 = sys::SIGUSR2, // User-defined signal 2.
	PIPE = sys::SIGPIPE, // Write on a pipe with no one to read it.
	ALRM = sys::SIGALRM, // Alarm clock.
	TERM = sys::SIGTERM, // Termination.
	STKFLT = sys::SIGSTKFLT, // Stack fault.
	CHLD = sys::SIGCHLD, // Child process terminated, stopped, or continued.
	CONT = sys::SIGCONT, // Continue executing if stopped.
	STOP = sys::SIGSTOP, // Stop executing (cannot be caught or ignored).
	TSTP = sys::SIGTSTP, // Terminal stop.
	TTIN = sys::SIGTTIN, // Background process attempting read.
	TTOU = sys::SIGTTOU, // Background process attempting write.
	URG = sys::SIGURG, // High bandwidth data is available at a socket.
	XCPU = sys::SIGXCPU, // CPU time limit exceeded.
	XFSZ = sys::SIGXFSZ, // File size limit exceeded.
	VTALRM = sys::SIGVTALRM, // Virtual timer expired.
	PROF = sys::SIGPROF, // Profiling timer expired.
	WINCH = sys::SIGWINCH, // Window resize signal.
	IO = sys::SIGIO, // I/O now possible (synonymous with sig::POLL).
	POLL = sys::SIGPOLL, // Pollable event.
	PWR = sys::SIGPWR, // Power failure.
	SYS = sys::SIGSYS, // Bad system call.
};

// Creates a signal file that handles the given set of signals.
export fn signalfd(signals: sig...) (io::file | errors::error) = {
	let sa_mask = newsigset(signals...);
	match (sys::signalfd(-1, &sa_mask, sys::SFD_CLOEXEC)) {
	case let fd: int =>
		return fd;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Updates a signalfd with a new set of signals. The signal set is overwritten,
// rather than appended to, with the provided set of signals.
export fn update(fd: io::file, signals: sig...) (void | errors::error) = {
	let sa_mask = newsigset(signals...);

	match (sys::signalfd(fd, &sa_mask, sys::SFD_CLOEXEC)) {
	case int =>
		return;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Reads pending signal info from a signalfd.
export fn read(fd: io::file) (siginfo | errors::error) = {
	let si = sys::signalfd_siginfo { ... };
	match (sys::read(fd, &si, size(sys::signalfd_siginfo))) {
	case let err: sys::errno =>
		return errors::errno(err);
	case let z: size =>
		assert(z == size(sys::signalfd_siginfo));
	};
	return siginfo {
		signo = si.ssi_signo: sig,
		errno = si.ssi_errno: sys::errno,
		code = si.ssi_code: code,
		...
	};
};

// Returns the human friendly name of a given signal.
export fn signame(sig: sig) const str = {
	switch (sig) {
	case sig::HUP =>
		return "SIGHUP";
	case sig::INT =>
		return "SIGINT";
	case sig::QUIT =>
		return "SIGQUIT";
	case sig::ILL =>
		return "SIGILL";
	case sig::TRAP =>
		return "SIGTRAP";
	case sig::ABRT =>
		return "SIGABRT";
	case sig::BUS =>
		return "SIGBUS";
	case sig::FPE =>
		return "SIGFPE";
	case sig::KILL =>
		return "SIGKILL";
	case sig::USR1 =>
		return "SIGUSR1";
	case sig::SEGV =>
		return "SIGSEGV";
	case sig::USR2 =>
		return "SIGUSR2";
	case sig::PIPE =>
		return "SIGPIPE";
	case sig::ALRM =>
		return "SIGALRM";
	case sig::TERM =>
		return "SIGTERM";
	case sig::STKFLT =>
		return "SIGSTKFLT";
	case sig::CHLD =>
		return "SIGCHLD";
	case sig::CONT =>
		return "SIGCONT";
	case sig::STOP =>
		return "SIGSTOP";
	case sig::TSTP =>
		return "SIGTSTP";
	case sig::TTIN =>
		return "SIGTTIN";
	case sig::TTOU =>
		return "SIGTTOU";
	case sig::URG =>
		return "SIGURG";
	case sig::XCPU =>
		return "SIGXCPU";
	case sig::XFSZ =>
		return "SIGXFSZ";
	case sig::VTALRM =>
		return "SIGVTALRM";
	case sig::PROF =>
		return "SIGPROF";
	case sig::WINCH =>
		return "SIGWINCH";
	case sig::POLL =>
		return "SIGPOLL";
	case sig::PWR =>
		return "SIGPWR";
	case sig::SYS =>
		return "SIGSYS";
	};
};
