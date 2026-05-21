// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Address of IPC buffer, if configured.
export let ipcbuf: nullable *[PAGESIZE]u8 = null;
