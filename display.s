.code32

debug:
	push	%es
	push	%esi
	push	%edi
	push	%eax

	#
	# Set up our destination segment selector
	# Index 3: Display RAM
	#
	movw	$GDT_DESC_DATADISPRAM,%ax
	movw	%ax,%es

	mov	$(79 * 2),%edi			# col 79 row 25
	movb	$0x0c,%ah			# bright red
	movb	dbgchar,%al
	#movb	$0x30,%al
	stosw
	incb	dbgchar
	cmpb	$0x80,dbgchar
	jb	charok
	movb	$0x20,dbgchar
charok:

	pop	%eax
	pop	%edi
	pop	%esi
	pop	%es

	ret
dbgchar:
	.byte	0x30


display_putchar:
	push	%ebp
	mov	%esp,%ebp

	push	%es
	push	%eax
	push	%ebx
	push	%ecx
	push	%edx
	push	%edi

	#
	# Set up our destination segment selector
	# Index 3: Display RAM
	#
	movw	$GDT_DESC_DATADISPRAM,%ax
	movw	%ax,%es

	mov	$0x02,%ah			# green
	mov	0x08(%ebp),%al
	movzxw	row,%edi			# row
	mov	%edi,%ebx
	mov	%edi,%edx
	shl	$0x6,%edi			# mul by 64
	shl	$0x4,%edx			# mul by 16
	add	%edx,%edi			# and add == mul by 80
	shl	$0x1,%edi			# mul by 2 (two bytes per char)
	movzxw	col,%ecx			# col

	cmp	$0x0a,%al
	je	putchar_lf
	es mov	%ax,(%edi,%ecx,2)
	inc	%ecx
	cmp	$0x50,%ecx			# are we at col 80?
	jl	samerow
putchar_lf:
	xor	%ecx,%ecx
	incw	%bx
	cmpw	$0x1a,%bx			# are we at row 26?
	jl	onscreen
	xor	%ebx,%ebx
onscreen:
samerow:
	movw	%bx,row
	movw	%cx,col

	pop	%edi
	pop	%edx
	pop	%ecx
	pop	%ebx
	pop	%eax
	pop	%es

	mov	%ebp,%esp
	pop	%ebp
	ret


###
# setloc: set the current printing position
#	  ah: row
#	  al: column
###
display_setloc:
	push	%ebp
	mov	%esp,%ebp

	push	%eax

	mov	0x08(%ebp),%eax
	movb	%ah,row
	movb	%al,col

	pop	%eax

	mov	%ebp,%esp
	pop	%ebp
	ret


###
# getloc: return the current printing position
#	  ah: row
#	  al: column
###
display_getloc:
	xor	%eax,%eax
	movb	row,%ah
	movb	col,%al

	ret


display_dumpword:
	push	%eax
	push	%ebx
	push	%ecx
	push	%edx

	mov	$0x04,%ecx
	mov	0x14(%esp),%ebx
nextnibble:
	rolw	$0x4,%bx
	movb	%bl,%dl
	andb	$0x0f,%dl
	addb	$0x30,%dl

	cmpb	$0x39,%dl
	jbe	printable
	addb	$0x27,%dl
printable:
	push	%edx
	call	display_putchar
	add	$0x4,%esp
	loop	nextnibble

	pop	%edx
	pop	%ecx
	pop	%ebx
	pop	%eax

	ret


dumplword:
	push	%eax

	mov	0x08(%esp),%eax
	ror	$0x10,%eax
	push	%eax
	call	display_dumpword
	add	$0x04,%esp

	rol	$0x10,%eax
	push	%eax
	call	display_dumpword
	add	$0x04,%esp

	pop	%eax
	ret


###
# dumpbits: Print the individual bits
#	    arg0: data to print
#	    arg1: number of bits
###
display_dumpbits:
	push	%ebp
	mov	%esp,%ebp

	push	%eax
	push	%ecx
	push	%edx

	ss mov	0x08(%ebp),%eax
	ss mov	0x0c(%ebp),%ecx

        #
        # Loop through and print the individual bits
        #
nextbit:
        xor     %edx,%edx
	dec	%ecx				# change %ecx to be bit number
        bt      %ecx,%eax
        setc    %dl
        add     $0x30,%dl
        push    %edx
        call    display_putchar
        add     $0x04,%esp
	inc	%ecx				# put %ecx back to loop control var
        loop    nextbit

	pop	%edx
	pop	%ecx
	pop	%eax

	mov	%ebp,%esp
	pop	%ebp
	ret


display_dumpstr:
	push	%ebp
	mov	%esp,%ebp

	push	%esi
	push	%eax

	mov	0x08(%ebp),%esi
nxtchr:
	lodsb
	test	%al,%al
	jz	eos
	push	%eax
	call	display_putchar
	add	$0x04,%esp
	jmp	nxtchr
eos:
	pop	%eax
	pop	%esi

	mov	%ebp,%esp
	pop	%ebp
	ret


clear:
	push	%es
	push	%eax
	push	%ecx
	push	%edi

	#
	# Set up our destination segment selector
	# Index 3: Display RAM
	#
	movw	$GDT_DESC_DATADISPRAM,%ax
	movw	%ax,%es

	movw	$0x0720,%ax
	xor	%edi,%edi
	mov	$0x7d0,%ecx
	rep	stosw

	xorw	%ax,%ax
	movw	%ax,col
	movw	%ax,row

	pop	%edi
	pop	%ecx
	pop	%eax
	pop	%es
	ret


col:	.hword	0x0000
row:	.hword	0x0000
