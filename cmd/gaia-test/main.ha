// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>
//
// Not all modules are supported on Gaia -- in some cases, such as net, the port
// is incomplete; in other cases, such as unix::signal, support is not planned.
// "hare test" currently collects all modules regardless of support status on
// the target platform, which causes problems on Gaia.
// 
// See the companion repository for detailed instructions on how to set up a
// test harness for Gaia:
//
// https://git.sr.ht/~sircmpwn/hare-gaia

use test;
// Include only modules supported on Gaia:
use ascii;
use crypto;
use crypto::aes;
use crypto::argon2;
//use crypto::bcrypt;		// crypto::random
use crypto::bigint;
use crypto::chacha;
use crypto::chachapoly;
use crypto::cipher;
//use crypto::curve25519;	// crypto::random
use crypto::ed25519;
use crypto::hkdf;
use crypto::hmac;
use crypto::mac;
use crypto::math;
use crypto::poly1305;
//use crypto::random;		// todo
use crypto::rsa;
use crypto::salsa;
use crypto::sha1;
use crypto::sha256;
use crypto::sha512;
//use crypto::x25519;		// crypto::random
use bufio;
use bytes;
use encoding::base32;
use encoding::base64;
use encoding::hex;
use encoding::pem;
use encoding::utf8;
use endian;
use fmt;
use fnmatch;
use format::elf;
use format::ini;
use format::tar;
use fs;
use getopt;
//use glob;			// todo
use hash;
use hash::adler32;
use hash::crc16;
use hash::crc32;
use hash::crc64;
use hash::fnv;
use hash::siphash;
use hare::ast;
use hare::lex;
//use hare::module;		// todo
use hare::parse;
use hare::types;
use hare::unit;
use hare::unparse;
//use log;			// time::chrono
use io;
use math;
use memio;
//use mime;			// todo
//use net;			// todo
//use net::dial;		// todo
//use net::dns;			// todo
use net::ip;
//use net::tcp;			// todo
//use net::udp;			// todo
//use net::unix;		// todo
use net::uri;
use os;
use os::exec;
use path;
use regex;
use rt;
use shlex;
use sort;
use sort::cmp;
use strconv;
use strings;
use strings::template;
//use temp;			// todo
use time;
//use time::chrono;		// todo
//use time::date;		// todo
use types;
//use uuid;			// crypto::random

export fn main() void = {
	test::main();
};
