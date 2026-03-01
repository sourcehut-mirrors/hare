.section .text
error:
	neg %rax
	ret

.section .text.sys.syscall0
.global sys.syscall0
sys.syscall0:
	movq %rdi, %rax
	syscall
	jc error
	ret

.section .text.sys.syscall1
.global sys.syscall1
sys.syscall1:
	movq %rdi, %rax
	movq %rsi, %rdi
	syscall
	jc error
	ret

.section .text.sys.syscall2
.global sys.syscall2
sys.syscall2:
	movq %rdi, %rax
	movq %rsi, %rdi
	movq %rdx, %rsi
	syscall
	jc error
	ret

.section .text.sys.syscall3
.global sys.syscall3
sys.syscall3:
	movq %rdi, %rax
	movq %rsi, %rdi
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	jc error
	ret

.section .text.sys.syscall4
.global sys.syscall4
sys.syscall4:
	movq %rdi, %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	jc error
	ret

.section .text.sys.syscall5
.global sys.syscall5
sys.syscall5:
	movq %rdi, %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %r9, %r8
	movq %rdx, %rsi
	movq %rcx, %rdx
	syscall
	jc error
	ret

.section .text.sys.syscall6
.global sys.syscall6
sys.syscall6:
	movq %rdi, %rax
	movq %r8, %r10
	movq %rsi, %rdi
	movq %r9, %r8
	movq %rdx, %rsi
	movq 8(%rsp), %r9
	movq %rcx, %rdx
	syscall
	jc error
	ret

.section .text.sys.__sigtramp_siginfo_2
.global sys.__sigtramp_siginfo_2
sys.__sigtramp_siginfo_2:
	movq	%r15,%rdi
	/* $308 = SYS_setcontext */
	movq	$308, %rax
	syscall
	movq	$-1,%rdi
	/* $1 = SYS_exit */
	movq	$1, %rax
	syscall
	ret
