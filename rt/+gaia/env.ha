// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;

export let argc: size = 0;
export let argv: *[*]*u8 = null: *[*]*u8;
export let envp: *[*]nullable *u8 = null: *[*]nullable *u8;
export let auxv: *[*]elf::auxv64 = null: *[*]elf::auxv64;

// The current task's cspace.
export let cspace: cap = ~0;

// The current task's vspace.
export let vspace: cap = ~0;

// The current process.
export let self: cap = ~0;

// Initial current working directory.
export let init_cwd: str = "/";

// Clock tick rate via auxv.
export let clktck: u64 = 0;
