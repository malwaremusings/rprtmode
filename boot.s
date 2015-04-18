###
# boot.s:
#     Bootstrap ourselves by switching to protected mode using our current 64KB 16-bit 
#     segments, copying ourselves to somewhere out the way of DOS (let's sit at the 
#     1MB mark), then switch to 32-bit mode by jumping there.
###

.text		# section declaration
.code16		# code section with 16-bit operands

.macro seg2linear seg,off,addr
	pushw	\seg
	popw	%ax

	movw	%ax,%bx
	shr	$0x0c,%bx
	movw	%bx,\addr + 0x02
	shl	$0x04,%ax
	addw	\off,%ax
	movw	%ax,\addr
.endm


.org	0x100
_start:
	jmp	__start

dumpword_r:
	push	%bp
	movw	%sp,%bp

	pushw	%ax
	pushw	%bx
	pushw	%cx
	pushw	%dx

	movw	$0x04,%cx
	movw	0x04(%bp),%bx
	movb	$0x02,%ah
nextnibble_r:
	movb	%bl,%dl
	andb	$0x0f,%dl
	addb	$0x30,%dl

	cmpb	$0x39,%dl
	jbe	printable_r
	addb	$0x27,%dl
printable_r:
	int	$0x21
	shr	$0x04,%bx
	loop	nextnibble_r

	popw	%dx
	popw	%cx
	popw	%bx
	popw	%ax

	movw	%bp,%sp
	popw	%bp
	ret

__start:
	push	%cs
	call	dumpword_r
	add	$0x02,%sp

	movb	$0x01,%ah
	int	$0x21

	#
	# Install an int 3 handler
	# This will allow us to see whether or not we are getting to a particular
	# location by running an int 3
	#
	call	install_int3_handler_16

	# realmode_switch_hook
	cli				# disable ints
	#movb	$0x80,%al
	#outb	%al,$0x70		# disable NMIs (0x80 -> port 0x70)
	#outb	%al,$0x80		# io delay

	# test A20
	xor	%eax,%eax
	movw	%ax,%fs
	movw	$0xffff,%ax
	movw	%ax,%gs

	movl	0x80 * 4,%eax
	movl	%eax,%ebx
	movl	$0x20,%ecx
loopme:
	inc	%eax
	fs movl	%eax,0x80 * 4

	outb	%al,$0x80		# io delay
	
	gs movl	(0x80 * 4) + 0x10,%edx
	xorl	%eax,%edx
	loopz	loopme

	sti

	movl	%ebx,0x80 * 4

	# %edx is whether or not a20 ok

	test	%edx,%edx
	jz	disabled
	movw	$en,%dx
	jmp	print
disabled:
	movw	$di,%dx
print:
	movb	$0x09,%ah
	int	$0x21

	#
	# Calculate the 32-bit logical address of the start of our current segment
	#
	xor	%eax,%eax
	movw	%cs,%ax
	movw	%ax,rmjmpcs
	shl	$0x4,%eax

	#
	# Add the logical address of our base on to the offset of the GDT stored 
	# by the assembler
	# The GDTR limit is populated by the assembler.
	#
	add	%eax,gdtr_boot + GDTR.BASE
	add	%eax,idtr + IDTR.BASE
	addw	%ax,ldt0off + GDT_ENTRY.BASE0
	addw	%ax,ldt1off + GDT_ENTRY.BASE0
	addw	%ax,ldt2off + GDT_ENTRY.BASE0

	#
	# Fix up the base addresses in the GDT to correspond with the segment at which
	# DOS loaded us.
	# This should give us the following GDT entries:
	#	0: Null selector
	#	1: the 64KB code segment at which DOS loaded us
	#	2: the 64KB data segment at which DOS loaded us
	#	3: All of memory from 1MB as data (so we can copy the main code)
	#	4: All of memory from 1MB as code (so we can jump to it)
	#
	movw	%ax,gdt_boot + (1 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE0
	movw	%ax,gdt_boot + (2 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE0
	movw	%ax,gdt_boot + (3 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE0
	movw	%ax,gdt_boot + (4 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE0
	ror	$0x10,%eax

	# ... and now the third byte
	movb	%al,gdt_boot + (1 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE16
	movb	%al,gdt_boot + (2 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE16
	movb	%al,gdt_boot + (3 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE16
	movb	%al,gdt_boot + (4 * GDT_ENTRY_SIZE) + GDT_ENTRY.BASE16
	addb	%al,ldt0off + GDT_ENTRY.BASE16
	addb	%al,ldt1off + GDT_ENTRY.BASE16
	addb	%al,ldt2off + GDT_ENTRY.BASE16

	#
	# Load the Global Descriptor Table Register with the data at gdtr_boot
	#
	lgdt	gdtr_boot

	#
	# Tell the PICs that we're not interested in any hardware interrupts
	#
	movw	$0xfffb,%ax			# all ints on slave, all but IRQ2 on master
	call	i8259_set_imr

	#
	# Disable interrupts
	#
	cli

	#
	# Switch the processor in to protected mode by setting bit 0 of CR0.
	#
	movl	%cr0,%eax
	orb	$0x01,%al
	movl	%eax,%cr0

	#
	# far jmp to our 32-bit code in order to load CS with a valid protected mode
	# selector, instead of our real mode memory segment address.
	# See you on the other side (boot32.s)...
	# ... hopefully!
	#
	.byte	0x66,0xea			# far jump
	.long	boot32				# this will get base addr added to it
	.short	GDT_DESC_CODE64KB		# idx: 1, table: 0, rpl: 00
