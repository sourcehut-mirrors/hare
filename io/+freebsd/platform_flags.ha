// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Flags to use for opening a file. Not all operating systems support all flags;
// at a minimum, RDONLY, WRONLY, RDWR, CREATE, and TRUNC will be supported.
// Note that NOCTTY and CLOEXEC are on by default, and the CTTY/NOCLOEXEC flags
// respectively disable them.
export type flag = enum int {
	RDONLY		= rt::O_RDONLY,
	WRONLY		= rt::O_WRONLY,
	RDWR		= rt::O_RDWR,
	CREATE		= rt::O_CREAT,
	EXCL		= rt::O_EXCL,
	CTTY		= rt::O_NOCTTY,
	TRUNC		= rt::O_TRUNC,
	APPEND		= rt::O_APPEND,
	NONBLOCK	= rt::O_NONBLOCK,
	DSYNC		= rt::O_DSYNC,
	SYNC		= rt::O_SYNC,
	RSYNC		= rt::O_SYNC,
	DIRECTORY	= rt::O_DIRECTORY,
	NOFOLLOW	= rt::O_NOFOLLOW,
	NOCLOEXEC	= rt::O_CLOEXEC,
};
