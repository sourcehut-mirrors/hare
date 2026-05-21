// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

.text
.set SYS_reply,  8
.set ENOSYS,     10
.set EOPNOTSUPP, 136
.set reply_flag_REPLY_TO, (1 << 12)

.global sys.recv_dispatch
sys.recv_dispatch:
	/*
	 * %rdi: 8-bit function number
	 * %rax: function table
	 */
	shlq $3, %rdi		/* ×8 */
	addq %rdi, %rax

	cmpq $0, (%rax)
	je sys.recv_eopnotsupp

	/* %rdi: *sys::server */
	movq 0(%rsp), %rdi

	/* Stash caller flags */
	movq 16(%rsp), %r11
	movq %r11, (%rdi)

	/* Stash badge */
	movq 8(%rsp), %r11
	movl %r11d, 16(%rdi)

	/* Clear reply flags */
	xorq %r11, %r11
	movq %r11, 8(%rdi)

	/* Jump to dispatch */
	addq $24, %rsp
	pushq %rdi
	pushq $1f
	jmpq *(%rax)

1:	/* Normal return via SYS_reply */
	popq %r11
	movq %rax, %rdi
	movq %rdx, %rsi
	movq 8(%r11), %rax
	shlq $8, %rax
	orq $SYS_reply, %rax
	syscall
	ret

.global sys.recv_error
sys.recv_error:
	/* Error via SYS_recv */
	addq $24, %rsp
	/* Indicate that the error occured during SYS_recv */
	orq $(1 << 8), %rax
	ret

.global sys.recv_enosys
sys.recv_enosys:
  	addq $24, %rsp
	movq $SYS_reply, %rax
	movq $ENOSYS, %rdi
	xorq %rsi, %rsi
	syscall
	ret

.global sys.recv_eopnotsupp
sys.recv_eopnotsupp:
  	addq $24, %rsp
	movq $SYS_reply, %rax
	movq $EOPNOTSUPP, %rdi
	xorq %rsi, %rsi
	syscall
	ret

.global sys.reply
sys.reply:
	movq 8(%rdi), %rax
	shlq $8, %rax
	movb $SYS_reply, %al
	movq %rsi, %rdi
	movq %rdx, %rsi
	syscall
	ret

.global sys.reply_to
sys.reply_to:
	/* TODO: Maybe we should use SYS_call against the reply capability */
	movq 8(%rdi), %rax
	orq $reply_flag_REPLY_TO, %rax
	shlq $8, %rax
	movb $SYS_reply, %al
	movq %rsi, %r11
	movq %rdx, %rdi /* r1 */
	movq %rcx, %rsi /* r2 */
	movq %r11, %rdx /* Reply capability address */
	syscall
	ret

