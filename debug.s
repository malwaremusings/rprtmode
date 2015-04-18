.code16

install_int3_handler_16:
	push	%es
	push	%ax

	xorw	%ax,%ax
	movw	%ax,%es

	movw	%cs,%ax
	es movw	%ax,(0x03 * INT_VECT_SIZE) + INT_VECT_SEG	# int 3 segment
	es movw	%ax,(0x0d * INT_VECT_SIZE) + INT_VECT_SEG	# int d (GPF) segment
	movw	$int3_handler_16,%ax
	es movw	%ax,(0x03 * INT_VECT_SIZE) + INT_VECT_OFF	# int 3 offset
	es movw	%ax,(0x0d * INT_VECT_SIZE) + INT_VECT_OFF	# int d (GPF) offset

	pop	%ax
	pop	%es
	ret
	

int3_handler_16:
	pushw	%sp
	pushw	%ax
	pushw	%bx
	pushw	%cx
	pushw	%dx
	pushw	%si
	pushw	%di
	pushw	%bp
	pushw	%ds
	pushw	%es
	pushw	%fs
	pushw	%gs

	pushw	%bp
	movw	%sp,%bp

	#
	# Print the 'Breakpoint at' string
	#
	movw	$debugloc,%dx
	movb	$0x09,%ah
	int	$0x21

	#
	# print CS register of caller
	#
	pushw	0x1c(%bp)
	call	dumpword_16
	addw	$0x02,%sp

	#
	# print a ':' character
	#
	movb	$0x3a,%dl
	movb	$0x02,%ah
	int	$0x21

	#
	# print IP register of caller
	#
	pushw	0x1a(%ebp)
	call	dumpword_16
	addw	$0x02,%sp

	#
	# print the CRLF sequence
	#
	movw	$crlf,%dx
	movb	$0x09,%ah
	int	$0x21

	#
	# dump the regs
	#
	movw	$regs_16,%dx
	movw	$0x0c,%cx
	lea	0x18(%bp),%bx
nxtreg_16:
	movb	$0x09,%ah
	int	$0x21

	pushw	(%bx)
	call	dumpword_16
	add	$0x02,%sp

	pushw	%dx
	movw	$crlf,%dx
	movb	$0x09,%ah
	int	$0x21
	popw	%dx

	add	$0x09,%dx
	sub	$0x02,%bx
	loop	nxtreg_16

	movw	%bp,%sp
	popw	%bp

	popw	%ax
	popw	%ax
	popw	%ax
	popw	%ax
	popw	%bp
	popw	%di
	popw	%si
	popw	%dx
	popw	%cx
	popw	%bx
	popw	%ax
	popw	%sp

	iret


dumpword_16:
	push	%bp
	movw	%sp,%bp

	pushw	%ax
	pushw	%bx
	pushw	%cx
	pushw	%dx

	movw	$0x04,%cx
	movw	0x04(%bp),%bx
	movb	$0x02,%ah
nextnibble_16:
	rol	$0x04,%bx
	movb	%bl,%dl
	andb	$0x0f,%dl
	addb	$0x30,%dl

	cmpb	$0x39,%dl
	jbe	printable_16
	addb	$0x27,%dl
printable_16:
	int	$0x21
	loop	nextnibble_16

	popw	%dx
	popw	%cx
	popw	%bx
	popw	%ax

	movw	%bp,%sp
	popw	%bp
	ret


debugloc:
	.ascii	"Breakpoint at $"
crlf:
	.ascii	"\r\n$"

regs_16:
	.ascii	" %sp: 0x$"
	.ascii	" %ax: 0x$"
	.ascii	" %bx: 0x$"
	.ascii	" %cx: 0x$"
	.ascii	" %dx: 0x$"
	.ascii	" %si: 0x$"
	.ascii	" %di: 0x$"
	.ascii	" %bp: 0x$"
	.ascii	" %ds: 0x$"
	.ascii	" %es: 0x$"
	.ascii	" %fs: 0x$"
	.ascii	" %gs: 0x$"
