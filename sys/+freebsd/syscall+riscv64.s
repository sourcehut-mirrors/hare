.section .text.sys.syscall0
.global sys.syscall0
sys.syscall0:
	mv a7, a0
	ecall
	ret

.section .text.sys.syscall1
.global sys.syscall1
sys.syscall1:
	mv a7, a0
	mv a0, a1
	ecall
	ret

.section .text.sys.syscall2
.global sys.syscall2
sys.syscall2:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	ecall
	ret

.section .text.sys.syscall3
.global sys.syscall3
sys.syscall3:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	ecall
	ret

.section .text.sys.syscall4
.global sys.syscall4
sys.syscall4:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	mv a3, a4
	ecall
	ret

.section .text.sys.syscall5
.global sys.syscall5
sys.syscall5:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	mv a3, a4
	mv a4, a5
	ecall
	ret

.section .text.sys.syscall6
.global sys.syscall6
sys.syscall6:
	mv a7, a0
	mv a0, a1
	mv a1, a2
	mv a2, a3
	mv a3, a4
	mv a4, a5
	mv a5, a6
	ecall
	ret
