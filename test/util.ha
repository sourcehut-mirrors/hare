// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;

// Returns the name of the currently running test.
export fn current() str = {
	abort("Attempted to call test::current outside of @test function");
};

// Expect the currently running test to abort. The test will fail if it doesn't
// abort.
export fn expectabort() void = {
	abort("Attempted to call test::expectabort outside of @test function");
};

// Skip the currently running test, formatting the message like with
// [[fmt::fprint]].
export fn skip(why: fmt::formattable...) never = {
	abort("Attempted to call test::skip outside of @test function");
};

// Skip the currently running test, formatting the message like with
// [[fmt::fprintf]].
export fn skipf(fmt: str, args: fmt::field...) never = {
	abort("Attempted to call test::skipf outside of @test function");
};

// Check the $HARETEST_INCLUDE space-delimited environment variable for
// keywords. If any of the keywords aren't present, the currently running test
// is skipped.
export fn require(keywords: str...) void = {
	abort("Attempted to call test::require outside of @test function");
};
