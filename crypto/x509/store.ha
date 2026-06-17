// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::sha256;
use encoding::asn1;
use encoding::pem;
use endian;
use errors;
use fmt;
use fs;
use hash;
use io;
use memio;
use os;
use types;

export def MAX_SUBJHASHSZ = sha256::SZ;

// A store is a pointer to a [[storevtable]] which allows implementing
// user-defined certificate stores. A store contains a collection of
// certificates and provides means to find and iterate through them. Some
// implementations may provide the possibility to add additional certificates
// to the store.
export type store = *storevtable;

// The interface for finding certificates by providing the raw subject in
// its DER encoded form. The raw subject is borrowed by the store iterator.
export type store_findfn = fn (
	s: *store,
	rawsubject: []u8
) (storeiter | io::error);

// The interface for receiving the next certificate after the current position
// the iterator 'it' points to.
export type store_nextfn = fn (
	s: *store,
	it: *storeiter
) (*cert | done | io::error);

// The interface for adding a certificate to a store.
export type store_addfn = fn (s: *store, c: cert) (void | nomem | io::error);

// The interface for finishing a store.
export type store_finishfn = fn (s: *store) void;

export type storevtable = struct {
	find: *store_findfn,
	next: *store_nextfn,
	add: nullable *store_addfn,
	finish: nullable *store_finishfn,
};

export type storeiter = struct {
	store: *store,
	rawsubject: []u8,
	subjecthash: [MAX_SUBJHASHSZ]u8,
	idx: size,
	subidx: size,
};

fn next_cert(it: *storeiter) (*cert | done | io::error) =
	it.store.next(it.store, it);

fn store_find(s: *store, rawsubject: []u8) (storeiter | io::error) =
	s.find(s, rawsubject);

// Adds a certificate to the store. The store will take ownership of the
// certificate and will invoke [[cert_free]] when the store is finished.
export fn store_add(s: *store, c: cert) (void | nomem | io::error) = {
	match (s.add) {
	case null =>
		return errors::unsupported;
	case let add: *store_addfn =>
		return add(s, c);
	};
};

// Creates a new variable sized store that allows certificates to be added.
//
// Must be finished with [[store_finish]].
export fn newstore() slicestore = newslicestore([]);

fn slicestore_find(s: *store, rawsubject: []u8) (storeiter | io::error) = {
	return storeiter {
		store = s,
		rawsubject = rawsubject,
		subjecthash = [0...],
		idx = 0,
		subidx = 0,
	};
};

fn slicestore_next(s: *store, it: *storeiter) (*cert | done | io::error) = {
	let s = s: *slicestore;

	for (it.idx < len(s.certs); it.idx += 1) {
		let c = &s.certs[it.idx];
		if (bytes::equal(c.subject, it.rawsubject)) {
			it.idx += 1;
			return c;
		};
	};

	return done;
};

fn slicestore_add(s: *store, c: cert) (void | nomem | io::error) = {
	let s = s: *slicestore;
	append(s.certs, c)?;
};

fn slicestore_finish(s: *store) void = {
	let s = s: *slicestore;
	for (let c &.. s.certs) {
		cert_free(c);
	};
	free(s.certs);
	s.certs = [];
};

const slicestorevt = storevtable {
	find = &slicestore_find,
	next = &slicestore_next,
	add = &slicestore_add,
	finish = &slicestore_finish,
};

export type slicestore = struct {
	s: store,
	certs: []cert,
};

export fn newslicestore(certs: []cert) slicestore = slicestore {
	s = &slicestorevt,
	certs = certs,
};

// Loads all certificates present at given path into 'store'. If it's a
// directory, only files of this directory will be added. Sub directories will
// be ignored.
export fn store_add_path(
	s: *store,
	path: str
) (void | nomem | fs::error | error) = {
	let stat = os::stat(path)?;
	if (fs::isfile(stat.mode)) {
		return store_add_file(s, path)?;
	};
	if (!fs::isdir(stat.mode)) {
		return fs::wrongtype;
	};

	let d = os::diropen(path)?;
	let it = fs::iter(d, ".")?;
	defer fs::finish(it);

	for (let n => fs::next(it)?) {
		if (!fs::isfile(n.ftype)) {
			continue;
		};


		let file = fs::open(d, n.name)?;
		defer io::close(file)!;
		match (store_addfrom_handle(s, file)) {
		case void => void;
		case nomem =>
			return nomem;
		case let e: error =>
			return e;
		case let e: io::error =>
			return e: fs::error;
		};
	};
};

// Adds a PEM encoded file stored at 'path'.
export fn store_add_file(
	s: *store,
	path: str
) (void | nomem | fs::error | error) = {
	let f = os::open(path)?;
	defer io::close(f)!;
	match (store_addfrom_handle(s, f)) {
	case void => void;
	case nomem =>
		return nomem;
	case let e: error =>
		return e;
	case let e: io::error =>
		return e: fs::error;
	};
};

// Adds a PEM encoded file copied from 'src'.
export fn store_addfrom_handle(
	s: *store,
	src: io::handle
) (void | nomem | io::error | error) = {
	let certs = parse_pemcerts(src)?;
	let ok = false;
	let added: size = 0;

	// Only free the slice on success, since the store owns the certs now.
	// On partial failure, only free those, that have not been added yet.
	defer if (ok) free(certs) else certs_free(certs[added..]);

	let crts = certs[..];
	for (added < len(certs); added += 1) {
		store_add(s, certs[added])?;
	};

	ok = true;
};

// Releases resources used by the [[store]] 's'.
export fn store_finish(s: *store) void = {
	match (s.finish) {
	case null => void;
	case let f: *store_finishfn =>
		f(s);
	};
};
