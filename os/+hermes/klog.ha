// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use sys;

const _klog_vt = io::vtable {
	reader = &klog_read,
	writer = &klog_write,
	...
};

const _klog: io::stream = &_klog_vt;

// An [[io::stream]] which writes to the kernel log.
export const klog: *io::stream = &_klog;

fn klog_read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = io::EOF;

fn klog_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	_ = sys::log(buf: *[*]u8, len(buf));
	return len(buf);
};
