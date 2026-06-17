// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use crypto::ecdsa;
use encoding::asn1::stdoid;
use memio;
use strings;

const p256key_pkcs8 = `
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgI+qZLB2vhtMQAkQf
/1lwKEWE2LWwpktFPnTCdnDq8m6hRANCAARzl5L8pSnzBkaegS/Ao5Mtc0ugTtXy
9aL0zOQ1En5eFwJXsqsJql6RpcD8a1NLMVtH9z2vBfu9dfbPLowm/RSi
-----END PRIVATE KEY-----
`;

const p256key_v0 = `
-----BEGIN EC PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgI+qZLB2vhtMQAkQf
/1lwKEWE2LWwpktFPnTCdnDq8m6hRANCAARzl5L8pSnzBkaegS/Ao5Mtc0ugTtXy
9aL0zOQ1En5eFwJXsqsJql6RpcD8a1NLMVtH9z2vBfu9dfbPLowm/RSi
-----END EC PRIVATE KEY-----
`;

const p256key_v1 = `
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEICPqmSwdr4bTEAJEH/9ZcChFhNi1sKZLRT50wnZw6vJuoAoGCCqGSM49
AwEHoUQDQgAEc5eS/KUp8wZGnoEvwKOTLXNLoE7V8vWi9MzkNRJ+XhcCV7KrCape
kaXA/GtTSzFbR/c9rwX7vXX2zy6MJv0Uog==
-----END EC PRIVATE KEY-----
`;

const p256cert = `
-----BEGIN CERTIFICATE-----
MIIBojCCAUkCFDj/7iqrM8MZP5PTw6xo6o+GhSJ9MAoGCCqGSM49BAMCMFQxCzAJ
BgNVBAYTAkFUMRQwEgYDVQQIDAtGZWxka2lyY2hlbjEVMBMGA1UECgwMRGVua21h
c2NoaW5lMRgwFgYDVQQDDA9kZW5rbWFzY2hpbmUuYXQwHhcNMjMwNzA5MTEyNzMy
WhcNMzMwNzA2MTEyNzMyWjBUMQswCQYDVQQGEwJBVDEUMBIGA1UECAwLRmVsZGtp
cmNoZW4xFTATBgNVBAoMDERlbmttYXNjaGluZTEYMBYGA1UEAwwPZGVua21hc2No
aW5lLmF0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEc5eS/KUp8wZGnoEvwKOT
LXNLoE7V8vWi9MzkNRJ+XhcCV7KrCapekaXA/GtTSzFbR/c9rwX7vXX2zy6MJv0U
ojAKBggqhkjOPQQDAgNHADBEAiBZo1B2BxptCa5idL3ROSVRaWlN2Nf+UR8XccRy
aZG4LAIgZDazYl+sK5mPCf72HC8Lms42GCwijuR5Dkn5iJui+rA=
-----END CERTIFICATE-----
`;

const p384key = `
-----BEGIN PRIVATE KEY-----
MIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDBBCCO6vqV6mdPEXbwi
EBYdJoPKNLX1GZJbpjQh2CswFvltoEddIlAfHzk7ROnkbJahZANiAATJQqrjq4v+
oQ1dQOCwczIxisQE5mbsXSoe3GuayvkGScDzxDj4zyuEd07KjR7BPL96PWVu+JYe
+YbstU35iiGSlleWu1aR13h9spimjkX200pOnhx40U8OCYY0hfn1Pkc=
-----END PRIVATE KEY-----
`;

const p384cert = `
-----BEGIN CERTIFICATE-----
MIIB5zCCAWygAwIBAgIUNrowpl523IqTu8S/G/yZgrrq6GcwCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMaGFyZWxhbmcub3JnMB4XDTI2MDUyMDE3MDYxNloXDTM2MDUx
NzE3MDYxNlowFzEVMBMGA1UEAwwMaGFyZWxhbmcub3JnMHYwEAYHKoZIzj0CAQYF
K4EEACIDYgAEyUKq46uL/qENXUDgsHMyMYrEBOZm7F0qHtxrmsr5BknA88Q4+M8r
hHdOyo0ewTy/ej1lbviWHvmG7LVN+YohkpZXlrtWkdd4fbKYpo5F9tNKTp4ceNFP
DgmGNIX59T5Ho3kwdzAdBgNVHQ4EFgQUc2WALFN21LSwT3QDrUFmM4Y2Eh4wHwYD
VR0jBBgwFoAUc2WALFN21LSwT3QDrUFmM4Y2Eh4wDwYDVR0TAQH/BAUwAwEB/zAL
BgNVHQ8EBAMCAoQwFwYDVR0RBBAwDoIMaGFyZWxhbmcub3JnMAoGCCqGSM49BAMC
A2kAMGYCMQD7U4opxAuAfrfZJzUZC/mD8nOM/f9RlOiGi6pSjPxWTxtjBPud3j7S
DnBvIAKipOMCMQDbeqefKCYJf8H1c77KUyfp3C52oCT2QyzLIiAZh/xY3wZ9KG0g
3n7M8ejpBSivUG0=
-----END CERTIFICATE-----
`;

const p521key = `
-----BEGIN PRIVATE KEY-----
MIHuAgEAMBAGByqGSM49AgEGBSuBBAAjBIHWMIHTAgEBBEIBBiXa4KnxXKtDsvVL
fFpMcxSQtkBr/YrpE0KgpJXdR0QHmxVWZjIheME0x7Kaz/fNkA+GI7aFy56cMjyG
NuXImpKhgYkDgYYABAC992wducwV7KRHNRccIBHmhHlUWSQW0VK2gUefD/VWnmG2
Bnuv3rqfVTkGVC164JuNdfJq+fiGHJ5aG453zT1dFgHpAVFXerw2AxuZm5syMZZb
H99U+Tq84/iNyLpnSQHfTAh4WmKAtv/xM0Pvg/kiyDx4CfYoD5xaP9tt5nuCWlv1
+A==
-----END PRIVATE KEY-----
`;

const p521cert = `
-----BEGIN CERTIFICATE-----
MIICMTCCAZKgAwIBAgIUOxDJadvVqYb9iT1DUORD164H7/UwCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMaGFyZWxhbmcub3JnMB4XDTI2MDUyMDE3MDYxNloXDTM2MDUx
NzE3MDYxNlowFzEVMBMGA1UEAwwMaGFyZWxhbmcub3JnMIGbMBAGByqGSM49AgEG
BSuBBAAjA4GGAAQAvfdsHbnMFeykRzUXHCAR5oR5VFkkFtFStoFHnw/1Vp5htgZ7
r966n1U5BlQteuCbjXXyavn4hhyeWhuOd809XRYB6QFRV3q8NgMbmZubMjGWWx/f
VPk6vOP4jci6Z0kB30wIeFpigLb/8TND74P5Isg8eAn2KA+cWj/bbeZ7glpb9fij
eTB3MB0GA1UdDgQWBBTOxqoLe8ILUhnqW7rTLXHXd5GnyTAfBgNVHSMEGDAWgBTO
xqoLe8ILUhnqW7rTLXHXd5GnyTAPBgNVHRMBAf8EBTADAQH/MAsGA1UdDwQEAwIC
hDAXBgNVHREEEDAOggxoYXJlbGFuZy5vcmcwCgYIKoZIzj0EAwIDgYwAMIGIAkIB
vF0BzwBqc8nR2NoROkyUqJRpSSb13HBlJE1uU7yn37mTViZRAQHKlPnmsXS9jfDP
BfLNLHEKlVBLvc4PE//klC0CQgEIZ2CSyeheQzPCprOhIXgSPHkS5Pe9SieGS519
kMHHefX4984LYtdu6Z/51zYCh1YFKgfoMVHzWZpmo4mTX4kUwQ==
-----END CERTIFICATE-----
`;

@test fn ec_keyformats() void = {
	let pk = newprivkey();
	let buf = memio::fixed(strings::toutf8(p256key_v1));
	privkey_load_pem(&pk, &buf)!;

	let pkv0 = newprivkey();
	let buf = memio::fixed(strings::toutf8(p256key_v0));
	privkey_load_pem(&pkv0, &buf)!;

	assert(bytes::equal(ecdsa::privkey_buf(&pkv0.p256),
			ecdsa::privkey_buf(&pk.p256)));

	let pkpkcs8 = newprivkey();
	let buf = memio::fixed(strings::toutf8(p256key_pkcs8));
	privkey_load_pem(&pkpkcs8, &buf)!;

	assert(bytes::equal(ecdsa::privkey_buf(&pkpkcs8.p256),
			ecdsa::privkey_buf(&pk.p256)));
};

@test fn ec_p256() void = {
	test_sign(p256key_v1, p256cert, stdoid::ECDSA_WITH_SHA256);
};

@test fn ec_p384() void = {
	test_sign(p384key, p384cert, stdoid::ECDSA_WITH_SHA256);
};

@test fn ec_p521() void = {
	test_sign(p521key, p521cert, stdoid::ECDSA_WITH_SHA256);
};
