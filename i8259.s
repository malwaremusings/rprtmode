	.equ	i8259_ICW1,$0x11
	.equ	i8259_ICW2m,$0x20	# Map IRQs 0 - 7 to ints 0x20 - 0x27
	.equ	i8259_ICW2s,$0x28	# Map IRQs 8 - 15 to ints 0x28 - 0x2f
	.equ	i8259_ICW3m,$0x04	# IRQ2 is connected to slave
	.equ	i8259_ICW3s,$0x02	# Slave's INT line is connected to IRQ2 on master
	.equ	i8259_ICW4,$0x01

	.equ	i8259_OCW3_Read_IRR,$0x0a	# 0:		0
						# ESMM,SMM:	00 (Nop)
						# 0:		0
						# 1:		1
						# P:		0 (no polling)
						# RR:		1 (read register)
						# RIS:		0 (IRR)
	.equ	i8259_OCW3_Read_ISR,$0x0b	# RR:		1 (read register)
						# RIS:		1 (ISR)

	.equ	i8259_OCW2_EoI,$0x20	# 001:	non-specific EoI
					# 0:	0
					# 0:	0
					# 000:	L2 L1 L0 (IRQ# ignored if non-specific)


.code32

i8259_init:
	push	%eax

	movb	$0x11,%al		# 0x11
	outb	%al,$0x20
	outb	%al,$0xa0

	movb	$0x20,%al		# 0x20 (IRQs 0 - 7 to ints 0x20 - 0x27)
	outb	%al,$0x21
	movb	$0x28,%al		# 0x28 (IRQs 8 - 15 to ints 0x28 - 0x2f)
	outb	%al,$0xa1

	movb	$0x04,%al		# 0x04 (IRQ2 is connected to slave)
	outb	%al,$0x21
	movb	$0x02,%al		# 0x02: Slave's INT line is connected to IRQ2 on master
	outb	%al,$0xa1

	movb	$0x01,%al		# 0x01: 8086/8088 mode
	outb	%al,$0x21
	outb	%al,$0xa1

	pop	%eax
	ret


i8259_move_irqs_pm:
	push	%eax

	# ICW1
	movb	$0x11,%al
	outb	%al,$0x20
	outb	%al,$0xa0

	# ICW2: route IRQs 0 - 7 to ints 0x20 - 0x27
	movb	$0x20,%al
	outb	%al,$0x21
	#	route IRQs 8 - 15 to to ints 0x28 - 0x2f
	addb	$0x08,%al
	outb	%al,$0xa1

	# ICW3
	movb	$0x04,%al
	outb	%al,$0x21
	movb	$0x02,%al
	outb	%al,$0xa1

	# ICW4
	movb	$0x01,%al
	outb	%al,$0x21
	outb	%al,$0xa1

	pop	%eax
	ret

i8259_move_irqs_rm:
	push	%eax

	# ICW1
	movb	$0x11,%al
	outb	%al,$0x20
	outb	%al,$0xa0

	# ICW2: route IRQs 0 - 7 to ints 0x08 - 0x0f
	movb	$0x08,%al
	outb	%al,$0x21
	#	route IRQs 8 - 15 to to ints 0x70 - 0x77
	addb	$0x70,%al
	outb	%al,$0xa1

	# ICW3
	movb	$0x04,%al
	outb	%al,$0x21
	movb	$0x02,%al
	outb	%al,$0xa1

	# ICW4
	movb	$0x01,%al
	outb	%al,$0x21
	outb	%al,$0xa1

	pop	%eax
	ret


###
# i8259_get_imr: Return the current Interrupt Mask Register
#		 %ah: IMR from slave PIC
#		 %al: IMR from master PIC
###
i8259_get_imr:
	xor	%eax,%eax
	inb	$0xa1,%al
	shl	$0x08,%eax		# can only read bytes in to %al
	inb	$0x21,%al

	ret


###
# i8259_set_imr: Set the Interrupt Mask Register
#		 %ah: mask register for slave PIC
#		 %al: mask register for master PIC
###
i8259_set_imr:
	xchg	%ah,%al			# can only output bytes from %al
	outb	%al,$0xa1
	xchg	%ah,%al
	outb	%al,$0x21

	ret


###
# i8259_get_irr: Get the current Interrupt Request Register
#		 %ah: IRR for slave
#		 %al: IRR for master
###
i8259_get_irr:
	xor	%eax,%eax
	movb	$0x0a,%al			# i8259_OCW3_Read_IRR
	outb	%al,$0xa0
	outb	%al,$0x20
	inb	$0xa0,%al
	shl	$0x08,%eax
	inb	$0x20,%al

	ret


###
# i8259_get_isr: Get the current Interrupt Service Register
#		 %ah: ISR for slave
#		 %al: ISR for master
###
i8259_get_isr:
	xor	%eax,%eax
	movb	$0x0b,%al			# i8259_OCW3_Read_ISR
	outb	%al,$0xa0
	outb	%al,$0x20
	inb	$0xa0,%al
	shl	$0x08,%eax
	inb	$0x20,%al

	ret


###
# eoi: Signal End-of-Interrupt
###
i8259_eoi:
	push	%eax

	movb	$0x20,%al
	outb	%al,$0x20

	pop	%eax
	ret
