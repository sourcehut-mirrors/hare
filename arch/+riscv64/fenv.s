.section ".text.arch.feclearexcept","ax"
.global arch.feclearexcept
.type arch.feclearexcept,@function
arch.feclearexcept:
	and a0, a0, 0x1f
	# fflags = fflags & ~a0
	frcsr t0
	not a0, a0
	and t0, t0, a0
	fscsr t0
	ret

.section ".text.arch.feraiseexcept","ax"
.global arch.feraiseexcept
.type arch.feraiseexcept,@function
arch.feraiseexcept:
	and a0, a0, 0x1f
	# fflags = fflags | a0
	frcsr t0
	or t0, t0, a0
	fscsr t0
	ret

.section ".text.arch.fesetround","ax"
.global arch.fesetround
.type arch.fesetround,@function
arch.fesetround:
	fsrm a0
	ret

.section ".text.arch.fegetround","ax"
.global arch.fegetround
.type arch.fegetround,@function
arch.fegetround:
	frrm a0
	ret

.section ".text.arch.fetestexcept","ax"
.global arch.fetestexcept
.type arch.fetestexcept,@function
arch.fetestexcept:
	and a0, a0, 0x1f
	frcsr t0
	and a0, a0, t0
	ret
