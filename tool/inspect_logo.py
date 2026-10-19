import os
from PIL import Image

orig_path = r"e:\Apps\new\assets\logo\Green and White Simple Al-Kareem Qur'an Center Logo.png"
if not os.path.exists(orig_path):
    orig_path = r"e:\Apps\new\assets\logo\hkquran_app_icon.png"

img = Image.open(orig_path)
print("Mode:", img.mode, "Size:", img.size)

# Find bounding box of non-transparent pixels (if RGBA) or non-white (if RGB)
if img.mode == 'RGBA':
    bbox = img.getbbox()
    print("Non-transparent bbox:", bbox)
else:
    # If RGB, convert white to transparent or find bbox
    import numpy as np
    arr = np.array(img)
    # find where not pure white
    mask = (arr[:, :, 0] < 250) | (arr[:, :, 1] < 250) | (arr[:, :, 2] < 250)
    y_indices, x_indices = np.where(mask)
    if len(y_indices) > 0:
        print("Non-white bbox:", (x_indices.min(), y_indices.min(), x_indices.max(), y_indices.max()))
