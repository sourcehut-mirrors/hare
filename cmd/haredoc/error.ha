// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use cmd::haredoc::doc;
use errors;
use hare::module;
use hare::parse;
use io;
use os::exec;
use path;
use strconv;

type error = !(
	exec::error |
	errors::error |
	io::error |
	module::error |
	path::error |
	parse::error |
	strconv::error |
	doc::error |
);
