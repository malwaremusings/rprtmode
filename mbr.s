###
# mbr.s:
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
	#mov	%ax,%bx

	mov	fatsize,%ax
	xor	%ch,%ch
	mov	numfats,%cl
	mul	%cx
	add	numres,%ax

	#
	# %ax is 1st sector of root directory
	#

	movw	%ax,%cx			# first sect of root dir
	xor	%dx,%dx
	movw	rootdirnum,%ax
	shl	$0x5,%ax
	divw	sectsize

	# %ax is number of sectors for root directory

	movw	%ax,rootdirsects
	push	%ax			# num of sects param to loadsects()
	addw	%cx,%ax

	# %ax is first file data sector

	movw	%ax,firstfiledatasect

	#
	# load the 1st sector of the root directory
	#

	mov	$0x0070,%bx
	mov	%bx,%es
	xor	%bx,%bx

	#push	rootdirsects		# pushed above
	push	%cx
	push	%bx
	push	%es
	call	loadsects

	test	%ax,%ax
	jne	.Lfileloaderr

	#
	# search for file name
	#

	mov	$filename,%si
	mov	%bx,%di
	movw	rootdirsects,%ax
	mulw	sectsize
	movw	%ax,%bx
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
	cmp	%bx,%di
	jb	.Lnextfile
	jmp	.Lfilenotfound

    .Lfilefound:
	mov	$okstr,%ax
	push	%ax
	call	dispstr

loadfile:
	# load it dear henry

	#
	# calculate number of sectors
	#

	movw	%es:0x1e(%di),%dx
	movw	%es:0x1c(%di),%ax
	divw	sectsize
	inc	%ax
	mov	%ax,%cx

	#
	# calculate starting logical sector
	#

	xor	%dx,%dx
	mov	%es:0x1a(%di),%ax

	#
	# need to increment starting logical sector by 3 for some reason
	# may be related to file area starting at cluster 2
	# the extra 1 may be logical sectors start at 1?
	#
	inc	%ax
	inc	%ax
	inc	%ax

	xor	%bx,%bx
	push	$0x0001
	push	%ax
	push	%bx
	push	%es
	call	loadsects
	test	%ax,%ax
	jne	fileloaderr
	mov	$fileloadok,%ax
        jmp	.Lstrhalt
    .Lfileloaderr:
	mov	$fileloaderr,%ax
    .Lstrhalt:
	push	%ax
	call	dispstr
	
	cli
	hlt

    .Lfilenotfound:
	movw	%di,%ax
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


.if 0
###
# loadclust: load a cluster
#     loadclust(int clustnum)
###
	push	%bp
	mov	%sp,%bp

	push	%ax
	movw	0x4(%bp),%ax
	xor	%bh,%bh
	movb	clustsize,%bl
	mul	%bx

	#
	# cluster 2 is first non-reserved logical sector
	# 
	inc	%ax
	inc	%ax
	addw	numres,%ax

	pop	%ax
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
	push	%di
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
	mov	0x06(%bp),%di
	mov	0x08(%ebp),%ax
	mov	0x0a(%ebp),%cx
    .Lnextsect:
	push	%ax
	push	%bx
	push	%cx
	xor	%dx,%dx
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
	mov	%di,%bx

	int	$0x13
	pop	%cx
	pop	%bx
	pop	%ax
	jc	.Lloadsects_fail

	push	$dot
	call	dispstr

	inc	%ax
	add	$0x200,%di
	loop	.Lnextsect

    .Lloadsects_exit:
	movw	%cx,%ax
	pop	%es
	pop	%di
	pop	%dx
	pop	%cx
	pop	%bx

	add	$0x6,%sp
	mov	%bp,%sp
	pop	%bp
	ret	$8

    .Lloadsects_fail:
	push	$fileloaderr
	call	dispstr
	jmp	.Lloadsects_exit


.section .rodata
welcome:
	.asciz	"Loading"
dot:
	.asciz	"."
okstr:
	.asciz	" Ok"
filename:
	.ascii	"PLAN    A  "
filenotfoundstr:
	.asciz	"File not found\r\n"
fileloadok:
	.asciz	"F"
fileloaderr:
	.asciz	"E"
firstfiledatasect:			# this is the sector where cluster 2 is
	.short	0x0000			# and is calculated
rootdirsects:				# number of sectors for root dir
	.short	0x0000
.section .id
	.long	0xaa550000
