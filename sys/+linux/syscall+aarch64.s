.section .text.sys.syscall0
.global sys.syscall0
sys.syscall0:
	mov x8, x0
	svc 0
	ret

.section .text.sys.syscall1
.global sys.syscall1
sys.syscall1:
	mov x8, x0
	mov x0, x1
	svc 0
	ret

.section .text.sys.syscall2
.global sys.syscall2
sys.syscall2:
	mov x8, x0
	mov x0, x1
	mov x1, x2
	svc 0
	ret

.section .text.sys.syscall3
.global sys.syscall3
sys.syscall3:
	mov x8, x0
	mov x0, x1
	mov x1, x2
	mov x2, x3
	svc 0
	ret

.section .text.sys.syscall4
.global sys.syscall4
sys.syscall4:
	mov x8, x0
	mov x0, x1
	mov x1, x2
	mov x2, x3
	mov x3, x4
	svc 0
	ret

.section .text.sys.syscall5
.global sys.syscall5
sys.syscall5:
	mov x8, x0
	mov x0, x1
	mov x1, x2
	mov x2, x3
	mov x3, x4
	mov x4, x5
	svc 0
	ret

.section .text.sys.syscall6
.global sys.syscall6
sys.syscall6:
	mov x8, x0
	mov x0, x1
	mov x1, x2
	mov x2, x3
	mov x3, x4
	mov x4, x5
	mov x5, x6
	svc 0
	ret
