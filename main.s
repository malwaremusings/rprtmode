.code32
.include	"protmode.h"

main:
	call	clear

	lea	num5,%eax
	push	%eax
	call	display_dumpstr
	add	$0x4,%esp

	#push	$0x08
	#push	$0x67
	#call	display_dumpbits
	#add	$0x08,%esp

	#call	debug

idle:
	xor	%eax,%eax
	movw	$GDT_DESC_LDT0,%ax
	lldt	%ax

	#
	# Set the current task to be task0
	# This specifies the TSS segment where the processor will save 
	# the state of the current task on a task switch
	#
	movw	$GDT_DESC_TSS0,%ax
	ltr	%ax
	movw	%ax,currtask

	mov	$0x0000000c,%eax
	#ljmp	$0x0058,$0x00000058
	jmp	task

	ret


msg:
	.ascii	"Goodbye world!\r\n$"	# our dear string
msghello:
	.ascii	"Hello world!\r\n$"

num5:	.asciz	"Number 5 is alive!\n"
