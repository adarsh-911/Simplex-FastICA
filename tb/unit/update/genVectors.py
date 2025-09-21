import random
import math

N = 7
M = 8
DATA_WIDTH = 16
FRAC_WIDTH = 10
MAKEVALUESSMALL = 5

def generate_random_value(data_width):
    return random.randint(-(1 << (data_width - MAKEVALUESSMALL - 1)),
                          (1 << (data_width - MAKEVALUESSMALL - 1)) - 1)

def fixed_point_mult(a, b, frac_bits):
    result = a * b
    return result >> frac_bits

def normalize_to_fixed_point(values, frac_bits):
    norm_squared = sum(v * v for v in values)
    norm = math.sqrt(norm_squared)
    if norm == 0:
        normalized = [0.0] * len(values)
    else:
        normalized = [v / norm for v in values]
    fixed_point_values = []
    max_val = (1 << (DATA_WIDTH - 1)) - 1
    min_val = -(1 << (DATA_WIDTH - 1))
    for val in normalized:
        fixed_val = int(val * (1 << frac_bits))
        fixed_val = max(min_val, min(max_val, fixed_val))
        fixed_point_values.append(fixed_val)
    return fixed_point_values

def generate_memory_files():
    W_in_float = [random.uniform(-1.0, 1.0) for _ in range(N)]
    W_in = normalize_to_fixed_point(W_in_float, FRAC_WIDTH)
    Z_in = [generate_random_value(DATA_WIDTH) for _ in range(M * N)]
    G = []
    for m in range(M):
        g_val = 0
        for n in range(N):
            g_val += fixed_point_mult(W_in[n], Z_in[m * N + n], FRAC_WIDTH)
        G.append(g_val)
    G_cubed = []
    for g in G:
        g_cubed = (g * g * g) >> (2 * FRAC_WIDTH)
        G_cubed.append(g_cubed)
    G_norm_squared = sum(g * g for g in G_cubed)
    G_norm = int(G_norm_squared ** 0.5)
    P = []
    for n in range(N):
        p_val = 0
        for m in range(M):
            p_val += fixed_point_mult(Z_in[m * N + n], G_cubed[m], FRAC_WIDTH)
        P.append(p_val)
    W_out = []
    for n in range(N):
        w_new = P[n] // M
        w_new = w_new & ((1 << DATA_WIDTH) - 1)
        W_out.append(w_new)
    print("W_in (fixed-point):", W_in)
    print("W_in (float):", [w / (1 << FRAC_WIDTH) for w in W_in])
    print("W_in norm:", math.sqrt(sum((w / (1 << FRAC_WIDTH)) ** 2 for w in W_in)))
    print("G (fixed-point):", G)
    print("G (float):", [g / (1 << FRAC_WIDTH) for g in G])
    print("G_norm (fixed-point):", G_norm)
    print("G_norm (float):", G_norm / (1 << FRAC_WIDTH))
    print("P (fixed-point):", P)
    print("P (float):", [p / (1 << FRAC_WIDTH) for p in P])
    with open('_W_in.mem', 'w') as f:
        for w in W_in:
            f.write(f"{w & 0xFFFFFFFF:08x}\n")
    with open('_Z_in.mem', 'w') as f:
        for z in Z_in:
            f.write(f"{z & 0xFFFFFFFF:08x}\n")
    with open('_expected.mem', 'w') as f:
        for w in W_out:
            f.write(f"{w & 0xFFFFFFFF:08x}\n")

if __name__ == "__main__":
    random.seed(3)
    generate_memory_files()