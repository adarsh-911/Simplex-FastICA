import numpy as np

DATA_WIDTH = 32
DIM = 5
FRAC_WIDTH = 20
ANGLE_WIDTH = 16

val_range = 100

w_test = (np.random.rand(DIM, 1)* (val_range) + val_range).astype(np.float32)
#w_test = np.array([1000, 500, 500, 0, 2000, 1000, 1000]).reshape(DIM, 1);

print('Test vector (W_in)')
print(w_test[:, 0])

w_test_shift = w_test * (1 << FRAC_WIDTH)

w_test_int = w_test_shift.astype(np.uint32)
w_hex = ''.join(f'{x:08x}' for x in w_test_int.flatten())

with open('sw-test/unit/theta/_wTest.mem', 'w') as f:
  f.write(w_hex)

w_test_rev = w_test[::-1, 0]

theta = np.zeros(DIM-1)
mag = w_test_rev[0]
for i in range(1, DIM):
  theta[i-1] = np.arctan2(mag, w_test_rev[i])
  mag = np.sqrt(mag**2 + w_test_rev[i]**2);

theta[0] = np.arctan2(w_test_rev[1], w_test_rev[0])

np.save('sw-test/unit/theta/_thetaExp.npy', theta)