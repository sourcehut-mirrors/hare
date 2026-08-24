// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Integer type compatible with signed char, as specified by ISO/IEC 9899.
//
// This is an alias of i8 on all platforms.
export type schar = i8;

// Minimum value which can be stored in an [[schar]] type.
export def SCHAR_MIN: schar = types::I8_MIN;

// Maximum value which can be stored in an [[schar]] type.
export def SCHAR_MAX: schar = types::I8_MAX;

// Integer type compatible with unsigned char, as specified by ISO/IEC 9899.
//
// This is an alias of u8 on all platforms.
export type uchar = u8;

// Minimum value which can be stored in a [[uchar]] type.
export def UCHAR_MIN: uchar = types::U8_MIN;

// Maximum value which can be stored in a [[uchar]] type.
export def UCHAR_MAX: uchar = types::U8_MAX;

// Integer type compatible with char8_t, as defined in <uchar.h> and specified
// by ISO/IEC 9899.
//
// This is an alias of [[uchar]] (which aliases u8) on all platforms.
export type char8 = uchar;

// Minimum value which can be stored in a [[char8]] type.
export def CHAR8_MIN: char8 = UCHAR_MIN;

// Maximum value which can be stored in a [[char8]] type.
export def CHAR8_MAX: char8 = UCHAR_MAX;

// Integer type compatible with char16_t, as defined in <uchar.h> and specified
// by ISO/IEC 9899.
//
// This is an alias of u16 on all platforms.
export type char16 = u16;

// Minimum value which can be stored in a [[char16]] type.
export def CHAR16_MIN: char16 = types::U16_MIN;

// Maximum value which can be stored in a [[char16]] type.
export def CHAR16_MAX: char16 = types::U16_MAX;

// Integer type compatible with char32_t, as defined in <uchar.h> and specified
// by ISO/IEC 9899.
//
// This is an alias of u32 on all platforms.
export type char32 = u32;

// Minimum value which can be stored in a [[char32]] type.
export def CHAR32_MIN: char32 = types::U32_MAX;

// Maximum value which can be stored in a [[char32]] type.
export def CHAR32_MAX: char32 = types::U32_MAX;

// Integer type compatible with intmax_t, as defined in <stdint.h> and specified
// by ISO/IEC 9899.
//
// Note that this type isn't necessarily the actual maximum integer type. This
// type should only be used when required for C interop.
export type intmax = i64;

// Minimum value which can be stored in an [[intmax]] type.
export def INTMAX_MIN: intmax = types::I64_MIN;

// Maximum value which can be stored in an [[intmax]] type.
export def INTMAX_MAX: intmax = types::I64_MAX;

// Integer type compatible with uintmax_t, as defined in <stdint.h> and
// specified by ISO/IEC 9899.
//
// Note that this type isn't necessarily the actual maximum integer type. This
// type should only be used when required for C interop.
export type uintmax = u64;

// Minimum value which can be stored in a [[uintmax]] type.
export def UINTMAX_MIN: uintmax = types::U64_MIN;

// Maximum value which can be stored in a [[uintmax]] type.
export def UINTMAX_MAX: uintmax = types::U64_MAX;

// Integer type compatible with sig_atomic_t, as defined in <signal.h> and
// specified by ISO/IEC 9899.
export type sig_atomic = int;

// Minimum value which can be stored in a [[sig_atomic]] type.
export def SIG_ATOMIC_MIN: sig_atomic = types::INT_MIN;

// Maximum value which can be stored in a [[sig_atomic]] type.
export def SIG_ATOMIC_MAX: sig_atomic = types::INT_MAX;

// Integer type compatible with wchar_t, as defined in <stddef.h> and specified
// by ISO/IEC 9899.
export type wchar = i32;

// Minimum value which can be stored in a [[wchar]] type.
export def WCHAR_MIN: wchar = types::I32_MIN;

// Maximum value which can be stored in a [[wchar]] type.
export def WCHAR_MAX: wchar = types::I32_MAX;

// Integer type compatible with wint_t, as defined in <wchar.h> and specified
// by ISO/IEC 9899.
export type wint = u32;

// Minimum value which can be stored in a [[wint]] type.
export def WINT_MIN: wint = types::U32_MIN;

// Maximum value which can be stored in a [[wint]] type.
export def WINT_MAX: wint = types::U32_MAX;
