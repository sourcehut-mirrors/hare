// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use errors;
use io;
use time;
use time::chrono;
use time::date;

// Contains requirements for the chain to be valid.
export type verifyopts = struct {
	// A store of trusted certificates. If a valid link is found to one
	// of the containing certs, the chain is verified and the certificate
	// can be trusted.
	trusted: *store,

	// A store of intermediate certificates that are required to create
	// a chain to one of the trusted certificates.
	chain: *store,

	// The date when the chain has to be valid. Defaults to now.
	date: (void | date::date),

	// A bitset of keyusage values that are acceptable for the chain. See
	// [[keyusage]] for a list of values.
	keyusage: u16,

	// A bitset of which extended keyusage values are acceptable for the
	// chain. A list of possible values is defined in [[extkeyusage]]. A
	// chain is valid, if it allows any of the keyusages. Default keyusage
	// is [[extkeyusage::SERVER_AUTH]]. Use [[extkeyusage::ANY]] to accept
	// any keyusage.
	extkeyusage: u8,
};

export type chainiter = struct {
	leaf: *cert,
	opts: *verifyopts,
	bt: []link,
	sz: size,
};

export type pathiter = struct {
	v: *chainiter,
	idx: size,
};

export def BTSTEPSZ = size(link);

fn verifyopts_date(opts: *verifyopts) date::date = {
	let d = match (opts.date) {
	case void =>
		yield date::now();
	case let d: date::date =>
		yield d;
	};

	// Clear nanoseconds to comply with rfc5280.
	const nano = date::nanosecond(&d);
	if (nano > 0) {
		d = date::add(d, -nano);
	};

	return d;
};

// Buffer size for [[verifier]] or [[verify]] that supports chains up to a
// length of 32.
export def VERIFYBUFSZ: size = size(link) * 32;

// A certification chain verifier is an iterator that tries to find valid
// trust paths from the 'leaf' certificate to trusted certificates provided
// by 'opts' on each [[next_chain]] call.
//
// 'buf' is required to store the current chain. The maximum chain length
// depends on its size. You may use [[VERIFYBUFSZ]] as a generous default.
export fn verifier(
	leaf: *cert,
	opts: *verifyopts,
	buf: []u8
) (chainiter | error) = {
	if (leaf.errcritext) {
		return critext;
	};

	match (leaf.err) {
	case void => void;
	case let e: error => return e;
	};

	const at = verifyopts_date(opts);
	if (chrono::compare(&at, &leaf.validfrom)! < 0
		|| chrono::compare(&at, &leaf.validto)! > 0) {
		return expired;
	};

	let ku = match (leaf.keyusage) {
	case void => yield 0u16;
	case let ku: u16 => yield ku;
	};

	if (ku & opts.keyusage != opts.keyusage) {
		return badusage;
	};

	let eku = opts.extkeyusage;
	if (eku == 0) {
		eku = extkeyusage::SERVER_AUTH;
	};
	if (leaf.extkeyusage != 0 && leaf.extkeyusage & extkeyusage::ANY == 0
			&& leaf.extkeyusage & eku != eku) {
		return badusage;
	};

	const maxpathlen = len(buf) / size(link);
	let buf = (buf[..maxpathlen]: *[*]u8: *[*]link)[..maxpathlen];

	assert(maxpathlen > 1);

	buf[0] = link {
		cert = leaf,
		pathlen = 0,
		trusted = false,
		trustit = store_find(opts.trusted, leaf.issuer)!,
		chainit = store_find(opts.chain, leaf.issuer)!,
		extkeyusage = eku,
	};

	return chainiter {
		leaf = leaf,
		opts = opts,
		bt = buf,
		sz = 1,
	};
};

// Verifies given cert 'c' by finding a valid chain within given verification
// options 'opts'.
//
// 'buf' is required to cache the the chain during the process. The maximum
// chain length depends on its size. You may use [[VERIFYBUFSZ]] as a generous
// default.
export fn verify(c: *cert, opts: *verifyopts, buf: []u8) (void | error) = {
	let v = verifier(c, opts, buf)?;

	match (next_chain(&v)?) {
	case let pi: pathiter =>
		return;
	case done =>
		return nochain;
	};
};

fn in_chain(v: *chainiter, c: *cert) bool = {
	for (let i = 0z; i < v.sz; i += 1) {
		if (cert_equals(v.bt[i].cert, c)) {
			return true;
		};
	};
	return false;
};

// Tries to find the next valid chain. On success a path iterator ([[pathiter]])
// is returned, that can be used to loop over the trust path found.
export fn next_chain(v: *chainiter) (pathiter | error | done) = {
	let pathlen = 0u16;
	const at = verifyopts_date(v.opts);

	let err: error = nochain;

	for (true) {
		if (v.sz >= len(v.bt)) {
			err = maxpath;
			v.sz -= 1;
		};

		if (v.sz == 0) return err;

		pathlen = v.bt[v.sz - 1].pathlen;
		match (find_nextlink(v, pathlen, &at)) {
		case done =>
			v.sz -= 1;
		case let e: error =>
			err = e;
			v.sz -= 1;
		case let pair: (*cert, bool) =>
			let (c, trusted) = pair;

			if (!trusted && in_chain(v, c)) {
				continue;
			};

			if (trusted || !selfissued(c)) {
				pathlen += 1;
			};

			let cur = &v.bt[v.sz - 1];
			let eku = cur.extkeyusage | c.extkeyusage;

			v.bt[v.sz] = link {
				cert = c,
				pathlen = pathlen,
				trusted = trusted,
				trustit = store_find(v.opts.trusted, c.issuer)!,
				chainit = store_find(v.opts.chain, c.issuer)!,
				extkeyusage = eku,
			};

			v.sz += 1;
			if (trusted) {
				return pathiter { v = v, idx = 1 };
			};
		};
	};
};

fn find_nextlink(
	v: *chainiter,
	pathlen: u16,
	at: *date::date
) ((*cert, bool) | error | done) = {
	let cur = &v.bt[v.sz - 1];
	let err: error = nochain;

	for (let l => next_cert(&cur.trustit)!) {
		match (try_link(cur, l, at, true)) {
		case void =>
			return (l, true);
		case let e: error =>
			err = e;
		};
	};

	for (let l => next_cert(&cur.chainit)!) {
		match (try_link(cur, l, at, false)) {
		case void =>
			return (l, false);
		case let e: error =>
			err = e;
		};
	};

	return done;
};

export fn path_next_cert(p: *pathiter) (*cert | done) = {
	if (p.idx >= p.v.sz) {
		return done;
	};
	p.idx += 1;

	return p.v.bt[p.idx - 1].cert;
};


export type link = struct {
	cert: *cert,
	pathlen: u16,
	trusted: bool,
	chainit: storeiter,
	trustit: storeiter,
	extkeyusage: u8,
};

fn try_link(l: *link, p: *cert, at: *date::date, trusted: bool) (void | error) = {
	const c = l.cert;
	if (p.errcritext) {
		return critext;
	};

	p.err?;

	if (p.flaws != 0) {
		// TODO some of those flaws may be acceptable in intermediate
		//      certs
		return "invalid CA cert configuration": invalid;
	};

	match (p.maxpathlen) {
	case let max: u16 =>
		if (l.pathlen > max) {
			return maxpath;
		};
	case void =>
		yield;
	};

	const equal = cert_equals(c, p);
	if (!equal && !p.ca) {
		return notca;
	};

	if (chrono::compare(at, &p.validfrom)! < 0
		|| chrono::compare(at, &p.validto)! > 0) {
		return expired;
	};

	match (p.keyusage) {
	case void =>
		return "invalid CA cert configuration": invalid;
	case let ku: u16 =>
		if (ku & keyusage::KEY_CERT_SIGN == 0) {
			return notca;
		};
	};

	const eku = l.extkeyusage;
	if (p.extkeyusage != 0 && p.extkeyusage & extkeyusage::ANY == 0
			&& p.extkeyusage & eku != eku) {
		return badusage;
	};

	cert_checksigfrom(c, p)?;
};
