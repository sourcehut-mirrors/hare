.section ".text.arch.cpuid_getvendorstr","ax"
.global arch.cpuid_getvendorstr
.type arch.cpuid_getvendorstr,@function
arch.cpuid_getvendorstr:
	pushq %rdx
	pushq %rcx
	pushq %rbx

	cpuid
	movl %ebx, (%rdi)
	movl %edx, 4(%rdi)
	movl %ecx, 8(%rdi)

	popq %rbx
	popq %rcx
	popq %rdx
	ret

.section ".text.arch.cpuid_getfeatureflags","ax"
.global arch.cpuid_getfeatureflags
.type arch.cpuid_getfeatureflags,@function
arch.cpuid_getfeatureflags:

	pushq %rdx
	pushq %rcx
	pushq %rbx

	movl $1, %eax
	cpuid

	movq %rdi, -0x8(%rsp)
	movq -0x8(%rsp), %rax
	movl %edx, (%rax)

	movq -0x8(%rsp), %rax
	add $0x4, %rax
	movl %ecx, (%rax)

	popq %rbx
	popq %rcx
	popq %rdx
	ret

