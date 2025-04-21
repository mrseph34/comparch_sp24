# Specify the tools
CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
ICEPROG = iceprog
YOSYS = yosys
NEXTPNR = nextpnr-ice40
ICEPACK = icepack

# Specify your source files
ASSEMBLY_FILE = blink_leds.s
ELF_FILE = blink_leds
BIN_FILE = $(ELF_FILE).bin
HEX_FILE = $(ELF_FILE).hex

# Verilog source directories
VERILOG_SRC_DIR = core
INSTRUCTION_SRC_DIR = instructions

# Top level and related files
TOP_MODULE = top.sv
MEMORY_FILE = memory/memory.sv

# Define your output files
DESIGN_BLIF = design.blif
DESIGN_JSON = design.json
DESIGN_ASC = design.asc
FPGA_BIN = design.bin

# Target to build everything
all: $(BIN_FILE) synth load

# Compile assembly to ELF
$(ELF_FILE): $(ASSEMBLY_FILE)
	$(CC) -o $@ $<

# Convert ELF to binary
$(BIN_FILE): $(ELF_FILE)
	$(OBJCOPY) -O binary $< $@

# Convert binary to hex
$(HEX_FILE): $(BIN_FILE)
	$(OBJCOPY) -O verilog $< $@

# Synthesize Verilog design
synth: $(HEX_FILE)
	$(YOSYS) -p "synth_ice40 -top top -blif $(DESIGN_BLIF)" $(VERILOG_SRC_DIR)/*.sv $(INSTRUCTION_SRC_DIR)/*.sv $(TOP_MODULE)
	$(NEXTPNR) --json $(DESIGN_JSON) --pcf iceBlink.pcf --asc $(DESIGN_ASC)
	$(ICEPACK) $(DESIGN_ASC) $(FPGA_BIN)

# Load design onto FPGA
load: $(FPGA_BIN)
	$(ICEPROG) $(FPGA_BIN)

# Clean up generated files
clean:
	rm -f $(ELF_FILE) $(BIN_FILE) $(HEX_FILE) $(DESIGN_BLIF) $(DESIGN_JSON) $(DESIGN_ASC) $(FPGA_BIN)

# Phony targets
.PHONY: all synth load clean