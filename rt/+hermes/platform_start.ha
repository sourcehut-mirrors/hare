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

	let ipcbuf: uintptr = 0;
	let tls_master: uintptr = 0;
	let tls_size = 0z;

	for (let i = 0z; auxv[i].a_type != elf::at::NULL; i += 1) {
		const aux = &auxv[i];
		switch (aux.a_type) {
		case elf::at::BOOTINFO =>
			boot_info = aux.a_ptr: *sys::bootinfo;
		case elf::at::IPC_BUF =>
			ipcbuf = aux.a_ptr: uintptr;
		case elf::at::TLS_MASTER =>
			tls_master = aux.a_ptr: uintptr;
		case elf::at::TLS_SIZE =>
			tls_size = aux.a_val: size;
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

	if (tls_size != 0) {
		assert(process_svc != ~0,
			"Cannot initialize TLS without process service");
		init_tls(tls_master, tls_size);
	};

	if (ipcbuf != 0) {
		sys::ipcbuf = ipcbuf: *[sys::PAGESIZE]u8;
	};

	start_ha();
};

type thread_state = struct {
	self: *thread_state,
};

fn init_tls(tls_master: uintptr, tls_size: size) void = {
	// TODO: Maybe for the initial thread, this belongs in boot/system
	if (tls_size % align(thread_state) != 0) {
		tls_size += align(thread_state) -
			tls_size % align(thread_state);
	};

	let sz = size(thread_state) + tls_size;
	let data: []u8 = alloc([0...], sz)!;
	const master = (tls_master: *[*]u8)[..tls_size];
	data[..tls_size] = master[..];

	let thread = &data[tls_size]: *thread_state;
	thread.self = thread;

	system::process_set_tls_base(process_svc, 0, thread: uintptr);
};
