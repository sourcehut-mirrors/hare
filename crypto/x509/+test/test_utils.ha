// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::pem;
use memio;
use io;
use strings;

@test fn verify_hostname() void = {
	let certbuf = memio::fixed(strings::toutf8(san_cert));
	let certs = parse_pemcerts(&certbuf)!;
	defer certs_free(certs);
	let crt = certs[0];

	cert_verify_hostname(&crt, "harelang.org": dnsname)!;
	cert_verify_hostname(&crt, "docs.harelang.org": dnsname)!;

	assert(!(cert_verify_hostname(&crt, "evil.harelang.org": dnsname) is void));
};
