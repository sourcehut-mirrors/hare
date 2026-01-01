.text
.global _start
_start:
	xor %rbp, %rbp
	movq %rsp, %rdi
	andq $-16, %rsp
	call rt.start_hermes

.type _start, @function
.size _start, .-_start

