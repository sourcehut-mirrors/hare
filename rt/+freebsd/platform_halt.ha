// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use sys;

// Immediately triggers an abnormal process termination.
export fn halt() never = {
	for (true) {
		_ = sys::kill(sys::getpid(), sys::SIGABRT);
	};
};
