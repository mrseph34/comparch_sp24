filename = rgb2
pcf_file = ../common/iceBlinkPico.pcf

build:
	yosys -p "synth_ice40 -top top -json $(filename).json" $(filename).sv
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog: #for sram
	dfu-util --alt 0 -D $(filename).bin -R

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).json $(filename).bin