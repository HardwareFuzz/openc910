# Makefile for skiptrap

# Toolchain settings
RISCV ?= /opt/riscv
PREFIX = $(RISCV)/bin/riscv64-unknown-elf-
CC = $(PREFIX)gcc
AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJDUMP = $(PREFIX)objdump
OBJCOPY = $(PREFIX)objcopy
SIZE = $(PREFIX)size

# Target files
TARGET = skiptrap
SRC = $(TARGET).S
LINKER_SCRIPT = linker.lcf

# Output files
ELF = $(TARGET).elf
BIN = $(TARGET).bin
HEX = $(TARGET).hex
DUMP = $(TARGET).dump
LST = $(TARGET).lst

# Architecture and ABI settings for C910
ARCH = rv64gc
ABI = lp64d

# Compiler/Assembler flags
ASFLAGS = -march=$(ARCH) -mabi=$(ABI) -g
LDFLAGS = -T$(LINKER_SCRIPT) -nostdlib -nostartfiles

# Default target
.PHONY: all
all: $(ELF) $(DUMP) $(BIN) $(HEX)
	@echo "Build complete!"
	@$(SIZE) $(ELF)

# Compile .S to .elf
$(ELF): $(SRC) $(LINKER_SCRIPT)
	$(CC) $(ASFLAGS) $(LDFLAGS) -o $@ $(SRC)
	@echo "Generated: $@"

# Generate disassembly dump
$(DUMP): $(ELF)
	$(OBJDUMP) -D -S $< > $@
	@echo "Generated: $@"

# Generate detailed listing with source
$(LST): $(ELF)
	$(OBJDUMP) -d -S -l $< > $@
	@echo "Generated: $@"

# Generate binary
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@
	@echo "Generated: $@"

# Generate hex
$(HEX): $(ELF)
	$(OBJCOPY) -O verilog $< $@
	@echo "Generated: $@"

# Clean build artifacts
.PHONY: clean
clean:
	rm -f $(ELF) $(DUMP) $(LST) $(BIN) $(HEX) *.o
	@echo "Cleaned build artifacts"

# Show disassembly
.PHONY: dump
dump: $(DUMP)
	@cat $(DUMP)

# Show size information
.PHONY: size
size: $(ELF)
	@$(SIZE) $(ELF)
	@$(SIZE) -A $(ELF)

# Show symbols
.PHONY: symbols
symbols: $(ELF)
	@$(PREFIX)nm -n $(ELF)

# Help
.PHONY: help
help:
	@echo "Makefile for $(TARGET)"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build ELF, dump, bin, and hex (default)"
	@echo "  clean    - Remove build artifacts"
	@echo "  dump     - Show disassembly"
	@echo "  size     - Show size information"
	@echo "  symbols  - Show symbol table"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  RISCV=$(RISCV)"
	@echo "  ARCH=$(ARCH)"
	@echo "  ABI=$(ABI)"
