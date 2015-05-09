
#AS		= as
AS		= i586-mingw32msvc-as
ASFLAGS		= --32 -march=i486
LD		= i586-mingw32msvc-ld
LDFLAGS		=

OBJCOPY		= objcopy
OBJCOPY_FLAGS	= -O binary --image-base=0x100

SRCS		= boot.s boot32.s paging.s display.s main.s eh.s interrupts.s i8259.s task.s debug.s exit.s end.s
OBJS		= $(SRCS:.s=.o)
INCLS		= rprtmode.h data.h
TARGET		= rprtmode.exe
BIN		= $(TARGET:.com=)
OBJ		= $(TARGET:.com=.o)
LST		= $(TARGET:.com=.lst)

FILESYSTEMIMG	= dossywossyfloppyfs.raw
TARGETDIR	= /home/libvirt/images/


.PHONY: all
all:	$(TARGET) mbr

.PHONY: clean
clean::
	rm -f $(LST) $(OBJ) $(BIN) $(TARGET) mbr mbr.axf

.PHONY: install
install: $(TARGET)
	cp -a rprtmode.com /mnt/
	sync

$(OBJS):	$(SRCS) $(INCLS)


#$(BIN): $(OBJ)
#	$(OBJCOPY) $(OBJCOPY_FLAGS) $(OBJ) $(BIN)
#
$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

mbr: mbr.o mbr.ld
	#objcopy -O binary mbr.o mbr
	ld -m i386pe  -nostartfiles -static --gc-sections -T mbr.ld --entry 0x7c00 -s -o mbr.axf mbr.o
	objcopy -j .text -O binary mbr.axf mbr

.s.o:
	$(AS) $(ASFLAGS) -a=$@.lst -o $@ $<

installboot: bootloader
	dd if=$(FILESYSTEMIMG) bs=512 skip=1 | cat mbr - > dossywossyfloppy.raw
	cp dossywossyfloppy.raw $(TARGETDIR)
