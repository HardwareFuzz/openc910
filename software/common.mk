# Common build rules for bare-metal demos under software/*
.DEFAULT_GOAL := all

ifndef RISCV_PREFIX
  ifdef TOOL_EXTENSION
    RISCV_PREFIX := ${TOOL_EXTENSION}/riscv64-unknown-elf
  else
    RISCV_PREFIX := riscv64-unknown-elf
  endif
endif
RISCV_GCC     ?= ${RISCV_PREFIX}-gcc
RISCV_OBJDUMP ?= ${RISCV_PREFIX}-objdump
RISCV_OBJCOPY ?= ${RISCV_PREFIX}-objcopy
CONVERT ?= $(CURDIR)/../../smart_run/tests/bin/Srec2vmem

SSRC := $(wildcard *.S)
sSRC := $(wildcard *.s)
CSRC := $(wildcard *.c)
OBJECTS := $(SSRC:%.S=%.o) $(sSRC:%.s=%.o) $(CSRC:%.c=%.o)

FLAG_MARCH ?= -march=rv64imafdc
FLAG_ABI   ?= -mabi=lp64d
CFLAGS     ?= ${FLAG_MARCH} ${FLAG_ABI} -c -O2 -nostdlib -fno-builtin
LINKER_SCRIPT ?= linker.lcf
LINKFLAGS  ?= -T${LINKER_SCRIPT} -nostartfiles -nostdlib ${FLAG_MARCH} ${FLAG_ABI}
OBJDUMPFLAGS ?= -S -Mnumeric
HEXFLAGS   ?= -O srec

%.o : %.c
	${RISCV_GCC} ${CFLAGS} -o $@ $<

%.o : %.s
	${RISCV_GCC} ${CFLAGS} -o $@ $<

%.o : %.S
	${RISCV_GCC} ${CFLAGS} -o $@ $<

${FILE}.elf : ${OBJECTS} ${LINKER_SCRIPT}
	${RISCV_GCC} ${LINKFLAGS} ${OBJECTS} -o $@

${FILE}.obj : ${FILE}.elf
	${RISCV_OBJDUMP} ${OBJDUMPFLAGS} $< > $@

INST_HEX = ${FILE}_inst.hex
DATA_HEX = ${FILE}_data.hex
FILE_HEX = ${FILE}.hex

${FILE}.hex : ${FILE}.elf
	${RISCV_OBJCOPY} ${HEXFLAGS} $< ${INST_HEX} -j .text*  -j .rodata* -j .eh_frame*
	${RISCV_OBJCOPY} ${HEXFLAGS} $< ${DATA_HEX} -j .data*  -j .bss -j .COMMON
	${RISCV_OBJCOPY} ${HEXFLAGS} $< $@

INST_PAT = inst.pat
DATA_PAT = data.pat
FILE_PAT = case.pat

%.pat : %.hex
	rm -f *.pat
	${CONVERT} ${INST_HEX} ${INST_PAT}
	${CONVERT} ${DATA_HEX} ${DATA_PAT}
	${CONVERT} ${FILE_HEX} ${FILE_PAT}

.PHONY: all clean

all : ${FILE}.pat ${FILE}.hex ${FILE}.elf ${FILE}.obj

clean:
	rm -rf *.o *.pat *.elf *.obj *.hex
