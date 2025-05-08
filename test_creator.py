import numpy as np
import cv2
import random
from tensorflow.keras.datasets import mnist

new_size = 6
image_mem_file = "image_fp16.mem"
kernel_mem_file = "kernel_fp16.mem"

# Load MNIST image
(x_train, y_train), _ = mnist.load_data()
idx = random.randint(0, len(x_train) - 1)
image = x_train[idx]
label = y_train[idx]
print(f"Selected image index: {idx}, label: {label}")

# Resize + binarize
resized = cv2.resize(image, (new_size, new_size), interpolation=cv2.INTER_NEAREST)
_, binary_img = cv2.threshold(resized, 127, 1, cv2.THRESH_BINARY)
image_fp16 = binary_img.astype(np.float16)

# Define kernel
kernel_fp16 = np.array([
    [0, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 0]
], dtype=np.float16)

# Save image
with open(image_mem_file, "w") as f:
    for row in image_fp16:
        for val in row:
            f.write(f"{val.view(np.uint16):04x}\n")

# Save kernel column-major
with open(kernel_mem_file, "w") as f:
    for c in range(new_size):
        for r in range(new_size):
            f.write(f"{kernel_fp16[r][c].view(np.uint16):04x}\n")

# 🧮 Compute expected output (column-wise accumulation)
elementwise = image_fp16 * kernel_fp16  # 6x6
columnwise_sum = np.sum(elementwise, axis=0)  # sum down each column
columnwise_sum = columnwise_sum.astype(np.float16)

print("\n== Elementwise (image × kernel) ==")
print(elementwise)
print("\n== Expected psum_outs[0..5] ==")
for i, val in enumerate(columnwise_sum):
    raw = val.view(np.uint16)
    print(f"psum_outs[{i}] = {val:.1f} (hex: {raw:04x})")
