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

.section .text.sys._mmap
.global sys._mmap
sys._mmap:
	// DragonFly BSD uses 7 arguments for mmap syscall
	//
 	//   rax: 197 (SYS_mmap)
	//   rdi: addr
	//   rsi: length
	//   rdx: prot
	//   r10: flags
	//   r8:  fd
	//   r9:  pad (0)
	//   on stack: offs

	// Move flags to r10
	movq %rcx, %r10

	// Put offs on stack
	sub $16, %rsp
	mov %r9, 8(%rsp)

	// Zero pad
	mov $0, %r9

	// SYS_mmap
	mov $197, %rax

	syscall
	jc error_mmap

	add $16, %rsp
	ret
error_mmap:
	neg %rax
	add $16, %rsp
	ret

.section .text.sys._pipe2
.global sys._pipe2
sys._pipe2:
	// SYS_pipe2
	mov $538, %rax
	syscall
	jc error_pipe2
	// %rdi is preserved by syscall
	movl	%eax,0(%rdi)
	movl	%edx,4(%rdi)
	movq	$0,%rax
	ret
error_pipe2:
	movl $-1, 0(%rdi)
	movl $-1, 4(%rdi)
	neg %rax
	ret

