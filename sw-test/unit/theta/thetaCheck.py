import numpy as np
import matplotlib.pyplot as plt

theta_exp = np.load('sw-test/unit/theta/_thetaExp.npy')

FRAC_WIDTH = 20
DIM = 5

with open('sw-test/unit/theta/out/sim.raw', 'r') as f:
  tht_est_hex_str = f.read()

tht_est_list = [int(tht_est_hex_str[i:i+4], 16) for i in range(0, len(tht_est_hex_str), 4)]
tht_est_shifted = np.array(tht_est_list, dtype=np.uint16)
tht_est_sign = tht_est_shifted.astype(np.int16)
tht_est = tht_est_sign.astype(np.float32) * np.pi / (1 << 15)

tht_est = tht_est[::-1]

print('Estimated theta:')
print(tht_est)

print('\nExpected theta:')
print(theta_exp)

err = theta_exp - tht_est

plt.plot(err, lw=1.5, c='g')
plt.xlabel('Element')
plt.ylabel('Error')
plt.title('Error')
plt.grid(True)
plt.show()