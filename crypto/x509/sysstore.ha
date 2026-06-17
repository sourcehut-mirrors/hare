// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fs;

let syss: slicestore = @undefined;

@init fn init_sysstore() void = {
	syss = newslicestore([]);
};

// Returns the systems trusted certificates. This call will lazy load them once
// on the first call and returns the same store on each consequential call.
export fn sysstore() (slicestore | nomem) = {
	if (len(syss.certs) > 0) {
		return syss;
	};

	for (let f .. certfiles) {
		match (store_add_file(&syss, f)) {
		case void => void;
		case nomem =>
			return nomem;
		case fs::error =>
			yield;
		case let e: error =>
			// XXX should we somehow log that somewhere?
			yield;
		};
	};

	for (let d .. certdirs) {
		match (store_add_path(&syss, d)) {
		case void => void;
		case nomem =>
			return nomem;
		case fs::error =>
			yield;
		case let e: error =>
			// XXX should we somehow log that somewhere?
			yield;
		};
	};

	return syss;
};
