// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

const certfiles: []str = [
	"/etc/ssl/certs/ca-certificates.crt",                // Debian/Ubuntu/Gentoo etc.
	"/etc/pki/tls/certs/ca-bundle.crt",                  // Fedora/RHEL 6
	"/etc/ssl/ca-bundle.pem",                            // OpenSUSE
	"/etc/pki/tls/cacert.pem",                           // OpenELEC
	"/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem", // CentOS/RHEL 7
	"/etc/ssl/cert.pem",                                 // Alpine Linux
];

const certdirs: []str = [
	"/etc/ssl/certs",               // SLES10/SLES11, https://golang.org/issue/12139
	"/etc/pki/tls/certs",           // Fedora/RHEL
	"/system/etc/security/cacerts", // Android
];
