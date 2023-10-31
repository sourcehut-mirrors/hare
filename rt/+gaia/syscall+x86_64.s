// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

.section .text.rt.syscall0
.global rt.syscall0
rt.syscall0:
	movq %rdi, %rax
	syscall
	ret

.section .text.rt.syscall1
.global rt.syscall1
rt.syscall1:
	movq %rdi, %rax
	movq %rsi, %rdi
	syscall
	ret

.section .text.rt.syscall2
.global rt.syscall2
rt.syscall2:
	movq %rdi, %rax
	movq %rsi, %rdi
	movq %rdx, %rsi
	syscall
	ret

.section .text.rt.syscall3
.global rt.syscall3
rt.syscall3:
	movq %rdi, %rax
	movq %rsi, %rdi
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	ret

.section .text.rt.syscall4
.global rt.syscall4
rt.syscall4:
	movq %rdi, %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	ret

.section .text.rt.syscall5
.global rt.syscall5
rt.syscall5:
	movq %rdi, %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %r9, %r8
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	ret
