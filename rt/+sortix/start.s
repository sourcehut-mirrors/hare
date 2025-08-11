.text
.globl main
.type main, @function
.extern rt.main
main:
	jmp rt.main
