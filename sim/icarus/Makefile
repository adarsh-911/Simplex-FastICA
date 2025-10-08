IVERILOG = iverilog
VVP      = vvp
WAVE     = gtkwave

EST_SRC_F = sim/icarus/est_rtl.f
GSO_SRC_F = sim/icarus/gso_rtl.f
NORM_SRC_F = sim/icarus/norm_rtl.f
UPDATE_SRC_F = sim/icarus/updt_rtl.f

EST_TB_F = sim/icarus/est_tb.f
GSO_TB_F = sim/icarus/gso_tb.f
NORM_TB_F = sim/icarus/norm_tb.f
UPDATE_TB_F = sim/icarus/updt_tb.f

BUILD = build/sim/icarus
OUT   = $(BUILD)/sim.out

all: run

compile_est:
	mkdir -p $(BUILD)
	$(IVERILOG) -o $(OUT) -c $(EST_SRC_F) -c $(EST_TB_F)

compile_gso:
	mkdir -p $(BUILD)
	$(IVERILOG) -o $(OUT) -c $(GSO_SRC_F) -c $(GSO_TB_F)

compile_norm:
	mkdir -p $(BUILD)
	$(IVERILOG) -o $(OUT) -c $(NORM_SRC_F) -c $(NORM_TB_F)

compile_update:
	mkdir -p $(BUILD)
	$(IVERILOG) -o $(OUT) -c $(UPDATE_SRC_F) -c $(UPDATE_TB_F)

run: compile
	$(VVP) $(OUT)

run_unit:
	$(VVP) $(OUT)

wave:
	$(WAVE) $(BUILD)/dump.vcd
