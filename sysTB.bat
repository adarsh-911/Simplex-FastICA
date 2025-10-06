iverilog -f ./tb/system/files.f -o ./build/sim/icarus/sysTB.out
vvp ./build/sim/icarus/sysTB.out
gtkwave ./dump.vcd