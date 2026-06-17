// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::pem;
use io;
use memio;
use strings;
use bytes;

@test fn san() void = {
	let certbuf = memio::fixed(strings::toutf8(san_cert));
	let certs = parse_pemcerts(&certbuf)!;
	defer certs_free(certs);
	let crt = certs[0];

	let san = cert_subjectan(&crt)! as gniter;

	let r = gn_next_dns(&san)! as utf8reader;
	let host = io::drain(&r)!;
	defer free(host);
	assert(bytes::equal(strings::toutf8("harelang.org"), host));

	let r = gn_next_dns(&san)! as utf8reader;
	let host = io::drain(&r)!;
	defer free(host);
	assert(bytes::equal(strings::toutf8("docs.harelang.org"), host));

	assert(gn_next_dns(&san) is done);
};
