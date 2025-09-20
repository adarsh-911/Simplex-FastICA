# Simplex FastICA
## Using iverilog
List all src and tb file paths in `./sim/icarus/rtl.f` and `./sim/icarus/tb.f`
Compile all source files and testbenches,
```
./simulate compile
```
Simulate using `gtkwave`
```
./simulate wave
```

## Testing
Generate test vectors
```
./genTestVectors
```
Saved at `./dataset/testVectors/`
