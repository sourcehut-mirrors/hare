// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use format::elf::{at};
use rt::ipc;
use rt::sys;

export fn start_gaia(iv: *[*]uintptr) never = {
	argc = iv[0]: size;
	argv = &iv[1]: *[*]*u8;
	envp = &argv[argc + 1]: *[*]nullable *u8;

	let i = 0z;
	for (envp[i] != null) {
		i += 1;
	};
	auxv = &envp[i + 1]: *[*]elf::auxv64;

	for (let i = 0z; auxv[i].a_type != at::NULL; i += 1) {
		switch (auxv[i].a_type) {
		case at::IPCBUF =>
			ipc::ipcbuf = auxv[i].a_ptr: *ipc::ipc_buffer;
		case at::TLS_BASE =>
			yield; // TODO
		case at::TLS_SIZE =>
			yield; // TODO
		case at::CAP_IFACE =>
			const iface = auxv[i].a_val: u32;
			switch (iface) {
			case sys::PROCESS_ID =>
				assert(auxv[i+1].a_type == at::CAP_ENDPOINT);
				self = auxv[i+1].a_val: cap;
				i += 1;
			case => yield;
			};
		case at::IO_POOL =>
			iopool_init(auxv[i].a_ptr: *iopool_aux);
		case at::CLKTCK =>
			clktck = auxv[i].a_val;
		case =>
			yield;
		};
	};

	start_ha();
};
