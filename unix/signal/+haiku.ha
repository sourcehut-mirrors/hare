// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use sys;
use unix;

// Requests that [[sig::ALRM]] is delivered to the calling process in (about)
// "sec" seconds. Returns the number of seconds until the previously scheduled
// alarm, or zero if none was scheduled.
export fn alarm(sec: uint) uint = {
	return sys::alarm(sec): uint;
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
		sa_sigaction = handler: *fn(_: int, _: *sys::siginfo, _: *opaque) void,
		sa_mask = mask,
		sa_flags = flags,
		sa_userdata = null,
	};
	let old = sys::sigact { @undefined... };
	match (sys::sigaction(signum, &new, &old)) {
	case let err: sys::errno =>
		abort("sigaction failed (invalid signal?)");
	case void => void;
	};
	return old;

};

// Restores previous signal behavior following [[handle]].
export fn restore(signum: sig, action: *sigaction) void = {
	match (sys::sigaction(signum, action: *sys::sigact, null)) {
	case sys::errno =>
		abort("sigaction failed (invalid signal?)");
	case void => void;
	};

};

// Unregisters signal handlers for the specified signal.
export fn reset(signum: sig) void = {
	handle(signum, sys::SIG_DFL: *handler);
};

// Unregisters all signal handlers.
export fn resetall() void = {
	// sig::KILL, sig::STOP, sig::KILLTHR deliberately omitted; see sigaction(2)
	reset(sig::HUP);
	reset(sig::INT);
	reset(sig::QUIT);
	reset(sig::ILL);
	reset(sig::CHLD);
	reset(sig::ABRT);
	reset(sig::PIPE);
	reset(sig::FPE);
	reset(sig::SEGV);
	reset(sig::CONT);
	reset(sig::TSTP);
	reset(sig::ALRM);
	reset(sig::TERM);
	reset(sig::TTIN);
	reset(sig::TTOU);
	reset(sig::USR1);
	reset(sig::USR2);
	reset(sig::WINCH);
	reset(sig::TRAP);
	reset(sig::POLL);
	reset(sig::PROF);
	reset(sig::SYS);
	reset(sig::URG);
	reset(sig::VTALRM);
	reset(sig::XCPU);
	reset(sig::XFSZ);
	reset(sig::BUS);
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
	let old: sigset = 0;
	sys::sigprocmask(how, mask: *sys::sigset, &old)!;
	return old;
};

// Gets the current process's signal mask.
export fn getprocmask() sigset = {
	let old: sigset = 0;
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
	let set: sigset = 0;
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

// Provides additional information about signal deliveries. Only the members
// defined by POSIX are available here; cast to [[sys::siginfo]] to access
// non-portable members.
export type siginfo = struct {
	// The signal number being delivered.
	signo: sig,
	// The signal code, if any.
	code: code,
	// The errno, if any, associated with this signal. See
	// [[errors::errno]] to convert to a Hare-native error.
	errno: sys::errno,

	// Process ID of the sender.
	pid: unix::pid,
	// Real user ID of the sending process.
	uid: unix::uid,
	// Address of the faulting instruction
	addr: nullable *opaque,
	_: int,
	_: i64,
	_: sys::sigval,
};

export type code = enum int {
	USER = sys::SI_USER,		// user generated signal via kill()
	QUEUE = sys::SI_QUEUE,		// user generated signal via sigqueue()
	TIMER = sys::SI_TIMER,		// from timer expiration
	ASYNCIO = sys::SI_ASYNCIO,	// signal sent on async I/O completion
	MESGQ = sys::SI_MESGQ,		// arrival of message on empty queue

	ILLOPC = sys::ILL_ILLOPC,	// sig::ILL: illegal opcode
	ILLOPN = sys::ILL_ILLOPN,	// sig::ILL: illegal operand
	ILLADR = sys::ILL_ILLADR,	// sig::ILL: illegal addressing mode
	ILLTRP = sys::ILL_ILLTRP,	// sig::ILL: illegal trap
	PRVOPC = sys::ILL_PRVOPC,	// sig::ILL: privileged opcode
	PRVREG = sys::ILL_PRVREG,	// sig::ILL: privileged register
	COPROC = sys::ILL_COPROC,	// sig::ILL: co-processor
	BADSTK = sys::ILL_BADSTK,	// sig::ILL: bad stack

	INTDIV = sys::FPE_INTDIV,	// sig::FPE: integer divide by zero
	INTOVF = sys::FPE_INTOVF,	// sig::FPE: integer overflow
	FLTDIV = sys::FPE_FLTDIV,	// sig::FPE: floating point divide by zero
	FLTOVF = sys::FPE_FLTOVF,	// sig::FPE: floating point overflow
	FLTUND = sys::FPE_FLTUND,	// sig::FPE: floating point underflow
	FLTRES = sys::FPE_FLTRES,	// sig::FPE: floating point inexact result
	FLTINV = sys::FPE_FLTINV,	// sig::FPE: invalid floating point operation
	FLTSUB = sys::FPE_FLTSUB,	// sig::FPE: subscript out of range

	MAPERR = sys::SEGV_MAPERR,	// sig::SEGV: address not mapped to object
	ACCERR = sys::SEGV_ACCERR,	// sig::SEGV: invalid permissions

	ADRALN = sys::BUS_ADRALN,	// sig::BUS: invalid address alignment
	ADRERR = sys::BUS_ADRERR,	// sig::BUS: non-existent physical address
	OBJERR = sys::BUS_OBJERR,	// sig::BUS: object specific hardware error

	BRKPT = sys::TRAP_BRKPT,	// sig::TRAP: breakpoint trap
	TRACE = sys::TRAP_TRACE,	// sig::TRAP: trace trap

	EXITED = sys::CLD_EXITED,	// sig::CHLD: child has exited
	KILLED = sys::CLD_KILLED,	// sig::CHLD: child was killed
	DUMPED = sys::CLD_DUMPED,	// sig::CHLD: child has coredumped
	TRAPPED = sys::CLD_TRAPPED,	// sig::CHLD: traced child has stopped
	STOPPED = sys::CLD_STOPPED,	// sig::CHLD: child has stopped on signal
	CONTINUED = sys::CLD_CONTINUED,	// sig::CHLD: stopped child has continued

	POLL_IN = sys::POLL_IN,		// sig::POLL: input available
	POLL_OUT = sys::POLL_OUT,	// sig::POLL: output available
	POLL_MSG = sys::POLL_MSG,	// sig::POLL: input message available
	POLL_ERR = sys::POLL_ERR,	// sig::POLL: I/O error
	POLL_PRI = sys::POLL_PRI,	// sig::POLL: high priority input available
	POLL_HUP = sys::POLL_HUP,	// sig::POLL: device disconnected
};

export type flag = enum int {
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
	// Do not add the signal to the signal mask while executing the signal
	// handler. This can cause the same signal to be delivered again during
	// the execution of the signal handler.
	NODEFER = sys::SA_NODEFER,
	// Restore the signal handler to the default behavior upon entering the
	// signal handler.
	RESETHAND = sys::SA_RESETHAND,
	// Makes certain system calls restartable across signals. See signal(7)
	// or similar documentation for your local system for details.
	RESTART = sys::SA_RESTART,
};

// All possible signals.
export type sig = enum int {
	HUP = sys::SIGHUP, // Hangup.
	INT = sys::SIGINT, // Terminal interrupt.
	QUIT = sys::SIGQUIT, // Terminal quit.
	ILL = sys::SIGILL, // Illegal instruction.
	CHLD = sys::SIGCHLD, // Child process terminated, stopped, or continued.
	ABRT = sys::SIGABRT, // Process abort.
	PIPE = sys::SIGPIPE, // Write on a pipe with no one to read it.
	FPE = sys::SIGFPE, // Erroneous arithmetic operation.
	KILL = sys::SIGKILL, // Kill (cannot be caught or ignored).
	STOP = sys::SIGSTOP, // Stop executing (cannot be caught or ignored).
	SEGV = sys::SIGSEGV, // Invalid memory reference.
	CONT = sys::SIGCONT, // Continue executing, if stopped.
	TSTP = sys::SIGTSTP, // Terminal stop.
	ALRM = sys::SIGALRM, // Alarm clock.
	TERM = sys::SIGTERM, // Termination.
	TTIN = sys::SIGTTIN, // Background process attempting read.
	TTOU = sys::SIGTTOU, // Background process attempting write.
	USR1 = sys::SIGUSR1, // User-defined signal 1.
	USR2 = sys::SIGUSR2, // User-defined signal 2.
	WINCH = sys::SIGWINCH, // Window resize.
	KILLTHR = sys::SIGKILLTHR, // Be specific: kill just the thread, not the team
	TRAP = sys::SIGTRAP, // Trace/breakpoint trap.
	POLL = sys::SIGPOLL, // Pollable event
	PROF = sys::SIGPROF, // Profiling timer expired.
	SYS = sys::SIGSYS, // Bad system call.
	URG = sys::SIGURG, // High bandwidth data is available at a socket.
	VTALRM = sys::SIGVTALRM, // Virtual timer expired.
	XCPU = sys::SIGXCPU, // CPU time limit exceeded.
	XFSZ = sys::SIGXFSZ, // File size limit exceeded.
	BUS = sys::SIGBUS, // Access to an undefined portion of a memory object.
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
	case sig::CHLD =>
		return "SIGCHLD";
	case sig::ABRT =>
		return "SIGABRT";
	case sig::PIPE =>
		return "SIGPIPE";
	case sig::FPE =>
		return "SIGFPE";
	case sig::KILL =>
		return "SIGKILL";
	case sig::STOP =>
		return "SIGSTOP";
	case sig::SEGV =>
		return "SIGSEGV";
	case sig::CONT =>
		return "SIGCONT";
	case sig::TSTP =>
		return "SIGTSTP";
	case sig::ALRM =>
		return "SIGALRM";
	case sig::TERM =>
		return "SIGTERM";
	case sig::TTIN =>
		return "SIGTTIN";
	case sig::TTOU =>
		return "SIGTTOU";
	case sig::USR1 =>
		return "SIGUSR1";
	case sig::USR2 =>
		return "SIGUSR2";
	case sig::WINCH =>
		return "SIGWINCH";
	case sig::KILLTHR =>
		return "SIGKILLTHR";
	case sig::TRAP =>
		return "SIGTRAP";
	case sig::POLL =>
		return "SIGPOLL";
	case sig::PROF =>
		return "SIGPROF";
	case sig::SYS =>
		return "SIGSYS";
	case sig::URG =>
		return "SIGURG";
	case sig::VTALRM =>
		return "SIGVTALRM";
	case sig::XCPU =>
		return "SIGXCPU";
	case sig::XFSZ =>
		return "SIGXFSZ";
	case sig::BUS =>
		return "SIGBUS";
	};
};
