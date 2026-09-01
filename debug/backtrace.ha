// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use debug::dwarf;
use debug::image;
use fmt;
use format::elf;
use fs;
use io;
use os;

def MAX_FRAMES_TOP: size = 16z;
def MAX_FRAMES_BOTTOM: size = 16z;
def MAX_FRAMES: size = MAX_FRAMES_TOP + MAX_FRAMES_BOTTOM;

// Prints a backtrace to the provided [[io::handle]].
export fn backtrace(
	self: *image::image,
	out: io::handle,
	frame: stackframe,
) (size | io::error) = {
	let orig = frame;
	let nframe = 1z;
	for (true; nframe += 1) {
		match (next(frame)) {
		case let next: stackframe =>
			frame = next;
		case done => break;
		};
	};
	frame = orig;

	const st = match (os::fstat(self.fd)) {
	case let st: fs::filestat =>
		yield st;
	case fs::error =>
		yield fs::filestat { mask = 0, ... };
	};

	static let seen: [MAX_FRAMES]uintptr = [0: uintptr...];
	let seen = seen[..0];

	let z = 0z;
	for (let i = 0z; i < nframe; i += 1) {
		if (i < MAX_FRAMES_TOP || i > nframe - MAX_FRAMES_BOTTOM) {
			z += printframe(self, out, &seen, &st, frame)?;
		};
		if (i == MAX_FRAMES_TOP && nframe > MAX_FRAMES) {
			z += fmt::fprintfln(out,
				"\t({} additional frames omitted)",
				nframe - MAX_FRAMES)?;
		};

		match (next(frame)) {
		case let next: stackframe =>
			frame = next;
		case done =>
			break;
		};
	};

	return z;
};

fn printframe(
	self: *image::image,
	out: io::handle,
	seen: *[]uintptr,
	imgstat: *fs::filestat,
	frame: stackframe,
) (size | io::error) = {
	const pc = frame_pc(frame);

	// Try to translate the address
	match (translate(pc: uintptr)) {
	case let ptr: uintptr =>
		pc = ptr;
	case =>
		void;
	};

	let z = 0z;
	const sym = match (symbol_byaddr(self, pc)) {
	case let sym: elf::sym64 =>
		yield sym;
	case =>
		z += fmt::fprintfln(out, "(unknown) [0x{:x}]", pc)?;
		return z;
	};
	const name = match (symbol_name(self, &sym)) {
	case let name: const str =>
		yield name;
	case =>
		z += fmt::fprintfln(out, "(unknown) [0x{:x}]", pc)?;
		return z;
	};

	// Look for DWARF line numbers, if possible
	const (path, line, col) = match (dwarf::addr_to_line(self, pc)) {
	case (void | io::error) =>
		// No line number available, print what we've got
		z += fmt::fprintfln(out, "{}+0x{:x} [0x{:x}]",
			symname_to_ident(name), pc - sym.st_value: uintptr, pc)?;
		return z;
	case let tuple: (const str, uint, uint) =>
		yield tuple;
	};

	z += fmt::fprintf(out, "{}:{}:{} {}+0x{:x} [0x{:x}]",
		path, line, col, symname_to_ident(name),
		pc - sym.st_value: uintptr, pc)?;

	// Skip context on frames we've already printed
	for (let i = 0z; i < len(seen); i += 1) {
		if (seen[i] == pc) {
			z += fmt::fprintln(out, " (already shown)")?;
			return z;
		};
	};
	static append(seen, pc)!;
	z += fmt::fprintln(out)?;

	z += print_context(out, path, line, col, imgstat.mtime)?;
	return z;
};
