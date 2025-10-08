import numpy as np
import matplotlib.pyplot as plt

W_T = np.array([
    [10, 20, 30],
    [40, 50, 60],
    [70, 80, 90]
], dtype=np.uint16)

Z = np.array([
    [5, 10, 15, 20],
    [25, 30, 35, 40],
    [45, 50, 55, 60]
], dtype=np.uint16)

W = W_T.T

result = np.matmul(W, Z, dtype=np.uint32)
result = np.clip(result, 0, 65535).astype(np.uint16)

def print_matrix_hex(name, matrix):
  print(f"{name}:")
  for row in matrix:
    print("  " + "  ".join(f"0x{val:04X}" for val in row))
  print()

print_matrix_hex("Matrix W (3x3)", W)
print_matrix_hex("Matrix Z (3x4)", Z)
print_matrix_hex("Expected S_est (3x4)", result)

S_est_hex_str = input("\nS_est hex string: ").strip()

S_est_hex_str = S_est_hex_str.replace("0x", "").replace(" ", "")

if len(S_est_hex_str) % 4 != 0:
  raise ValueError("Invalid S_est length: total hex digits must be a multiple of 4 (16 bits per element).")

S_est_list = [int(S_est_hex_str[i:i+4], 16) for i in range(0, len(S_est_hex_str), 4)]
S_est = np.array(S_est_list, dtype=np.uint16)

result_flat = result.flatten()

if len(S_est) != len(result_flat):
  raise ValueError(f"S_est length ({len(S_est)}) does not match result size ({len(result_flat)}).")

error = (result_flat.astype(np.int32) - S_est.astype(np.int32))
abs_error = np.abs(error)

print("\nIndex | Actual(hex) | Expected(hex) | Error (dec)")
print("-----------------------------------------------")
for i in range(len(result_flat)):
  print(f"{i:5d} | 0x{result_flat[i]:04X} | 0x{S_est[i]:04X} | {error[i]:04X}")

'''
plt.figure()
plt.title("Per-element Error (Result - S_est)")
plt.plot(abs_error, marker='o')
plt.xlabel("Element Index")
plt.ylabel("Absolute Error (LSBs)")
plt.grid(True)
plt.show()
'''