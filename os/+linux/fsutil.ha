// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>
//
// Filesystem-related helper functions for common high-level operations.

use errors;
use path;

// Canonicalizes a path in this filesystem by resolving all symlinks and
// collapsing any "." or ".." path components. The return value is statically
// allocated and will be overwritten on subsequent calls.
export fn realpath(path: str) (str | errors::error) = {
	static let res = path::buffer { ... };
	path::set(&res)!;

	static let inbuf = path::buffer { ... };
	if (path::abs(path)) {
		path::set(&inbuf, path)!;
	} else {
		path::set(&inbuf, getcwd(), path)!;
	};

	const iter = path::iter(&inbuf);

	for (let item => path::nextiter(&iter)) {
		const item = path::push(&res, item)!;

		const link = match (readlink(item)) {
		case let link: str =>
			yield link;
		case errors::wrongtype =>
			continue;
		case let err: errors::error =>
			return err;
		};

		if (!path::abs(link)) {
			path::push(&res, "..", link)!;
		} else {
			path::set(&res, link)!;
		};
	};

	return path::string(&res);
};
