// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

.text
.global _start
_start:
	xor %rbp, %rbp
	movq %rsp, %rdi
	andq $-16, %rsp
	call rt.start_gaia
