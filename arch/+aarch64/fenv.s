# This file is vendored from musl and is licensed under MIT license:
#
# ----------------------------------------------------------------------
# Copyright © 2005-2020 Rich Felker, et al.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ----------------------------------------------------------------------

.section ".text.arch.fegetround","ax"
.global arch.fegetround
.type arch.fegetround,%function
arch.fegetround:
	mrs x0, fpcr
	and w0, w0, #0xc00000
	ret

.section ".text.arch.fesetround","ax"
.global arch.fesetround
.type arch.fesetround,%function
arch.fesetround:
	mrs x1, fpcr
	bic w1, w1, #0xc00000
	orr w1, w1, w0
	msr fpcr, x1
	mov w0, #0
	ret

.section ".text.arch.fetestexcept","ax"
.global arch.fetestexcept
.type arch.fetestexcept,%function
arch.fetestexcept:
	and w0, w0, #0x1f
	mrs x1, fpsr
	and w0, w0, w1
	ret

.section ".text.arch.feclearexcept","ax"
.global arch.feclearexcept
.type arch.feclearexcept,%function
arch.feclearexcept:
	and w0, w0, #0x1f
	mrs x1, fpsr
	bic w1, w1, w0
	msr fpsr, x1
	mov w0, #0
	ret

.section ".text.arch.feraiseexcept","ax"
.global arch.feraiseexcept
.type arch.feraiseexcept,%function
arch.feraiseexcept:
	and w0, w0, #0x1f
	mrs x1, fpsr
	orr w1, w1, w0
	msr fpsr, x1
	mov w0, #0
	ret

.section ".text.arch.fegetenv","ax"
.global arch.fegetenv
.type arch.fegetenv,%function
arch.fegetenv:
	mrs x1, fpcr
	mrs x2, fpsr
	stp w1, w2, [x0]
	mov w0, #0
	ret

// TODO preserve some bits
.section ".text.arch.fesetenv","ax"
.global arch.fesetenv
.type arch.fesetenv,%function
arch.fesetenv:
	mov x1, #0
	mov x2, #0
	cmn x0, #1
	b.eq 1f
	ldp w1, w2, [x0]
1:	msr fpcr, x1
	msr fpsr, x2
	mov w0, #0
	ret
