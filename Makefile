
AS		= as
ASFLAGS		= --32 -march=i486

OBJCOPY		= objcopy
OBJCOPY_FLAGS	= -O binary --image-base=0x100

SRCS		= boot.s boot32.s paging.s display.s main.s eh.s interrupts.s i8259.s task.s debug.s exit.s end.s
INCLS		= rprtmode.h data.h
TARGET		= rprtmode.com
BIN		= $(TARGET:.com=)
OBJ		= $(TARGET:.com=.o)
LST		= $(TARGET:.com=.lst)

FILESYSTEMIMG	= dossywossyfloppyfs.raw
TARGETDIR	= /home/libvirt/images/


.PHONY: all
all:	$(TARGET)

.PHONY: clean
clean::
	rm -f $(LST) $(OBJ) $(BIN) $(TARGET)

.PHONY: install
install: $(TARGET)
	cp -a rprtmode.com /mnt/
	sync

$(OBJ):	Makefile $(SRCS) $(INCLS)
	$(AS) $(ASFLAGS) -a=$(LST) -o $@ $(SRCS)


$(BIN): $(OBJ)
	$(OBJCOPY) $(OBJCOPY_FLAGS) $(OBJ) $(BIN)

$(TARGET): $(BIN)
	dd if=$(BIN) of=$(TARGET) bs=256 skip=1

bootloader: bootloader.o bootloader.ld
	#objcopy -O binary bootloader.o bootloader
	ld -m i386pe  -nostartfiles -static --gc-sections -T bootloader.ld --entry 0x7c00 -s -o bootloader.axf bootloader.o
	objcopy -j .text -O binary bootloader.axf bootloader

.s.o:
	$(AS) $(ASFLAGS) -a=$(LST) -o $@ $<

installboot: bootloader
	dd if=$(FILESYSTEMIMG) bs=512 skip=1 | cat bootloader - > dossywossyfloppy.raw
	cp dossywossyfloppy.raw $(TARGETDIR)
