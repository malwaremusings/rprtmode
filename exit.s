.code16
_exit:
	#
	# prepare for real mode
	# Intel reference section 9.9.2
	#

	cli

	# load IDTR with normal int vectors
	xor	%eax,%eax
	mov	%eax,idtr + IDTR.BASE
	movw	$0x3ff,%ax
	mov	%ax,idtr + IDTR.LIMIT
	lidt	idtr

	mov	$GDT_DESC_DATAREAL,%ecx
	mov	%ecx,%ds
	mov	%ecx,%es
	mov	%ecx,%ss

	movl	%cr0,%eax
	andl	$0xfffffffe,%eax
	movl	%eax,%cr0

	.byte	0xea
	.short	text16
rmjmpcs:.short	0x0000
text16:
	movw	%cs,%cx
	movw	%cx,%ds
	movw	%cx,%es
	movw	%cx,%ss

	movw	$0xb800,%cx
	movw	%cx,%es
	movw	$0x0742,%ax
	xorw	%di,%di
	stosw

	#
	# Relocate IRQs back to ints 0x08 - 0x0f, and 0x70 - 0x77
	# (note that this requires initing the PICs which will 
	#  reset the mask register. Hence all interrupts are 
	#  unmasked, which is ok, as we were going to do that 
	#  next anyway!)
	#
	call	i8259_move_irqs_rm

	sti

	mov	$0x01,%ah
	int	$0x21

	xorw	%ax,%ax
	int	$0x21

	int	$0x20

	nop
