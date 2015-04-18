.code16
#.text		# section declaration

		# we must export the entry point to the ELF linker or
		# loader. They conventionally recognise _start as their
		# entry point. Use ld -e foo to override the default

#.global _start

.org 0x100

_start:
	#movw $0x10c,%dx
	movw $msg,%dx
	movb $0x09,%ah
	int $0x21

	mov $0x00,%ah
	int  $0x21
	nop

msg:
	.ascii	"Hello world!\n$"	# our dear string
	len = . - msg			# length of our dear string
