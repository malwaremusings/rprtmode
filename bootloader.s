###
# bootloader.s:
#     Load ourselves from disk
###

.text		# section declaration
.code16		# code section with 16-bit operands

	jmp	__code


#
# BIOS Parameter Block
#

.org	0x000b
sectsize:	.short	0x0200		/* bytes per logical sector */
clustsize:	.byte	0x01		/* logical sectors per cluster */
numres:		.short	0x0001		/* reserved logical sectors */
numfats:	.byte	0x02		/* number of FATs */
rootdirnum:	.word	0x00e0		/* root directory entries */
totalsects:	.word	0x0b40		/* total logical sectors */
mediadesc:	.byte	0xf0		/* media descriptor byte */
fatsize:	.word	0x0009		/* logical sectors per FAT */

tracksize:	.word	0x0012		/* physical sectors per track */
numheads:	.word	0x0002		/* number of heads */
hiddensects:	.long	0x0000		/* hidden sectors */
lgetotalsects:	.long	0x0000		/* large total logical sectors */

phydrivenum:	.byte	0x00		/* physical drive number */
flags:		.byte	0x00		/* flags etc. */
extbootsig:	.byte	0x29		/* extended boot signature (0x29 == MS-DOS 4.1)
volsernum:	.long	0x10cbaab0	/* volume serial number */
vollabel:	.ascii	"DOSSYWOSSY0"	/* volume label */
fstype:		.ascii	"FAT12   "	/* file system type */


#
# Boot code
#

__code:
	push	%cs
	pop	%ds

	push	%cs
	pop	%ss
	mov	$0xfffe,%sp

	push	$welcome
	call	dispstr

	#
	# load first sector of root directory
	#

	xor	%dx,%dx
	mov	tracksize,%ax
	mov	numheads,%bx
	mul	%bx
	xor	%dx,%dx

	# %ax == number sectors per cylinder
	mov	%ax,%bx

	mov	fatsize,%ax
	xor	%ch,%ch
	mov	numfats,%cl
	mul	%cx
	add	numres,%ax

	#
	# load the 1st sector of the root directory
	#

	mov	$0x0070,%bx
	mov	%bx,%es
	xor	%bx,%bx

	push	$0001
	push	%ax
	push	%bx
	push	%es
	call	loadsects

	#push	%ax
	#div	%bx

	# %ax is cyl num
	# %dx is sector within cyl

	#mov	%al,%ch		# cyl (7:0)
	#shl	$0x6,%ah
	#mov	%ah,%cl		# cyl (9:8)

	#mov	%dx,%ax
	#xor	%dx,%dx

	#mov	tracksize,%bx
	#div	%bx

	#mov	%al,%dh		# head
	#and	$0x3f,%dl	# 6-bit sector number
	#or	%dl,%cl		# sector
	#inc	%cl		# one based, not zero based
	#xor	%dl,%dl		# drive

	#mov	$0x0201,%ax
	#mov	$0x0070,%bx
	#mov	%bx,%es
	#xor	%bx,%bx
	#int	$0x13
	cmp	$0x0001,%ax
	jne	.Lint13err


	#
	# search for file name
	#

	mov	$filename,%si
	mov	%bx,%di
    .Lnextfile:
	mov	$0x0b,%cx
	push	%si
	push	%di
    1:
	cmpsb
	loopz	1b
	pop	%di
	pop	%si
	jz	.Lfilefound

	add	$0x20,%di
	cmp	$0x1200,%di
	jb	.Lnextfile
	jmp	.Lfilenotfound

    .Lfilefound:

	mov	$okstr,%ax
    .Lstrhalt:
	push	%ax
	call	dispstr
halt:
	cli
	hlt

    .Lint13err:
	mov	$int13errstr,%ax
	jmp	.Lstrhalt

    .Lfilenotfound:
	mov	$filenotfoundstr,%ax
	jmp	.Lstrhalt
	

.ifdef DEBUG
dispworddbg:
	push	%ax
	push	%bx
	push	%cx
	push	%dx

	mov	$0x0007,%bx
	mov	$12,%cx
	mov	%ax,%dx
nextnibble:
	mov	%dx,%ax
	shr	%cl,%ax
	and	$0x0f,%al
	or	$0x30,%al

	mov	$0x0e,%ah
	int	$0x10

	sub	$0x4,%cx
	jnb	nextnibble

	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	ret
.endif
	

###
# dispstr: take near address off stack and print null terminated string
###

dispstr:
	push	%bp
	mov	%sp,%bp

	push	%ax
	push	%bx
	push	%si

	mov	0x4(%bp),%si
	mov	$0x0e,%ah
	mov	$0x0007,%bx

    .Lnxtchar:
	lodsb
	test	%al,%al
	jz	.Leos
	int	$0x10
	jmp	.Lnxtchar

    .Leos:
	pop	%si
	pop	%bx
	pop	%ax

	mov	%bp,%sp
	pop	%bp
	ret	$2


.if 0
###
# dispword:
###

dispword:
	push	%bp
	mov	%sp,%bp
	sub	$0x6,%sp

	push	%ax
	push	%cx
	push	%dx
	push	%di
	push	%es

	push	%cs
	pop	%es

	mov	0x04(%bp),%dx
	lea	(-0x6 + 0x3)(%bp),%di

	mov	$0x04,%cx
	pushf
	std
    .Lnxtnibble:
	mov	%dx,%ax
	and	$0x0f,%ax
	cmp	$0x0a,%ax
	jb	.Lnotletter
	add	$0x27,%ax
    .Lnotletter:
	add	$0x30,%ax
	stosb
	shr	$0x4,%dx
	loop	.Lnxtnibble
	popf

	xor	%ah,%ah
	movb	%ah,(-0x6 + 0x4)(%bp)
	inc	%di

	push	%di
	call	dispstr

	pop	%es
	pop	%di
	pop	%dx
	pop	%cx
	pop	%ax

	add	$0x6,%sp
	mov	%bp,%sp
	pop	%bp
	ret	$2
.endif

###
# loadsects: load contiguous sectors from disk
#     loadsects(void *buffseg,void *buffoff,int startsect,int count)
###

loadsects:
	push	%bp
	mov	%sp,%bp
	sub	$0x6,%sp

	push	%bx
	push	%cx
	push	%dx
	push	%es

	#
	# get sectors per cylinder
	#   (tracksize * numheads)
	#

	xor	%dx,%dx
	mov	tracksize,%ax
	mulw	numheads

	#
	# divide by sec per cyl
	#

	mov	%ax,%bx
	xor	%dx,%dx
	mov	0x8(%ebp),%ax
	div	%bx

	#
	# %ax is cyl
	# %dx is sector within cyl
	#
	and	$0x3ff,%ax
	mov	%ax,-0x02(%bp)
	mov	%ax,%cx
	xchg	%ch,%cl
	shl	$0x6,%cl

	#
	# divide sector by sectors per track
	#
	mov	%dx,%ax
	xor	%dx,%dx
	mov	tracksize,%bx
	div	%bx

	#
	# %ax is head
	# %dx is sec (zero based)
	#

	and	$0x3f,%dx
	or	%dl,%cl
	inc	%cl

	mov	%ax,-0x04(%bp)
	mov	%dx,-0x06(%bp)

	mov	%al,%dh
	mov	$0x00,%dl

	mov	$0x0201,%ax
	mov	0x04(%bp),%bx
	mov	%bx,%es
	mov	0x06(%bp),%bx

	int	$0x13

	pop	%es
	pop	%dx
	pop	%cx
	pop	%bx

	add	$0x6,%sp
	mov	%bp,%sp
	pop	%bp
	ret	$6


.section .rodata
welcome:
	.asciz	"Loading... "
okstr:
	.asciz	"Ok\r\n"
int13errstr:
	.asciz	"int 0x13 failed\r\n"
filename:
	.ascii	"PLAN    A  "
filenotfoundstr:
	.asciz	"File not found\r\n"
dbgmsg:
	.asciz	"!"
badhexstr:
	.asciz	"Bad hex character\r\n"

.section .id
	.short	0xaa55
