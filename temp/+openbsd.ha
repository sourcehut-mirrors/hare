// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::random;
use encoding::hex;
use fs;
use io;
use memio;
use os;
use path;

fn get_tmpdir() str = os::tryenv("TMPDIR", "/tmp");

// Creates a temporary directory. This function only guarantees that the
// directory will have a unique name and be placed in the system temp directory,
// but not that it will be removed automatically; the caller must remove it when
// they're done using it via [[os::rmdir]] or [[os::rmdirall]].
//
// The return value is statically allocated and will be overwritten on
// subsequent calls.
export fn dir() str = {
	const buf: [8]u8 = [0...], name: [16]u8 = [0...];
	random::buffer(buf[..]);

	const sink = memio::fixed(name);
	let enc = hex::newencoder(&sink);
	io::write(&enc, buf) as size;
	const name = memio::string(&sink)!;

	static let buf = path::buffer { ... };
	path::set(&buf, get_tmpdir(), name)!;
	const path = path::string(&buf);
	match (os::mkdir(path, 0o700)) {
	case let err: fs::error => abort("Could not create temp directory");
	case void => void;
	};
	return path;
};
