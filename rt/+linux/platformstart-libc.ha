// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;

export fn start_linux(iv: *[*]uintptr) never = {
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*u8;
	envp = &argv[argc + 1]: *[*]nullable *u8;

	// Read auxv to determine if we need to sanitize file descriptors
	let i = 0z;
	for (envp[i] != null) i += 1;
	const auxv = &envp[i + 1]: *[*][2]uintptr;

	let secure = false;
	let uid: uintptr = 0, euid: uintptr = 0;
	let gid: uintptr = 0, egid: uintptr = 0;
	for (let j = 0z; auxv[j][0]: u64 != elf::at::NULL; j += 1) {
		switch (auxv[j][0]: u64) {
		case elf::at::SECURE => secure = auxv[j][1] != 0;
		case elf::at::UID    => uid = auxv[j][1];
		case elf::at::EUID   => euid = auxv[j][1];
		case elf::at::GID    => gid = auxv[j][1];
		case elf::at::EGID   => egid = auxv[j][1];
		case => void;
		};
	};

	if (secure || uid != euid || gid != egid) {
		sanitize_stdio();
	};

	start_ha();
};

// The standard library's stdin/stdout/stderr always refer to file descriptors
// 0, 1, and 2. If these have not been opened, subsequent file descriptors may
// take these FD numbers, causing I/O intended for stdin/stdout/stderr to use
// these files instead.
//
// If the process is setuid, this can cause the program to write garbage, leak
// information, or otherwise misbehave within the context of its elevated
// privileges. In case we have elevated permissions, ensure file descriptors 0-2
// are valid and replace them with /dev/null if not.
fn sanitize_stdio() void = {
	let pfds: [3]pollfd = [
		pollfd { fd = 0, ... },
		pollfd { fd = 1, ... },
		pollfd { fd = 2, ... },
	];

	const r = poll(&pfds: *[*]pollfd, 3, 0)!;
	for (let i = 0z; i < 3; i += 1) {
		if (pfds[i].revents & POLLNVAL != 0) {
			_ = open("/dev/null", O_RDWR, 0);
		};
	};
};
