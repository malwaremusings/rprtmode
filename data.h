###
# a20 strings
###

en:
	.ascii	"Enabled\r\n$"
di:
	.ascii	"Disabled\r\n$"


###
# Our bootstrap Global Descriptor Table Register and GDT.
# This is used to enable us to switch to protected mode and to a 32-bit code 
# segment to get access to our big memory segment (as it is not addressable 
# while in real mode).
###

gdtr_boot:	.short	gdt_bootend - gdt_boot - 1	# gdtr limit is largest valid address in GDT, not size in bytes!
					# since each entry is 8 bytes, this should be (8n - 1)
	.long   gdt_boot		# linear address of GDT

.balign 16
gdt_boot:

	#
	# 0: Null descriptor
	#
	.equ	GDT_DESC_NULL,(((. - gdt_boot) / 8) << 3)
	.short	0x0000			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x00			# P = 0		(segment not present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 0	(read only)
	.byte	0x00			# G = 0		(byte granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 1: Real Mode Code
	#
	.equ	GDT_DESC_CODEREAL,(((. - gdt_boot) / 8) << 3)
	.short	0xffff			# limit 0 - 15
ourcs:	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x9b			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = b	(exe, read, accessed)
	.byte	0x00			# G = 0		(byte granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 2: Real Mode Data
	#
	.equ	GDT_DESC_DATAREAL,(((. - gdt_boot) / 8) << 3)
	.short	0xffff			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0x00			# G = 0		(byte granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 3: Code
	#
	.equ	GDT_DESC_CODE64KB,(((. - gdt_boot) / 8) << 3)
	.short	0xffff			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x9b			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = b	(exe, read, accessed)
	.byte	0x40			# G = 0		(byte granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 4: Data
	#
	.equ	GDT_DESC_DATA64KB,(((. - gdt_boot) / 8) << 3)
	.short	0xffff			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0x40			# G = 0		(byte granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 5: Data (display RAM: 0xb8000 length 80 * 25 * 2)
	#
	.equ	GDT_DESC_DATADISPRAM,(((. - gdt_boot) / 8) << 3)
	.short	0x0fa0			# limit 0 - 15
	.short	0x8000			# base  0 - 15
	.byte	0x0b			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0x00			# G = 0		(byte granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 6: Our target segment (as data, for copying)
	#
	.equ	GDT_DESC_DATABIG,(((. - gdt_boot) / 8) << 3)
	.short	0xfeff			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	0x0000			# base  0 - 15
	.byte	0x10			# base 16 - 23
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
	# 7: Our target segment (as code, so we can jump to it)
	#
	.equ	GDT_DESC_CODEBIG,(((. - gdt_boot) / 8) << 3)
	.short	0xfeff			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	0x0000			# base  0 - 15
	.byte	0x10			# base 16 - 23
	.byte	0x9b			# P = 1		(segment present)
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
	# 8: Our LDT for task 0
	#
	.equ	GDT_DESC_LDT0,(((. - gdt_boot) / 8) << 3)
ldt0off:.short	ldt0end - ldt0 - 1	# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	ldt0			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x82			# P = 1		(segment present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 2	(LDT)
	.byte	0x40			# G = 0		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 9: Our TSS for task 0
	#
	.equ	GDT_DESC_TSS0,(((. - gdt_boot) / 8) << 3)
tss0off:.short	103			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	tss0			# base  0 - 15
	.byte	0x10			# base 16 - 23
	.byte	0x89			# P = 1		(segment present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 9	(available i386 TSS)
	.byte	0x40			# G = 0		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# a: Our LDT for task 1
	#
	.equ	GDT_DESC_LDT1,(((. - gdt_boot) / 8) << 3)
ldt1off:.short	ldt1end - ldt1 - 1	# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	ldt1			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x82			# P = 1		(segment present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 2	(LDT)
	.byte	0x40			# G = 0		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# b: Our TSS for task 1
	#
	.equ	GDT_DESC_TSS1,(((. - gdt_boot) / 8) << 3)
tss1off:.short	103			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	tss1			# base  0 - 15
	.byte	0x10			# base 16 - 23
	.byte	0x8b			# P = 1		(segment present)
					# DPL = 00
					# DT = 0	(system)
					# Type = b	(busy i386 TSS)
	.byte	0x40			# G = 0		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# c: Our LDT for task 2
	#
	.equ	GDT_DESC_LDT2,(((. - gdt_boot) / 8) << 3)
ldt2off:.short	ldt2end - ldt2 - 1	# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	ldt2			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x82			# P = 1		(segment present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 2	(LDT)
	.byte	0x40			# G = 0		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# d: Our TSS for task 2
	#
	.equ	GDT_DESC_TSS2,(((. - gdt_boot) / 8) << 3)
tss2off:.short	103			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	tss2			# base  0 - 15
	.byte	0x10			# base 16 - 23
	.byte	0x8b			# P = 1		(segment present)
					# DPL = 00
					# DT = 0	(system)
					# Type = b	(busy i386 TSS)
	.byte	0x40			# G = 0		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# e: Our TSS for timer interrupt
	#
	.equ	GDT_DESC_TSSIRQ0,(((. - gdt_boot) / 8) << 3)
tssirq0off:.short	103			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	tssirq0			# base  0 - 15
	.byte	0x10			# base 16 - 23
	.byte	0x89			# P = 1		(segment present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 9	(available i386 TSS)
	.byte	0x40			# G = 0		(page granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
gdt_bootend:


###
# Our main Global Descriptor Table Register, and GDT
# This is used once we've moved ourselves to the big memory segment and
# jumped to it.
###

gdtr:	.short	gdtend - gdt - 1	# gdtr limit is largest valid address in GDT, not size in bytes!
					# since each entry is 8 bytes, this should be (8n - 1)
	.long   gdt			# logical address of GDT

.balign 16
gdt:
	#
	# 0: Null descriptor
	#
	.short	0x0000			# limit 0 - 15
	.short	0x0000			# base  0 - 15
	.byte	0x00			# base 16 - 23
	.byte	0x00			# P = 0		(segment not present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 0	(read only)
	.byte	0x00			# G = 0		(byte granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
					# ---
	#
	# 1: Our target segment (Code)
	#
	.short	0xfeff			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	0x0000			# base  0 - 15
	.byte	0x10			# base 16 - 23
	.byte	0x9b			# P = 1		(segment present)
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
	# 2: Our target segment (Data -- this really ought to be different)
	#
	.short	0xfeff			# limit 0 - 15	(4GB - 1MB (256 * 4KB pages))
	.short	0x0000			# base  0 - 15
	.byte	0x10			# base 16 - 23
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
gdtend:


###
# Interrupt Descriptor Table Register and IDT
###

idtr:	.short	(idtend - idt - 1)
	.long	idt

.balign 8
idt:
	#
	# 00: Divide Error
	#
	.short	int00_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 01: Single Step/RESERVED
	#
	.short	int01_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 02: NMI
	#
	.short	int02_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 03: Breakpoint (INT 3)
	#
	.short	int03_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 04: Overflow (INTO)
	#
	.short	int04_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 05: BOUND range exceeded (BOUND)
	#
	.short	int05_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 06: Invalid Opcode
	#
	.short	int06_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xf (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 07: Device not available
	#
	.short	int07_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 08: Double Fault
	#
	.short	int08_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 09: Coprocessor Segment Overrun (reserved)
	#
	.short	int09_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0a: Invalid TSS
	#
	.short	int0a_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0b: Segment Not Present
	#
	.short	int0b_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0c: Stack Segment Fault
	#
	.short	int0c_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0d: General Protection
	#
	.short	int0d_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0e: Page Fault
	#
	.short	int0e_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 0f: (Intel reserved. Do not use.)
	#
	.short	int0f_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 10: x87 FPU Floating-Point Error (Math Fault)
	#
	.short	int10_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 11: Alignment Check
	#
	.short	int11_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 12: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 13: SIMD Floating-Point Exception
	#
	.short	int13_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 14: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 15: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 16: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 17: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 18: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 19: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1a: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1b: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1c: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1d: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1e: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 1f: Machine Check
	#
	.short	int12_handler		# Offset 0 - 15
	.short	GDT_DESC_CODE64KB	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 20: IRQ0 handler (Timer)
	#
	.short	0x0000			# Offset 0 - 15
	.short	GDT_DESC_TSSIRQ0	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x85			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0x5 (i386 task gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 21: IRQ1 handler (Keyboard)
	#
	.short	int21_handler		# Offset 0 - 15
	.short	GDT_DESC_CODEBIG	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 22: IRQ2 handler (Slave PIC)
	#
	.short	0x0000			# Offset 0 - 15
	.short	0x0000			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 23: IRQ3 handler (Serial port)
	#
	.short	0x0000			# Offset 0 - 15
	.short	0x0000			# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

	#
	# 24: IRQ4 handler (Serial port)
	#
	.short	int24_handler		# Offset 0 - 15
	.short	GDT_DESC_CODEBIG	# seg selector
	.byte	0x00			# 000 = 000
					# DWord-Count = 00000
	.byte	0x8e			# P = 1
					# DPL = 00
					# 0 = 0
					# Typ = 0xe (i386 interrupt gate)
	.short	0x0000			# Offset 16 - 31

idtend:


###
# ldt0: Local Descriptor Table for task 0
###
ldt0:
	#
	# 0: Null descriptor
	#
	#.equ	LDT_DESC_TASK0NULL,(((. - ldt0) / 8) << 3) | 0x04
	#.short	0x0000			# limit 0 - 15
	#.short	0x0000			# base  0 - 15
	#.byte	0x00			# base 16 - 23
	#.byte	0x00			# P = 0		(segment not present)
					# DPL = 00
					# DT = 0	(system)
					# Type = 0	(read only)
	#.byte	0x00			# G = 0		(byte granularity)
					# DB = 0	(16-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	#.byte	0x00			# base  24 - 31
					# ---
	.equ	LDT_DESC_TASK0DATA,(((. - ldt0) / 8) << 3) | 0x04
	.short	0x00a0			# limit 0 - 15
	.short	0x8280			# base  0 - 15
	.byte	0x0b			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0x40			# G = 0		(byte granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
ldt0end:
	

###
# ldt1: Local Descriptor Table for task 1
###
ldt1:
	.equ	LDT_DESC_TASK1DATA,(((. - ldt1) / 8) << 3) | 0x04
	.short	0x00a0			# limit 0 - 15
	.short	0x8280 + 0xa0		# base  0 - 15
	.byte	0x0b			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0x40			# G = 0		(byte granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
ldt1end:
	

###
# ldt2: Local Descriptor Table for task 2
###
ldt2:
	.equ	LDT_DESC_TASK2DATA,(((. - ldt2) / 8) << 3) | 0x04
	.short	0x00a0			# limit 0 - 15
	.short	0x8280 + 0x140		# base  0 - 15
	.byte	0x0b			# base 16 - 23
	.byte	0x93			# P = 1		(segment present)
					# DPL = 00
					# DT = 1	(application)
					# Type = 3	(read/write, accessed)
	.byte	0x40			# G = 0		(byte granularity)
					# DB = 1	(32-bit segment)
					# L = 0		(not 64-bit)
					# av = 0	(available for OS)
					# limit 16 - 19
	.byte	0x00			# base  24 - 31
ldt2end:
