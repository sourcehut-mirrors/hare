// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Synthetic directory file descriptor representing the current working
// directory for all [[*at]] operations.
export def AT_FDCWD: int = rt::AT_FDCWD;

// When used with [[*at]] operations, if the path refers to a symbolic link, do
// not follow it (such that [[fstatat]] behaves like [[lstat]] if this flag is
// provided).
export def AT_SYMLINK_NOFOLLOW: int = rt::AT_SYMLINK_NOFOLLOW;

// When used with [[unlinkat]], causes directory entries to be removed as in
// [[rmdir]] (otherwise [[unlinkat]] behaves similarly to [[unlink]]).
export def AT_REMOVEDIR: int = rt::AT_REMOVEDIR;

// When used with the [[*at]] family of functions (namely [[fstatat]]), this
// flag causes the directory file descriptor to be the object of the operation
// and the path argument is ignored.
export def AT_EMPTY_PATH: int = rt::AT_EMPTY_PATH;
