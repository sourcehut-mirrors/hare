// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Immediately triggers an abnormal process termination.
export fn halt() never = {
	// TODO Hermes
	for (true) void;
};
