// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use arch;
use fmt;
use memio;
use os;
use shlex;
use strings;

let want_abort = false;

// Expect the currently running test to abort. The test will fail if it doesn't
// abort.
export fn expectabort() void = {
	assert(jmp != null, "Attempted to call test::expectabort outside of @test function");
	want_abort = true;
};

// Skip the currently running test, formatting the message like with
// [[fmt::fprint]].
export fn skip(why: fmt::formattable...) never = {
	assert(jmp != null, "Attempted to call test::skip outside of @test function");
	skipstr(fmt::asprint(why...)!);
};

// Skip the currently running test, formatting the message like with
// [[fmt::fprintf]].
export fn skipf(fmt: str, args: fmt::field...) never = {
	assert(jmp != null, "Attempted to call test::skipf outside of @test function");
	skipstr(fmt::asprintf(fmt, args...)!);
};

// Check the $HARETEST_INCLUDE space-delimited environment variable for
// keywords. If any of the keywords aren't present, the currently running test
// is skipped.
export fn require(keywords: str...) void = {
	assert(jmp != null, "Attempted to call test::require outside of @test function");
	if (len(keywords) == 0) {
		return;
	};
	let include = match (os::getenv("HARETEST_INCLUDE")) {
	case void => skip_require(keywords...);
	case let s: str =>
		yield s;
	};

	for :keywords (let keyword .. keywords) {
		let tokr = strings::tokenize(include, " ");
		for (let tok => strings::next_token(&tokr)) {
			if (tok == keyword) {
				continue :keywords;
			};
		};
		skip_require(keywords...);
	};
};

let _current: nullable *test = null;

// Returns the name of the currently running test.
export fn current() str = {
	match (_current) {
	case let t: *test =>
		return t.name;
	case null =>
		abort("Attempted to call test::current outside of @test function");
	};
};

fn skip_require(keywords: str...) never = {
	let keywords = strings::join(" ", keywords...)!;
	defer free(keywords);

	let s = memio::dynamic();
	memio::concat(&s, "Requires HARETEST_INCLUDE=")!;
	shlex::quote(&s, keywords)!;

	skipstr(memio::string(&s)!);
};

fn skipstr(why: str) never = {
	reason = abort_reason {
		msg = why,
		...
	};
	arch::longjmp(&jmp_buf, status::SKIP);
};
