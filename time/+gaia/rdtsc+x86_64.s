// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

.section .text.time.rdtsc
.global time.rdtsc
time.rdtsc:
	xorq %rax, %rax
	rdtsc
	shl $32, %rdx
	orq %rdx, %rax
	ret
