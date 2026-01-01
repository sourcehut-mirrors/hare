.text
.set SYS_log,		0
.set SYS_schedule,	1
.set SYS_cpu_stat,	2
.set SYS_ident,		3
.set SYS_signal,	4
.set SYS_wait,		5
.set SYS_call,		6
.set SYS_recv,		7
.set SYS_reply,		8
.set SYS_recvcap,	9
.set SYS_poll,		10
.set REPLY_FLAG_REPLY_TO, 1 << 18

.global sys_log
sys_log:
	mov $SYS_log, %rax
	syscall
	ret

.global sys_schedule
sys_schedule:
	mov $SYS_schedule, %rax
	syscall
	ret

.global sys_cpu_stat
sys_cpu_stat:
	mov $SYS_cpu_stat, %rax
	syscall
	ret

.global sys_ident
sys_ident:
	mov $SYS_ident, %rax
	syscall
	ret

.global sys_signal
sys_signal:
	mov $SYS_signal, %rax
	syscall
	ret

.global sys_wait
sys_wait:
	mov $SYS_wait, %rax
	syscall
	ret

.global sys_call
sys_call:
	/* TODO: Flags */
	mov $SYS_call, %rax
	mov %rcx, %r10
	syscall
	ret

.global sys_recvcap
sys_recvcap:
	mov $SYS_recvcap, %rax
	syscall
	ret

.global sys_poll
sys_poll:
	mov $SYS_poll, %rax
	syscall
	ret

.global sys_reply
sys_reply:
	movq %rcx, %rax
	shlq $8, %rax
	movb $SYS_reply, %al
	syscall
	ret
