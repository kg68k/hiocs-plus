# Makefile for HIOCS PLUS

AS	= has
ASFLAGS	= -c4
LD	= hlk
LDFLAGS = -x

PROG	= hiocs.x hiocs030.x

SRCS	= header.s rompatch.s console.s doscon.s mouse.s graph.s work.s hiocs.s
OBJS	= $(SRCS:.s=.o)


all: $(PROG)

hiocs.x: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

hiocs030.x: $(OBJS:.o=030.o)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.s hiocs.equ
	$(AS) $(ASFLAGS) -o $@ $< -sCPU=68000

%030.o: %.s hiocs.equ
	$(AS) $(ASFLAGS) -o $@ $< -sCPU=68030


# EOF
