// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fs;
use io;
use path;
use time;

// Provides an implementation of [[fs::fs]] for the current working directory.
export let cwd: *fs::fs = null: *fs::fs;

// Creates a directory.
export fn mkdir(path: str, mode: io::mode) (void | fs::error) = fs::mkdir(cwd, path, mode);

// Creates a directory, and all non-extant directories in its path.
export fn mkdirs(path: str, mode: io::mode) (void | fs::error) = fs::mkdirs(cwd, path, mode);
