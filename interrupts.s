.code32

###
# Processor exceptions/interrupts
###

int00_handler:
	push	$0x00000000			# 0 (no error code) xxx 0000
	jmp	exception_handler

int01_handler:
	push	$0x00000001
	jmp	exception_handler

int02_handler:
	push	$0x00000002			# 0 (no error code) xxx 0000
	jmp	exception_handler

int03_handler:
	push	%esp
	push	%eax
	push	%ebx
	push	%ecx
	push	%edx
	push	%esi
	push	%edi
	push	%ebp
	push	%ds
	push	%es
	push	%fs
	push	%gs
	mov	%cr0,%eax
	push	%eax

	push	%ebp
	mov	%esp,%ebp

	push	%eax

	lea	brkpt_header,%eax
	push	%eax
	call	display_dumpstr
	add	$0x04,%esp

	ss push	0x3c(%ebp)			# cs?
	call	dumplword
	add	$0x04,%esp

	movl	$0x3a,%eax
	push	%eax
	call	display_putchar
	add	$0x04,%esp

	ss push	0x38(%ebp)			# eip
	call	dumplword
	add	$0x04,%esp

	movl	$0x0a,%eax
	push	%eax
	call	display_putchar
	add	$0x04,%esp

	lea	0x04(%ebp),%eax
	push	%eax
	call	dumpregs
	add	$0x04,%esp

	pop	%eax

	mov	%ebp,%esp
	pop	%ebp

	add	$0x14,%esp			# discard cr0 and the four seg regs
	pop	%ebp
	pop	%edi
	pop	%esi
	pop	%edx
	pop	%ecx
	pop	%ebx
	pop	%eax
	pop	%esp

	iret

int04_handler:
	push	$0x00000004			# 0 (no error code) xxx 0000
	jmp	exception_handler

int05_handler:
	push	$0x00000005
	jmp	exception_handler

int06_handler:
	push	$0x00000006			# 0 (no error code) xxx 0000
	jmp	exception_handler

int07_handler:
	push	$0x00000007
	jmp	exception_handler

int08_handler:
	push	$0x80000008			# 0 (no error code) xxx 0000
	jmp	exception_handler

int09_handler:
	push	$0x00000009
	jmp	exception_handler

int0a_handler:
	push	$0x8000000a			# 0 (no error code) xxx 0000
	jmp	exception_handler

int0b_handler:
	push	$0x8000000b
	jmp	exception_handler

int0c_handler:
	push	$0x8000000c			# 0 (no error code) xxx 0000
	jmp	exception_handler

int0d_handler:
	push	$0x8000000d
	jmp	exception_handler

int0e_handler:
	push	$0x8000000e			# 0 (no error code) xxx 0000
	jmp	exception_handler

int0f_handler:
	push	$0x0000000f
	jmp	exception_handler

int10_handler:
	push	$0x00000010			# 0 (no error code) xxx 0000
	jmp	exception_handler

int11_handler:
	push	$0x80000011
	jmp	exception_handler

int12_handler:
	push	$0x00000012			# 0 (no error code) xxx 0000
	jmp	exception_handler

int13_handler:
	push	$0x00000013
	jmp	exception_handler


###
# Hardware interrupts
###

int20_handler:					# IRQ0 (Timer)
	push	$0x00000000
	call	irq_handler
	add	$0x04,%esp

	call	debug
	call	i8259_eoi

	push	%edx

	#
	# get selector of current task
	#
	xor	%edx,%edx
	movw	currtask,%dx

	#
	# increment it by 2 (LDT and TSS of next task) x 8 bytes per descriptor
	#
	addw	$0x10,%dx

	#
	# check to see if we have gone past task 2 (the last task)
	#
	cmpw	$GDT_DESC_TSS2,%dx
	jbe	ok
	movw	$GDT_DESC_TSS0,%dx
ok:
	movw	%dx,tssirq0
	movw	%dx,currtask

	pop	%edx
	iret
	jmp	int20_handler

int21_handler:					# IRQ1 (Keyboard)
	int	$0x03
	push	$0x00000001
	call	irq_handler
	add	$0x04,%esp
	iret

int24_handler:					# IRQ4 (Serial port)
	push	$0x00000004
	call	irq_handler
	add	$0x04,%esp
	iret


###
# irq_handler: Handle hardware interrupts
#		We'll print the current interrupt mask register
#		Then the current interrupt request register
#		Then the current interrupt service register
#		That ought to impress the chicks
###
irq_handler:
	push	%ebp
	mov	%esp,%ebp

	push	%eax

	#
	# Get the current printing position
	#
	call	display_getloc

	#
	# Set the current printing position
	#
	push	$0x00000020		# row 0, col 32
	call	display_setloc
	add	$0x04,%esp

	#
	# Get the IMR
	#
	call	i8259_get_imr

	push	$0x10
	push	%eax
	call	display_dumpbits
	add	$0x08,%esp

	#
	# Set the current printing position
	#
	push	$0x00000120		# row 1, col 32
	call	display_setloc
	add	$0x04,%esp

	#
	# Get the IRR
	#
	call	i8259_get_irr

	push	$0x10
	push	%eax
	call	display_dumpbits
	add	$0x08,%esp

	#
	# Set the current printing position
	#
	push	$0x00000220		# row 2, col 32
	call	display_setloc
	add	$0x04,%esp

	#
	# Get the ISR
	#
	call	i8259_get_isr

	push	$0x10
	push	%eax
	call	display_dumpbits
	add	$0x08,%esp

	#
	# Restore the current printing position
	#
	# %eax containing previous printing position is still on the stack
	push	%eax
	call	display_setloc
	add	$0x04,%esp

	pop	%eax

	mov	%ebp,%esp
	pop	%ebp

	#call	i8259_eoi

	ret
