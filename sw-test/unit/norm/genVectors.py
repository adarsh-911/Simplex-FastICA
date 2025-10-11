import numpy as np

DATA_WIDTH = 32
DIM = 5
FRAC_WIDTH = 20

val_range = 20

w_test = (np.random.rand(DIM, 1)* (val_range*2) - val_range).astype(np.float32)

print('Test vector (W_in)')
print(w_test[:, 0])

w_norm = w_test / np.linalg.norm(w_test)

w_test_shift = w_test * (1 << FRAC_WIDTH)

w_test_int = w_test_shift.astype(np.uint32)
w_hex = ''.join(f'{x:08x}' for x in w_test_int.flatten())

with open('sw-test/unit/norm/_wTest.mem', 'w') as f:
  f.write(w_hex)

np.save('sw-test/unit/norm/_wExp.npy', w_norm)