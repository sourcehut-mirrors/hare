// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use path;
use strings;

// Reads all entries from a directory. The caller must free the return value
// with [[dirents_free]].
export fn readdir(fs: *fs, path: str) ([]dirent | error) = {
	let i = iter(fs, path)?;
	defer finish(i);
	let ents: []dirent = [];

	for (let d => next(i)?) {
		append(ents, dirent_dup(&d));
	};
	return ents;
};

// Frees a slice of [[dirent]]s.
export fn dirents_free(dirents: []dirent) void = {
	for (let d &.. dirents) {
		dirent_finish(d);
	};
	free(dirents);
};

// Removes a directory, and anything in it.
export fn rmdirall(fs: *fs, path: str) (void | error) = {
	let buf = path::init(path)!;
	return rmdirall_path(fs, &buf);
};

fn rmdirall_path(fs: *fs, buf: *path::buffer) (void | error) = {
	let it = iter(fs, path::string(buf))?;
	defer finish(it);
	for (let ent => next(it)?) {
		path::push(buf, ent.name)!;

		switch (ent.ftype & io::mode::DIR) {
		case io::mode::DIR =>
			rmdirall_path(fs, buf)?;
		case =>
			remove(fs, path::string(buf))?;
		};
		path::pop(buf);
	};
	return rmdir(fs, path::string(buf));
};
