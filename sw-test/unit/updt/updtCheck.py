import numpy as np
import matplotlib.pyplot as plt

FRAC_WIDTH = 20

data = np.loadtxt("sw-test/unit/updt/out/test_results.txt", dtype=str)

est = np.array([int(x, 32) for x in data[:, 0]])
exp = np.array([int(x, 32) for x in data[:, 1]])

est = est.astype(np.float64) / (1 << FRAC_WIDTH)
exp = exp.astype(np.float64) / (1 << FRAC_WIDTH)


print(f"Estimated \n: {est}")
print(f"\nExpected \n: {exp}")

err = exp - est

plt.plot(err, lw=1.5)
plt.grid(True)
plt.show()