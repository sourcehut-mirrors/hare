// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use rt;
use errors;

export type termios = struct {
	file: io::file,
	saved: rt::termios,
	current: rt::termios,
};

// Retrieves serial port settings of the given terminal.
export fn termios_query(file: io::file) (termios | errors::error) = {
	let settings = rt::termios { ... };

	match (rt::tcgetattr(file, &settings)) {
	case int => void;
	case let err: rt::errno =>
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
	rt::tcsetattr(termios.file, rt::TCSAFLUSH, &termios.saved)!;
};

// Sets serial port settings.
export fn termios_set(termios: *const termios) (void | errors::error) = {
	match (rt::tcsetattr(termios.file, rt::TCSAFLUSH, &termios.current)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case void => void;
	};
};

// Enables "raw" mode for this terminal, disabling echoing, line
// editing, and signal handling. Users should call [[termios_query]]
// prior to this to save the previous terminal settings, and
// [[termios_restore]] to restore them before exiting.
export fn makeraw(termios: *termios) (void | errors::error) = {
	// Disable break signal and CR<->LF processing
	termios.current.c_iflag &= ~(rt::IGNBRK | rt::BRKINT
		| rt::INLCR | rt::IGNCR | rt::ICRNL);
	// Disable output post-processing
	termios.current.c_oflag &= ~rt::OPOST;
	// Disable character echo, canonical mode, implementation defined
	// extensions and INTR/QUIT/SUSP characters
	termios.current.c_lflag &= ~(rt::ECHO | rt::ECHONL
		| rt::ICANON | rt::IEXTEN | rt::ISIG);

	termios_set(termios)?;
};

// Disables "echo" on this terminal. Users should call [[termios_restore]] to
// restore settings.
export fn noecho(termios: *termios) (void | errors::error) = {
	termios.current.c_lflag &= ~rt::ECHO;
	termios_set(termios)?;
};
