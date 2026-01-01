// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use proto::system;

// Immediately triggers an abnormal process termination.
export fn halt() never = {
	if (process_svc == ~0) {
		for (true) void;
	};
	system::process_exit(process_svc, 1);
	for (true) void;
};
