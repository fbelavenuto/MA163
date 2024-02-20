# Makefile
#

AS = ca65
LD = ld65
CP = cp
RM = rm -f
MD = mkdir

AFLAGS  = -t none -l $(*).lst
LDFLAGS = -C link.cfg

all: apple.rom

apple.rom: apple.o
	$(LD) $(LDFLAGS) -o $@ $^

.PHONY: clean

clean:
	$(RM) *.o *.lst *.rom

%.o: %.a65
	$(AS) $(AFLAGS) -o $@ $<
