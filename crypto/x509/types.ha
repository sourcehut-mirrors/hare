// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net::ip;

// Key usage bit flags. Values differ from the RFC, because they reflect how
// bit flags are stored in [[cert]].
export type keyusage = enum u16 {
	// Public key is used for verifying signatures other than signatures
	// on certificates [[keyusage::KEY_CERT_SIGN]] and CRLs
	// [[keyusage::CRL_SIGN]].
	DIGITAL_SIGNATURE = 1 << 15,

	// The public key is used to provide a non-repudiation service to
	// avoid falsely denying some action.
	CONTENT_COMMITMENT = 1 << 14,

	// The public key is used to encipher raw private or secret keys.
	KEY_ENCIPHERMENT = 1 << 13,

	// The public key is used to encipher raw user data without the use of
	// an intermediate symmetric cipher.
	DATA_ENCIPHERMENT = 1 << 12,

	// The public key is used for key agreement.
	KEY_AGREEMENT = 1 << 11,

	// The public key is used for verifying signatures on public key
	// certificates.
	KEY_CERT_SIGN = 1 << 10,

	// The public key is used for verifying signatures on certificate
	// revocation lists.
	CRL_SIGN = 1 << 9,

	// Defined only in combination with [[keyusage::KEY_AGREEMENT]]. The
	// public key may be used only for enciphering data while performing key
	// agreement.
	ENCIPHER_ONLY = 1 << 8,

	// Defined only in combination with [[keyusage::KEY_AGREEMENT]]. The
	// public key may be used only for deciphering data while performing key
	// agreement.
	DECIPHER_ONLY = 1 << 7,
};

// Extended key usage bit flags.
export type extkeyusage = enum u8 {
	// Any key usage allowed
	ANY = 1 << 0,

	// TLS WWW server authentication
	SERVER_AUTH = 1 << 1,

	// TLS WWW client authentication
	CLIENT_AUTH = 1 << 2,

	// Signing of downloadable executable code
	CODE_SIGNING = 1 << 3,

	// Email protection
	EMAIL_PROTECTION = 1 << 4,

	// Binding the hash of an object to a time
	TIME_STAMPING = 1 << 5,

	// Signing OCSP responses
	OCSP_SIGNING = 1 << 6,
};

// String representation of a key usage.
export fn strkeyusage(ku: keyusage) str = {
	switch (ku) {
	case keyusage::DIGITAL_SIGNATURE =>
		return "digital_signature";
	case keyusage::CONTENT_COMMITMENT =>
		return "content_commitment";
	case keyusage::KEY_ENCIPHERMENT =>
		return "key_encipherment";
	case keyusage::DATA_ENCIPHERMENT =>
		return "data_encipherment";
	case keyusage::KEY_AGREEMENT =>
		return "key_agreement";
	case keyusage::KEY_CERT_SIGN =>
		return "key_cert_sign";
	case keyusage::CRL_SIGN =>
		return "crl_sign";
	case keyusage::ENCIPHER_ONLY =>
		return "encipher_only";
	case keyusage::DECIPHER_ONLY =>
		return "decipher_only";
	case =>
		abort();
	};
};

// String representation of an external key usage.
export fn strextkeyusage(eku: extkeyusage) str = {
	switch (eku) {
	case extkeyusage::ANY =>
		return "any";
	case extkeyusage::SERVER_AUTH =>
		return "server_auth";
	case extkeyusage::CLIENT_AUTH =>
		return "client_auth";
	case extkeyusage::CODE_SIGNING =>
		return "code_signing";
	case extkeyusage::EMAIL_PROTECTION =>
		return "email_protection";
	case extkeyusage::TIME_STAMPING =>
		return "time_stamping";
	case extkeyusage::OCSP_SIGNING =>
		return "ocsp_signing";
	};
};

// General name
export type gn = enum u32 {
	OTHER = 0,
	RFC822 = 1,
	DNS = 2,
	X400 = 3,
	DN = 4,
	EDI_PARTY = 5,
	URI = 6,
	IP = 7,
	REGISTERED_ID = 8,
};

// String representation of given general name 'gn'.
export fn strgn(gn: u32) str = {
	switch (gn) {
	case gn::OTHER =>
		return "OTHER";
	case gn::RFC822 =>
		return "RFC822";
	case gn::DNS =>
		return "DNS";
	case gn::X400 =>
		return "X400";
	case gn::DN =>
		return "DN";
	case gn::EDI_PARTY =>
		return "EDI_PARTY";
	case gn::URI =>
		return "URI";
	case gn::IP =>
		return "IP";
	case gn::REGISTERED_ID =>
		return "REGISTERED_ID";
	case =>
		return "invalid";
	};
};

type flaw = enum u32 {
	// Basic constraints must be crictical for certificate authorities
	NONCRIT_BASICC = 1 << 0,

	// authorityKeyProvider must only include keyIdentifier according
	// to CA/Browser Forum.
	COMPLEX_AKI = 1 << 1,
};

export type dnsname = str;
export type rfc822name = str;

export type name = (dnsname | rfc822name | ip::addr);
