###
# task.s: Implement a task. We'll start multiple copies.
###

###
# task: Write arrows back and forth on the screen
#	es: will be the current task's area of display RAM
###
task:
	movw	$LDT_DESC_TASK0DATA,%dx
	movw	%dx,%es

	#mov	$0x280,%edi		# offset in to our display RAM area
	xor	%edi,%edi		# offset in to our display RAM area
	xchg	%al,%ah
	movb	$0xaf,%al		# start with a right arrow
	cld				# increment %edi
task_nxtloop:
	mov	$0x4f,%ecx		# 80 columns per display row
task_nxtchr:
	stosw
	loop task_nxtchr

	xorb	$0x01,%al		# toggle the direction of the arrow
	testb	$0x01,%al
	jz	goleft
	cld				# increment %edi
	jmp	task_nxtloop
goleft:
	std				# decrement %edi
	jmp	task_nxtloop

	# never actually get here
	ret

currtask:	.short	0x0000

tss0:
	.short	0x0000			# previous task link
	.short	0x0000			# reserved
	.long	0x00020000		# esp0
	.short	GDT_DESC_DATABIG	# ss0
	.short	0x0000			# reserved
	.long	0x00000000		# esp1
	.short	0x0000			# ss1
	.short	0x0000			# reserved
	.long	0x00000000		# esp2
	.short	0x0000			# ss2
	.short	0x0000			# reserved
	.long	0x00000000		# cr3 (PDBR)
	.long	task			# eip
	.long	0x00000000		# eflags
	.long	0x0000000c		# eax
	.long	0x00000000		# ecx
	.long	0x00000000		# edx
	.long	0x00000000		# ebx
	.long	0x00010000		# esp
	.long	0x00000000		# ebp
	.long	0x00000000		# esi
	.long	0x00000000		# edi
	.short	LDT_DESC_TASK0DATA	# es
	.short	0x0000			# reserved
	.short	GDT_DESC_CODEBIG	# cs
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ss
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ds
	.short	0x0000			# reserved
	.short	0x0000			# fs
	.short	0x0000			# reserved
	.short	0x0000			# gs
	.short	0x0000			# reserved
	.short	GDT_DESC_LDT0		# LDT selector
	.short	0x0000			# reserved
	.short	0x0000			# reserved | T flag
	.short	0x0000			# I/O map base addr
					# ---
tss1:
	.short	0x0000			# previous task link
	.short	0x0000			# reserved
	.long	0x00000000		# esp0
	.short	0x0000			# ss0
	.short	0x0000			# reserved
	.long	0x00000000		# esp1
	.short	0x0000			# ss1
	.short	0x0000			# reserved
	.long	0x00000000		# esp2
	.short	0x0000			# ss2
	.short	0x0000			# reserved
	.long	0x00000000		# cr3 (PDBR)
	.long	task			# eip
	.long	0x00000200		# eflags
	.long	0x0000000e		# eax
	.long	0x00000000		# ecx
	.long	0x00000000		# edx
	.long	0x00000000		# ebx
	.long	0x00020000		# esp
	.long	0x00000000		# ebp
	.long	0x00000000		# esi
	.long	0x00000000		# edi
	.short	LDT_DESC_TASK1DATA	# es
	.short	0x0000			# reserved
	.short	GDT_DESC_CODEBIG	# cs
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ss
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ds
	.short	0x0000			# reserved
	.short	0x0000			# fs
	.short	0x0000			# reserved
	.short	0x0000			# gs
	.short	0x0000			# reserved
	.short	GDT_DESC_LDT1		# LDT selector
	.short	0x0000			# reserved
	.short	0x0000			# reserved | T flag
	.short	0x0000			# I/O map base addr
					# ---
tss2:
	.short	0x0000			# previous task link
	.short	0x0000			# reserved
	.long	0x00000000		# esp0
	.short	0x0000			# ss0
	.short	0x0000			# reserved
	.long	0x00000000		# esp1
	.short	0x0000			# ss1
	.short	0x0000			# reserved
	.long	0x00000000		# esp2
	.short	0x0000			# ss2
	.short	0x0000			# reserved
	.long	0x00000000		# cr3 (PDBR)
	.long	task			# eip
	.long	0x00000200		# eflags
	.long	0x00000009		# eax
	.long	0x00000000		# ecx
	.long	0x00000000		# edx
	.long	0x00000000		# ebx
	.long	0x00030000		# esp
	.long	0x00000000		# ebp
	.long	0x00000000		# esi
	.long	0x00000000		# edi
	.short	LDT_DESC_TASK2DATA	# es
	.short	0x0000			# reserved
	.short	GDT_DESC_CODEBIG	# cs
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ss
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ds
	.short	0x0000			# reserved
	.short	0x0000			# fs
	.short	0x0000			# reserved
	.short	0x0000			# gs
	.short	0x0000			# reserved
	.short	GDT_DESC_LDT2		# LDT selector
	.short	0x0000			# reserved
	.short	0x0000			# reserved | T flag
	.short	0x0000			# I/O map base addr
					# ---
tssirq0:
	.short	0x0000			# previous task link
	.short	0x0000			# reserved
	.long	0x00000000		# esp0
	.short	0x0000			# ss0
	.short	0x0000			# reserved
	.long	0x00000000		# esp1
	.short	0x0000			# ss1
	.short	0x0000			# reserved
	.long	0x00000000		# esp2
	.short	0x0000			# ss2
	.short	0x0000			# reserved
	.long	0x00000000		# cr3 (PDBR)
	.long	int20_handler		# eip
	.long	0x00000000		# eflags
	.long	0x00000200		# eax
	.long	0x00000000		# ecx
	.long	0x00000000		# edx
	.long	0x00000000		# ebx
	.long	0x00040000		# esp
	.long	0x00000000		# ebp
	.long	0x00000000		# esi
	.long	0x00000000		# edi
	.short	GDT_DESC_DATABIG	# es
	.short	0x0000			# reserved
	.short	GDT_DESC_CODEBIG	# cs
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ss
	.short	0x0000			# reserved
	.short	GDT_DESC_DATABIG	# ds
	.short	0x0000			# reserved
	.short	0x0000			# fs
	.short	0x0000			# reserved
	.short	0x0000			# gs
	.short	0x0000			# reserved
	.short	0x0000			# LDT selector
	.short	0x0000			# reserved
	.short	0x0000			# reserved | T flag
	.short	0x0000			# I/O map base addr
					# ---
