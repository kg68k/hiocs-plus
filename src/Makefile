# Makefile for HIOCS PLUS

ifeq ($(notdir $(CURDIR)),src)
$(error do not execute make in src directory)
endif

AS = has060
ASFLAGS = -w2 -c3

ifndef LD
LD = hlk
endif
LDFLAGS = -x

U8TOSJ = u8tosj

SRCDIR_MK = ../srcdir.mk
SRC_DIR = ../src
-include $(SRCDIR_MK)


PROG = hiocs.x hiocs030.x

SRCS = header.s rompatch.s console.s doscon.s mouse.s graph.s work.s hiocs.s
OBJS = $(SRCS:.s=.o)
DOCS = hiocs_plus.txt ChangeLog.txt

HIOCSP_ZIP = hiocsp.zip


.PHONY: all archive

all: $(PROG)

hiocs.x: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

hiocs030.x: $(OBJS:.o=030.o)
	$(LD) $(LDFLAGS) -o $@ $^

hiocs.o hiocs030.o: version.equ

%.o: %.s hiocs.equ
	$(AS) $(ASFLAGS) -o $@ $< -sCPU=68000

%030.o: %.s hiocs.equ
	$(AS) $(ASFLAGS) -o $@ $< -sCPU=68030

hiocs_plus.txt: $(SRC_DIR)/../hiocs_plus.txt
	rm -f $@
	$(U8TOSJ) < $^ > $@

ChangeLog.txt: $(SRC_DIR)/../ChangeLog.md
	rm -f $@
	$(U8TOSJ) < $^ > $@

archive: $(HIOCSP_ZIP)

$(HIOCSP_ZIP): $(DOCS) $(PROG)
	rm -f $@
	zip -9 $@ $^

# EOF
