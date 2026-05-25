// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use proto::system;
use sys;

export fn start_hermes(iv: *[*]uintptr) never = {
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*u8;
	envp = &argv[argc + 1]: *[*]nullable *u8;

	let i = 0;
	for (envp[i] != null; i += 1) void;
	auxv = &envp[i+1]: *[*]elf::auxv64;

	for (let i = 0z; auxv[i].a_type != elf::at::NULL; i += 1) {
		const aux = &auxv[i];
		switch (aux.a_type) {
		case elf::at::BOOTINFO =>
			boot_info = aux.a_ptr: *sys::bootinfo;
		case elf::at::IPC_BUF =>
			sys::ipcbuf = aux.a_ptr: *[sys::PAGESIZE]u8;
		case elf::at::SERVICE =>
			const svc_id = (aux.a_val >> 32): u32;
			const addr = aux.a_val: u32;
			if (svc_id == system::PROCESS_ID) {
				process_svc = addr;
				set_allocator(&proc_allocator);
			};
		case => void;
		};
	};

	start_ha();
};
