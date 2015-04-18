
AS		= as
ASFLAGS		= --32 -march=i486

OBJCOPY		= objcopy
OBJCOPY_FLAGS	= -O binary --image-base=0x100

SRCS		= boot.s boot32.s display.s main.s eh.s interrupts.s i8259.s task.s debug.s exit.s end.s
INCLS		= protmode.h data.h
TARGET		= protmode.com
BIN		= $(TARGET:.com=)
OBJ		= $(TARGET:.com=.o)
LST		= $(TARGET:.com=.lst)


.PHONY: all
all:	$(TARGET)

.PHONY: clean
clean::
	rm -f $(LST) $(OBJ) $(BIN) $(TARGET)

.PHONY: install
install: $(TARGET)
	cp -a protmode.com /mnt/
	sync

$(OBJ):	Makefile $(SRCS) $(INCLS)
	$(AS) $(ASFLAGS) -a=$(LST) -o $@ $(SRCS)


$(BIN): $(OBJ)
	$(OBJCOPY) $(OBJCOPY_FLAGS) $(OBJ) $(BIN)

$(TARGET): $(BIN)
	dd if=$(BIN) of=$(TARGET) bs=256 skip=1
