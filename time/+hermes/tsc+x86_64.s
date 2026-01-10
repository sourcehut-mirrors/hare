.text
.global time.read_ticks
time.read_ticks:
	xorq %rax, %rax
	rdtsc
	shl $32, %rdx
	orq %rdx, %rax
	ret
