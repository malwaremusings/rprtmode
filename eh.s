.code32

dumpregs:
	push	%ebp
	mov	%esp,%ebp

	push	%ebx
	push	%ecx
	push	%esi

	movl	0x08(%ebp),%ebx
	lea	regs,%esi
	mov	$0x0d,%ecx
nxtreg:
	push	%esi
	call	display_dumpstr
	add	$0x04,%esp

	ss push	-0x04(%ebx,%ecx,4)		# Downside of not using same SS as DS
						# This means arg must be addr on stack
	call	dumplword
	add	$0x04,%esp

	push	$0x0000000a
	call	display_putchar
	add	$0x04,%esp

	add	$0x09,%esi
	loop	nxtreg

	mov	%ebp,%esp
	pop	%ebp
	ret


exception_handler:
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

	movw	$GDT_DESC_DATADISPRAM,%ax
	movw	%ax,%es

	#call	clear

	lea	exception_header,%edx
	push	%edx
	call	display_dumpstr
	add	$0x04,%esp

	lea	exception_names,%ebx
	ss mov	56(%ebp),%eax
	and	$0x0000ffff,%eax
	lea	(%ebx,%eax,4),%esi
	push	%esi
	call	display_dumpstr
	add	$0x04,%esp

	lea	exception_header2,%edx
	push	%edx
	call	display_dumpstr
	add	$0x04,%esp

	lea	60(%ebp),%ebx			# assume return address is here, ie. no error code
	testl	$0x80000000,56(%ebp)
	jz	noerrtoprint

	lea	64(%ebp),%ebx			# unless there is an error code on stack
	ss push	60(%ebp)			# error code on stack
	call	dumplword
	add	$0x04,%esp

noerrtoprint:
	movl	$0x0a,%eax
	push	%eax
	call	display_putchar
	add	$0x04,%esp

	lea	exception_addr,%edx
	push	%edx
	call	display_dumpstr
	add	$0x04,%esp

	ss push	0x04(%ebx)			# cs
	call	dumplword
	add	$0x04,%esp

	movl	$0x3a,%eax
	push	%eax
	call	display_putchar
	add	$0x04,%esp

	ss push	(%ebx)				# eip
	call	dumplword
	add	$0x04,%esp

	movl	$0x0a,%eax
	push	%eax
	call	display_putchar
	add	$0x4,%esp

	lea	0x04(%ebp),%ebx
	push	%ebx
	call	dumpregs

	mov	%ebp,%esp
	pop	%ebp
stop:	jmp	stop

	add	$0x14,%esp			# discard cr0 and the four seg regs
	pop	%ebp
	pop	%edi
	pop	%esi
	pop	%edx
	pop	%ecx
	pop	%ebx
	pop	%eax
	pop	%esp
	testl	$0x80000000,(%esp)
	jz	noerr
	add	$0x04,%esp			# discard error code
noerr:
	add	$0x04,%esp			# discard our int number
	#
	# figure out how to terminate
	#
	push	%eax
	movl	$GDT_DESC_CODEREAL,%eax
	mov	%eax,0x08(%esp)
	lea	_exit,%eax
	mov	%eax,0x04(%esp)
	pop	%eax

	iret


brkpt_header:
	.ascii	"\n------------- BREAKPOINT -------------\n"
	.asciz	"Breakpoint addr: "
exception_header:
	.asciz	"\n============= EXCEPTION: "
exception_header2:
	.ascii	" =============\n"
	.asciz	"Error code: "
exception_addr:
	.asciz	"Exception addr: "
regs:
	.asciz	"%esp: 0x"
	.asciz	"%eax: 0x"
	.asciz	"%ebx: 0x"
	.asciz	"%ecx: 0x"
	.asciz	"%edx: 0x"
	.asciz	"%esi: 0x"
	.asciz	"%edi: 0x"
	.asciz	"%ebp: 0x"
	.asciz	"%ds : 0x"
	.asciz	"%es : 0x"
	.asciz	"%fs : 0x"
	.asciz	"%gs : 0x"
	.asciz	"%cr0: 0x"
exception_names:
	.asciz	"#DE"
	.asciz	"#DB"
	.asciz	"NMI"
	.asciz	"#BP"
	.asciz	"#OF"
	.asciz	"#BR"
	.asciz	"#UD"
	.asciz	"#NM"
	.asciz	"#DF"
	.asciz	"CSO"
	.asciz	"#TS"
	.asciz	"#NP"
	.asciz	"#SS"
	.asciz	"#GP"
	.asciz	"#PF"
	.asciz	"#0f"
	.asciz	"#MF"
	.asciz	"#AC"
	.asciz	"#MC"
	.asciz	"#XM"
	.asciz	"IR0"
	.asciz	"IR1"
	.asciz	"IR2"
	.asciz	"IR3"
	.asciz	"IR4"
	.asciz	"IR5"
	.asciz	"IR6"
	.asciz	"IR7"
