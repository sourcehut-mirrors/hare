// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::asn1::stdoid;

const ed25519_key = `
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIB5wKAE9Y/C1La4X22wBABfH3JKsnjDngAyDzLCvIVp1
-----END PRIVATE KEY-----
`;

const ed25519_cert = `
-----BEGIN CERTIFICATE-----
MIIBaTCCARugAwIBAgIUciKNl6WhGwqK77Xmn7mzZsCqMcMwBQYDK2VwMBcxFTAT
BgNVBAMMDGhhcmVsYW5nLm9yZzAeFw0yNTEwMjQxMjE0MDJaFw0zNTEwMjIxMjE0
MDJaMBcxFTATBgNVBAMMDGhhcmVsYW5nLm9yZzAqMAUGAytlcAMhAMYRoCFFX4Zg
6erhpyS3B55PI7hJFJ1yVvhKyZAeEzlIo3kwdzAdBgNVHQ4EFgQUEFt6WvH+l0zX
GP2bWPmE6txO8KwwHwYDVR0jBBgwFoAUEFt6WvH+l0zXGP2bWPmE6txO8KwwDwYD
VR0TAQH/BAUwAwEB/zALBgNVHQ8EBAMCAoQwFwYDVR0RBBAwDoIMaGFyZWxhbmcu
b3JnMAUGAytlcANBACidKOJttbdBfBu2HJyBSf7TyFPzsYQ/sydhGuBopcChgmZ3
rnvpFwb7DK9JA8AKIcyfMpjPqqWXMgZJxye0wQc=
-----END CERTIFICATE-----
`;

@test fn ed25519() void =
	test_sign(ed25519_key, ed25519_cert, stdoid::ED25519);
