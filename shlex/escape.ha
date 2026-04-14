// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use io;
use memio;
use strings;

fn is_safe(s: str) bool = {
	const iter = strings::iter(s);
	for (let rn => strings::next(&iter)) {
		switch (rn) {
		case '@', '%', '+', '=', ':', ',', '.', '/', '-' => void;
		case =>
			// XXX: what about non-ascii characters?
			if (!ascii::isalnum(rn)) {
				return false;
			};
		};
	};
	return true;
};

// Quotes a shell string and writes it to the provided I/O handle.
export fn quote(sink: io::handle, s: str) (size | io::error) = {
	if (len(s) == 0) {
		return memio::concat(sink, `''`);
	};
	if (is_safe(s)) {
		return memio::concat(sink, s);
	};

	let z = memio::appendrune(sink, '\'')?;

	const iter = strings::iter(s);
	for (let rn => strings::next(&iter)) {
		if (rn == '\'') {
			z += memio::concat(sink, `'"'"'`)?;
		} else {
			z += memio::appendrune(sink, rn)?;
		};
	};

	z += memio::appendrune(sink, '\'')?;
	return z;
};

// Quotes a shell string and returns a new string. The caller must free the
// return value.
export fn quotestr(s: str) str = {
	const sink = memio::dynamic();
	quote(&sink, s)!;
	return memio::string(&sink)!;
};
