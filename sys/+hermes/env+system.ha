// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// This file is a temporary hack to allow Artemis' /boot/system to use
// thread-local storage before threads are supported in any other process.

// Address of IPC buffer, if configured.
export @threadlocal let ipcbuf: nullable *[PAGESIZE]u8 = null;
