import numpy as np
import matplotlib.pyplot as plt

FRAC_WIDTH = 20
DIM = 5

w_exp = np.load('sw-test/unit/norm/_wExp.npy')
w_exp = w_exp[:, 0]

with open('sw-test/unit/norm/out/sim.raw', 'r') as f:
  w_est_hex_str = f.read()

w_est_list = [int(w_est_hex_str[i:i+8], 16) for i in range(0, len(w_est_hex_str), 8)]
w_est_shifted = np.array(w_est_list, dtype=np.uint32)
w_est_sign = w_est_shifted.astype(np.int32)
w_est = w_est_sign.astype(np.float32) / (1 << FRAC_WIDTH)

print('Estimated W_norm')
print(w_est)

print('\nExpected W_norm')
print(w_exp)

err = w_exp - w_est

plt.plot(np.arange(1, DIM+1), err, lw=1.5)
plt.scatter(np.arange(1, DIM+1), err)
plt.xlabel('Element')
plt.ylabel('Error')
plt.title('Error')
plt.grid(True)
plt.show()