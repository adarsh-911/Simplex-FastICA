IVERILOG = iverilog
VVP      = vvp
WAVE     = gtkwave

SRC_F = sim/icarus/rtl.f
TB_F = sim/icarus/tb.f
BUILD = build/sim/icarus
OUT   = $(BUILD)/sim.out

all: run

compile:
	mkdir -p $(BUILD)
	$(IVERILOG) -o $(OUT) -c $(SRC_F) -c $(TB_F)

run: compile
	$(VVP) $(OUT)

wave:
	$(WAVE) $(BUILD)/dump.vcd
