// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use sys;

export let argc: size = @undefined;
export let argv: *[*]*u8 = @undefined;
export let envp: *[*]nullable *u8 = @undefined;
export let auxv: *[*]elf::auxv64 = @undefined;

// Bootinfo structure from the auxillary vector, if present.
export let boot_info: nullable *sys::bootinfo = null;
