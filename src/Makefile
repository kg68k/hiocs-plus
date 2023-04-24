# Makefile for HIOCS PLUS

ifeq ($(notdir $(CURDIR)),src)
$(error do not execute make in src directory)
endif

AS	= has
ASFLAGS	= -c3
LD	= hlk
LDFLAGS = -x

PROG	= hiocs.x hiocs030.x

SRCS	= header.s rompatch.s console.s doscon.s mouse.s graph.s work.s hiocs.s
OBJS	= $(SRCS:.s=.o)
DOCS	= hiocs_plus.txt

HIOCSP_ZIP = hiocsp.zip
ARCS	= $(HIOCSP_ZIP)


all: $(PROG)

hiocs.x: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

hiocs030.x: $(OBJS:.o=030.o)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.s hiocs.equ
	$(AS) $(ASFLAGS) -o $@ $< -sCPU=68000

%030.o: %.s hiocs.equ
	$(AS) $(ASFLAGS) -o $@ $< -sCPU=68030


$(HIOCSP_ZIP): $(DOCS) $(PROG)
	rm -f $@
	zip -9 $@ $^

# EOF
