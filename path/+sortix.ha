// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Platform-specific path separator byte.
export def SEP: u8 = '/';

const sepstr: str = "/";

// Maximum length of a file path which can be stored in a [[path::buffer]].
//
// Note that the actual maximum length for absolute paths (if such a limit
// exists at all) is dependent on the filesystem implementation, and may not be
// a constant value.
export def MAX = rt::PATH_MAX - 1;
