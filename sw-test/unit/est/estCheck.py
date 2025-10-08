import numpy as np
import matplotlib.pyplot as plt

FRAC_WIDTH = 20
DIM = 5
SAMPLES = 10

with open('sw-test/unit/est/_expMult.mem', 'r') as f:
  S_exp_hex_str = f.read()

with open('sw-test/unit/est/out/sim.raw', 'r') as f:
  S_est_hex_str = f.read()

S_est_list = [int(S_est_hex_str[i:i+8], 16) for i in range(0, len(S_est_hex_str), 8)]
S_est_shifted = np.array(S_est_list, dtype=np.uint32)

S_est_sign = S_est_shifted.astype(np.int32)

S_est = S_est_sign.astype(np.float32) / (1 << FRAC_WIDTH)

S_exp_hex_str = S_exp_hex_str.strip()
S_exp_list = [int(S_exp_hex_str[i:i+8], 16) for i in range(0, len(S_exp_hex_str), 8)]
S_exp = np.array(S_exp_list, dtype=np.uint32).view(np.float32)

diff = (S_exp - S_est)

print("S estimated: ")
print(" ".join(f"{num:.6f}" for num in S_est))

print("\nS expected: ")
print(" ".join(f"{num:.6f}" for num in S_exp))

print("\nError: ")
print(" ".join(f"{num:.6f}" for num in diff))

print("-----------------------------------------------------------------------------------------------------------------")
absNorm = np.linalg.norm(diff)
avgError = np.mean(diff)
print(f"Absolute error: {absNorm:.10f}")

plt.plot(np.arange(1, DIM*SAMPLES+1), diff, color='r', lw=2)
plt.scatter(np.arange(1, DIM*SAMPLES+1), diff, color='r')
plt.xlabel("Element")
plt.ylabel("Error")
plt.axhline(y=avgError, color='g', linestyle='--', lw=2)
plt.title("Absolute error")
plt.grid(True)
plt.show()