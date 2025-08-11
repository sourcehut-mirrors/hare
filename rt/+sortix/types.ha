// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type off_t = i64;

// Maximum length of a file path including the NUL terminator.
//
// Note: Sortix does not define a maximum path length. This is a limitation of
// the Hare standard library.
export def PATH_MAX: size = 4096;

// Maximum length of a file name.
//
// Note: Sortix does not define a maximum filename length. This is a limitation
// of the Hare standard library.
export def NAME_MAX: size = 255;
