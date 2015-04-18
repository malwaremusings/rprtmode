.text		# section declaration
.code16

		# we must export the entry point to the ELF linker or
		# loader. They conventionally recognise _start as their
		# entry point. Use ld -e foo to override the default

#.global _start

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
	fs:movl	%eax,0x80 * 4

	outb	%al,$0x80		# io delay
	
	gs:movl	(0x80 * 4) + 0x10,%edx
	xorl	%eax,%edx
	loopz	loopme

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

	call	mask_all_ints

	seg2linear %cs,$gdt,gdtr + 0x02

	lgdt	gdtr

	pushw	%cs
	popw	%ax

	movw	%ax,jmpoff1 + 0x02

	#
	# fix up the real mode base address in the GDT
	# to be current real mode CS << 4, so linear 
	# addr of cs:0000
	#
	# if we don't do this, the jump to 64kb segment 
	# is trying to jump to a (linear) address that is past 
	# the end of a 64kb segment. This seems to cause 
	# a reset!
	#
	pushw	%cs
	popw	%ax
	movw	%ax,%bx
	shr	$0x0c,%bx
	movb	%bl,rbase1 + 0x02
	movb	%bl,rbase2 + 0x02
	shl	$0x04,%ax
	movw	%ax,rbase1
	movw	%ax,rbase2

	push	%ss
	call	dumpword_r

	seg2linear %cs,$text32,jmpoff0

	movl	%cr0,%eax
	orb	$0x01,%al
	movl	%eax,%cr0

	.byte	0x66,0xea			# far jump
jmpoff0:.long	0x00000000
	.short	0x0008				# idx: 1, table: 0, rpl: 00
.code32
#.section ".text32","ax"

text32:
	call	text32_wherearewe
text32_wherearewe:
	pop	%ebp
	sub	$(text32_wherearewe - _start + 0x100),%ebp

	xor	%eax,%eax
	movw	%ss,%ax
	shl	$0x4,%eax

	movw	$0x10,%cx
	movw	%cx,%ds
	movw	%cx,%es

	add	$0x08,%cx
	movw	%cx,%ss
	mov	%esp,oldsp(%ebp)

	add	%eax,%esp

	#
	# fix up offsets in IDT
	#
	mov	$0x14,%ecx
	lea	idt(%ebp),%esi
nxtint:
	xor	%eax,%eax
	movw	-8(%esi,%ecx,8),%ax		# loop control var needs to be 20 for 20 entries and 'loop', but 0 based index
						# so subtract 8 to essentially make it (ecx - 1) * 8
	add	%ebp,%eax
	movw	%ax,-8(%esi,%ecx,8)
	ror	$0x10,%eax
	movw	%ax,6 - 8(%esi,%ecx,8)
	loop	nxtint

	mov	%esi,idtr + 2(%ebp)
	lidt	idtr(%ebp)

	#call	move_irqs_pm
	#call	unmask_all_ints

	# cross your fingers
	#sti

	call	main
	call	debug
	push	%esp
	call	dumplword
	add	$0x4,%esp
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	#movw	$0xeee0,%ax
	#movw	%ax,%ds
	push	%esp
	call	dumplword
	add	$0x4,%esp

gotoreal:
	#
	# prepare for real mode
	# Intel reference section 9.9.2
	#

	# load IDTR with normal int vectors
	xor	%eax,%eax
	mov	%eax,idtr + 2(%ebp)
	movw	$0x3ff,%ax
	mov	%ax,idtr(%ebp)
	lidt	idtr(%ebp)

	cli
	.byte	0xea
	.long	goto64kb
	.short	0x0020
goto64kb:
	call	debug

	mov	$0x0028,%ecx
	mov	%ecx,%ds
	mov	%ecx,%es
	mov	%ecx,%ss

	movl	%cr0,%eax
	andl	$0xfffffffe,%eax
	movl	%eax,%cr0

	.byte	0xea
jmpoff1:.short	text16
	.short	0x0000
.code16
text16:
	movw	%cs,%cx
	movw	%cx,%ds
	movw	%cx,%es
	movw	%cx,%ss

	movw	oldsp,%sp
	push	%sp
	call	dumpword_r

	movw	$0xb800,%cx
	movw	%cx,%es
	movw	$0x0742,%ax
	xorw	%di,%di
	stosw

	call	move_irqs_rm

	call	unmask_all_ints

	sti

	mov	$0x01,%ah
	int	$0x21

	xorw	%ax,%ax
	int	$0x21

	int	$0x20

	nop

oldsp:
	.word	0x00000000

en:
	.ascii	"Enabled\r\n$"
di:
	.ascii	"Disabled\r\n$"

gdtr:	.short	gdtend - gdt - 1	# gdtr limit is largest valid address in GDT, not size in bytes!
					# since each entry is 8 bytes, this should be (8n - 1)
	.long   $gdt
.balign 16
gdt:

	#
	# 0: Null descriptor
	#
	.short	0x0000			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x00			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = f	(exe, read, conforming, accessed)
	.byte	0x00			# G = 1		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 1: Code
	#
	.short	0xffff			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x9f			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = b	(exe, read, accessed)
	.byte	0xcf			# G = 1		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 2: Data
	#
	.short	0xffff			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0xcf			# G = 1		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 3: Stack
	#
	.short	0xffff			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0xcf			# G = 1		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 4: Real Mode Code
	#
	.short	0xffff			# limit 0 - 15
rbase1:	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x98			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 8	(exe only)
	.byte	0x00			# G = 0		(byte granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 4: Real Mode Data
	#
	.short	0xffff			# limit 0 - 15
rbase2:	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0x00			# G = 0		(page granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
gdtend:

idtr:	.short	(idtend - idt - 1)
	.long	0x00000000

.balign 8
idt:
	#
	# 00: Divide Error
	#
	.short	int00_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 01: Single Step/RESERVED
	#
	.short	int01_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 02: NMI
	#
	.short	int02_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 03: Breakpoint (INT 3)
	#
	.short	int03_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 04: Overflow (INTO)
	#
	.short	int04_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 05: BOUND range exceeded (BOUND)
	#
	.short	int05_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 06: Invalid Opcode
	#
	.short	int06_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 07: Device not available
	#
	.short	int07_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 08: Double Fault
	#
	.short	int08_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 09: Coprocessor Segment Overrun (reserved)
	#
	.short	int09_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0a: Invalid TSS
	#
	.short	int0a_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0b: Segment Not Present
	#
	.short	int0b_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0c: Stack Segment Fault
	#
	.short	int0c_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0d: General Protection
	#
	.short	int0d_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0e: Page Fault
	#
	.short	int0e_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0f: (Intel reserved. Do not use.)
	#
	.short	int0f_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 10: x87 FPU Floating-Point Error (Math Fault)
	#
	.short	int10_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 11: Alignment Check
	#
	.short	int11_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 12: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 13: SIMD Floating-Point Exception
	#
	.short	int13_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 14: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 15: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 16: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 17: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 18: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 19: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1a: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1b: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1c: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1d: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1e: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1f: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8f			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 20: IRQ0 handler
	#
	.short	int20_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 20: IRQ1 handler
	#
	.short	0x0000			# Offset 0 - 15
	.short	0x0000			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 22: IRQ2 handler
	#
	.short	0x0000			# Offset 0 - 15
	.short	0x0000			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 23: IRQ3 handler
	#
	.short	0x0000			# Offset 0 - 15
	.short	0x0000			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 24: IRQ4 handler
	#
	.short	int24_handler		# Offset 0 - 15
	.short	0x0008			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 trap gate)
	.short	0x0000			# Offset 16 - 31

idtend:
