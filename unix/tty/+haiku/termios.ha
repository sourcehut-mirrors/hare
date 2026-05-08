// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// TODO: Not in love with this interface
use io;
use sys;
use errors;

export type termios = struct {
	file: io::file,
	saved: sys::termios,
	current: sys::termios,
};

// Retrieves serial port settings of the given terminal.
export fn termios_query(file: io::file) (termios | errors::error) = {
	let settings = sys::termios { ... };
	match (sys::tcgetattr(file, &settings)) {
	case void => void;
	case let err: sys::errno =>
		return errors::errno(err);
	};

	return termios {
		file = file,
		saved = settings,
		current = settings,
	};
};

// Restores original serial port settings.
export fn termios_restore(termios: *const termios) void = {
	_ = sys::tcsetattr(termios.file, 0, &termios.saved);
};

// Sets serial port settings.
export fn termios_set(termios: *const termios) (void | errors::error) = {
	match (sys::tcsetattr(termios.file, 0, &termios.current)) {
	case int => void;
	case let err: sys::errno =>
		return errors::errno(err);
	};
};

// Enables "raw" mode for this terminal, disabling echoing, line
// editing, and signal handling. Users should call [[termios_query]]
// prior to this to save the previous terminal settings, and
// [[termios_restore]] to restore them before exiting.
export fn makeraw(termios: *termios) (void | errors::error) = {
	// Disable break signal and CR<->LF processing
	termios.current.c_iflag &= ~(sys::tcflag::IGNBRK | sys::tcflag::BRKINT
		| sys::tcflag::INLCR | sys::tcflag::IGNCR
		| sys::tcflag::ICRNL);
	// Disable output post-processing
	termios.current.c_oflag &= ~sys::tcflag::OPOST;
	// Disable character echo, canonical mode, implementation defined
	// extensions and INTR/QUIT/SUSP characters
	termios.current.c_lflag &= ~(sys::tcflag::ECHO | sys::tcflag::ECHONL
		| sys::tcflag::ICANON | sys::tcflag::IEXTEN
		| sys::tcflag::ISIG);

	termios_set(termios)?;
};

// Disables "echo" on this terminal. Users should call [[termios_restore]] to
// restore settings.
export fn noecho(termios: *termios) (void | errors::error) = {
	termios.current.c_lflag &= ~sys::tcflag::ECHO;
	termios_set(termios)?;
};
