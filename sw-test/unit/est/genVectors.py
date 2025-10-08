import numpy as np

DATA_WIDTH = 32
FRAC_WIDTH = 20 # signed Q12.20

DIM = 5
SAMPLES = 10

val_range = 5

W_T = (np.random.rand(DIM, DIM)* (val_range*2) - val_range).astype(np.float32)
Z = (np.random.rand(DIM, SAMPLES)* (val_range*2) - val_range).astype(np.float32)

W = W_T.T

result = np.matmul(W, Z, dtype=np.float32)

def print_matrix_hex(name, matrix):
  print(f"{name}:")
  for row in matrix:
    print("  " + "  ".join(f"0x{val:08x}" for val in row))
  print()

W_T_shifted = W_T * (1 << FRAC_WIDTH)
Z_shifted = Z * (1 << FRAC_WIDTH)

W_int = W_T_shifted.astype(np.uint32)
Z_int = Z_shifted.astype(np.uint32)
res_int = result.view(np.uint32)

#print_matrix_hex("Matrix W (3x3)", W)
#print_matrix_hex("Matrix Z (3x4)", Z)
#print(result)
#print(res_int)

w_hex = ''.join(f'{x:08x}' for x in W_int.flatten())
z_hex = ''.join(f'{x:08x}' for x in Z_int.flatten())
res_hex = ''.join(f'{x:08x}' for x in res_int.flatten())

with open('sw-test/unit/est/_wTest.mem', 'w') as f:
  f.write(w_hex)

with open('sw-test/unit/est/_zTest.mem', 'w') as f:
  f.write(z_hex)

with open('sw-test/unit/est/_expMult.mem', 'w') as f:
  f.write(res_hex)

print("Written test vectors to _wTest.mem and _zTest.mem")