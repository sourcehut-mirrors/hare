use fmt;

// Prints a simplified backtrace that does not rely on debug symbols.
export fn simple_backtrace(frame: stackframe) void = {
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

	static let seen: [MAX_FRAMES]uintptr = [0: uintptr...];
	let seen = seen[..0];

	for (let i = 0z; i < nframe; i += 1) {
		if (i < MAX_FRAMES_TOP || i > nframe - MAX_FRAMES_BOTTOM) {
			const pc = frame_pc(frame);
			_ = fmt::errorfln("(unknown) [0x{:x}]", pc);
		};
		if (i == MAX_FRAMES_TOP && nframe > MAX_FRAMES) {
			_ = fmt::errorfln("\t({} additional frames omitted)",
				nframe - MAX_FRAMES);
		};

		match (next(frame)) {
		case let next: stackframe =>
			frame = next;
		case done =>
			break;
		};
	};
};
