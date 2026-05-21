// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

.text
.set SYS_call, 6

/*
 * Generic call utility.
 * %rdi: capability address for call
 * %rax: user word for call (proto | function)
 */
.global sys.call_generic
sys.call_generic:
	endbr64
	orq %rax, %rdi
	movq $SYS_call, %rax
	movq %rcx, %r10
	syscall
	/* TODO: Handle errors */
	movq %rdi, %rax
	movq %rsi, %rdx
	ret

/*
 * Extended call utility.
 * %rdi: pointer to params::call_params structure
 * %rax: user word for call (proto | function)
 */
.global sys.callx_generic
sys.callx_generic:
	endbr64
	pushq %rdi
	movq 8(%rdi), %r11
	movq (%rdi), %rdi
	orq %rax, %rdi
	movq $SYS_call, %rax
	shlq $8, %r11
	orq %r11, %rax
	movq %rcx, %r10
	syscall
	/* TODO: Check %rax for errors */
	popq %r11
	shrq $8, %rax
	movq %rax, 16(%r11)
	movq %rdi, %rax
	movq %rsi, %rdx
	ret
