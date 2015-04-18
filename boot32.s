###
# boot32.s:
#     Something tells me we're not in Kansas any more, Toto...
#     We should now be in a 32-bit segment with the processor in protected mode
#     so now we need to be more careful about what we do -- we can't walk on the grass
#     any more, for instance.
#     We can, however, now access the big memory segment in order to copy the main code
#     there and jump to it -- hopefully without causing any exceptions!
###

.code32
#.section ".text32","ax"

boot32:
	#
	# Load the Interrupt Descriptor Table
	# This will help if we screw something up and cause an exception.
	# What are the chances of that happening!?!
	#

	#
	# Fix up the other segment registers so that they contain the selector for
	# our cosy little 64KB segment's data descriptor
	# (CS should contain the selector for our 64KB segment's code descriptor)
	#
	movw	$GDT_DESC_DATA64KB,%ax		# Index 2, GDT, RPL 0
	movw	%ax,%ds
	movw	%ax,%ss

	#
	# ES segment register will be used as the destination for our copy
	# so this needs to be set to the big segment data descriptor
	#
	movw	$GDT_DESC_DATABIG,%ax		# Index 4, GDT, RPL 0
	movw	%ax,%es

	#
	# We don't use FS nor GS, so set them to the null descriptor
	#
	xorw	%ax,%ax
	movw	%ax,%fs
	movw	%ax,%gs

	#
	# Now that we have the segment registers set up with valid (or null) selectors,
	# let's get the Interrupt Descriptor Table set up in case we generate an exception
	# (which, let's face it, is reasonably likely)
	# It will also allow us to use 'int 3' to let us know we are reaching a certain 
	# point and what values the registes contain when we get there
	#
	lidt	idtr

	# test int 03 handler
	#movl	$0x01234567,%eax
	#movl	$0x12345678,%ebx
	#movl	$0x23456789,%ecx
	#movl	$0x3456789a,%edx
	#movl	$0x456789ab,%esi
	#movl	$0x56789abc,%edi
	#movl	$0x6789abcd,%ebp
	#int	$0x03

	#
	# Start copying ourselves. We'll go to offset 0x100 so that all the assembler
	# calculated offsets can be used without modification at runtime
	#
	movl	$_start,%esi
	movl	%esi,%edi
	movl	$(end - _start),%ecx
	shr	$0x02,%ecx			# convert num of bytes to num 4 byte words
	inc	%ecx				# inc just in case num of bytes wasn't 4n
	rep	movsl

	#
	# Change segment registers to big memory segment
	# (FS and GS are unused and already set to null descriptor)
	# We'll leave the stack segment where it is (our 64KB segment 
	# where DOS loaded us), otherwise we have to find somewhere
	# to locate the stack in our big segment!
	# Although we really ought to move it. If we don't need more 
	# than 256 bytes of stack space, we could move it to 0xfe, 
	# which is where the PSP was, as that won't be required in 
	# our big segment. 256 bytes is probably a bit small but!
	#

	movw	%es,%ax
	movw	%ax,%ds

	#
	# Relocate IRQs to ints 0x20 - 0x27, and 0x28 - 0x2f
	# so that they are out of the way of the processor
	# exception interrupts.
	# (note that this requires initing the PICs which will
	#  reset the mask register. Hence all interrupts are
	#  unmasked, which is ok, as we were going to do that
	#  next anyway!)
	#
	call	i8259_move_irqs_pm

	#
	# mask all interrupts except timer interrupt
	# (parameter passed in register as it is called from both
	#  32-bit and 16-bit code!)
	#
	movw	$0xfffa,%ax				# IRQ2 (slave) and IRQ0 (timer)
	call	i8259_set_imr

	# cross your fingers
	sti

	#
	# call far GDT_DESC_CODEREAL:main
	#

	.byte	0x9a
	.long	main
	.short	GDT_DESC_CODEBIG
	#lcall	$GDT_DESC_CODEBIG,$main

	#
	# jmp far GDT_DESC_CODEREAL:_exit
	#

	.byte	0xea
	.long	_exit
	.short	GDT_DESC_CODEREAL
