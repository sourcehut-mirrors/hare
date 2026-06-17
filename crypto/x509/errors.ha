// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::asn1;
use io;

export type badsig = !str;

const weaksig: badsig = "weak signature hash";
const invalidsig: badsig = "signature verification failed";
const unknownhash: badsig = "unsupported signature hash function";
const weakparams: badsig = "weak signature or public key parameters";

// Certificate format or encoding wrong.
export type badformat = !str;

// Invalid input.
export type invalid = !str;

// Certificate not fully readable.
export type truncated = !void;

// Certificate validity period expired.
export type expired = !void;

// Unsupported feature.
export type unsupported = !str;

// Unsupported signature algorithm.
export type unknownalgo = !void;

// Certificate is not a certificate authority.
export type notca = !void;

// No valid chain can be found.
export type nochain = !void;

// Critical extension not supported.
export type critext = !void;

// Max trust path length exceeded.
export type maxpath = !void;

// Bad key usage.
export type badusage = !void;

export type weakkey = !void;

// An error which may be returned from an x509 function.
export type error = !(...io::error | badsig | expired | badformat | unknownalgo
	| unsupported | notca | nochain | truncated | critext | maxpath
	| badusage | invalid | weakkey);

type _error = !(...asn1::error | ...error);

fn norm_error(e: _error) error = {
	match (e) {
	case let e: io::error =>
		match (asn1::unwrap_err(e)) {
		case let e: io::error =>
			return e;
		case let e: asn1::error =>
			return norm_error(e);
		};
	case let e: asn1::error =>
		match (e) {
		case asn1::badformat =>
			return "corrupt DER encoding": badformat;
		case asn1::invalid =>
			return "invalid DER encoding": badformat;
		case asn1::truncated =>
			return truncated;
		case =>
			abort();
		};
	case let e: error =>
		return e;
	};
};

// Converts an [[error]] into an user-friendly string.
export fn strerror(e: error) str = {
	match (e) {
	case let e: io::error =>
		return io::strerror(e);
	case let e: badsig =>
		return e;
	case expired =>
		return "certificate expired";
	case let b: badformat =>
		return b;
	case let e: invalid =>
		return e;
	case truncated =>
		return "truncated";
	case let e: unsupported =>
		return e;
	case unknownalgo =>
		return "unsupported signature algorithm";
	case critext =>
		return "unsupported critical extension";
	case notca =>
		return "parent cert is not a certificate authority";
	case nochain =>
		return "trust path could not be found";
	case maxpath =>
		return "max trust path length exceeded";
	case badusage =>
		return "bad key usage";
	case weakkey =>
		return "weak key parameters";
	};
};
