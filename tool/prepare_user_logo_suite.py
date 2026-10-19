import os
from PIL import Image, ImageOps, ImageFilter
import numpy as np

logo_dir = r"e:\Apps\new\assets\logo"
artifact_dir = r"C:\Users\Salah eddine\.gemini\antigravity-ide\brain\c6e9ea42-d199-4bd9-8266-392859f82a44"

# Source transparent image
src_transparent = os.path.join(logo_dir, "Green and White Simple Al-Kareem Qur'an Center Logo.png")
if not os.path.exists(src_transparent):
    src_transparent = os.path.join(logo_dir, "hkquran_app_icon.png")

img_rgba = Image.open(src_transparent).convert("RGBA")

# 1. Standardize hkquran_logo_transparent.png
img_rgba.save(os.path.join(logo_dir, "hkquran_logo_transparent.png"), format="PNG")

# 2. Extract Emblem Only (Quran + Calligraphy)
# Bounding box of emblem roughly y=490 to 1100, x=400 to 1600
emblem_crop = img_rgba.crop((350, 480, 1650, 1120))
# Center emblem in a square canvas 1024x1024
emblem_w, emblem_h = emblem_crop.size
target_size = 1024
scale = min(800 / emblem_w, 800 / emblem_h)
new_w = int(emblem_w * scale)
new_h = int(emblem_h * scale)
emblem_resized = emblem_crop.resize((new_w, new_h), Image.Resampling.LANCZOS)

# A. Transparent Emblem
emblem_square_trans = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
emblem_square_trans.paste(emblem_resized, ((target_size - new_w) // 2, (target_size - new_h) // 2), emblem_resized)
emblem_square_trans.save(os.path.join(logo_dir, "hkquran_emblem_transparent.png"), format="PNG")

# B. Elegant App Tile / Squircle (Optimized for Windows Taskbar & System Tray)
# Soft rounded squircle with subtle cream/warm off-white or dark emerald
squircle_size = 1024
tile_img = Image.new("RGBA", (squircle_size, squircle_size), (0, 0, 0, 0))

# Create rounded mask for squircle
mask = Image.new("L", (squircle_size, squircle_size), 0)
from PIL import ImageDraw
draw = ImageDraw.Draw(mask)
corner_radius = 220
draw.rounded_rectangle([20, 20, squircle_size - 20, squircle_size - 20], radius=corner_radius, fill=255)

# Background for Light Squircle: Soft luxury ivory/parchment with subtle emerald border
bg_light = Image.new("RGBA", (squircle_size, squircle_size), (252, 250, 246, 255))
# draw subtle emerald border
draw_bg = ImageDraw.Draw(bg_light)
draw_bg.rounded_rectangle([20, 20, squircle_size - 20, squircle_size - 20], radius=corner_radius, outline=(30, 56, 55, 180), width=6)

# Paste emblem inside light squircle
bg_light.paste(emblem_resized, ((squircle_size - new_w) // 2, (squircle_size - new_h) // 2), emblem_resized)
tile_light = Image.new("RGBA", (squircle_size, squircle_size), (0, 0, 0, 0))
tile_light.paste(bg_light, (0, 0), mask)
tile_light.save(os.path.join(logo_dir, "hkquran_app_tile_light.png"), format="PNG")

# Background for Dark Squircle (Deep Emerald & Gold)
bg_dark = Image.new("RGBA", (squircle_size, squircle_size), (15, 28, 27, 255))
draw_dark = ImageDraw.Draw(bg_dark)
draw_dark.rounded_rectangle([20, 20, squircle_size - 20, squircle_size - 20], radius=corner_radius, outline=(245, 158, 11, 200), width=6)

# Convert emblem dark green elements to warm gold / cream for dark backgrounds
arr = np.array(emblem_resized)
# where color is dark green [30, 56, 55], recolor to gold [245, 180, 50]
r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
is_dark_green = (r < 60) & (g < 80) & (b < 80) & (a > 50)
arr_gold = arr.copy()
arr_gold[is_dark_green, 0] = 245
arr_gold[is_dark_green, 1] = 195
arr_gold[is_dark_green, 2] = 75
emblem_gold = Image.fromarray(arr_gold)

bg_dark.paste(emblem_gold, ((squircle_size - new_w) // 2, (squircle_size - new_h) // 2), emblem_gold)
tile_dark = Image.new("RGBA", (squircle_size, squircle_size), (0, 0, 0, 0))
tile_dark.paste(bg_dark, (0, 0), mask)
tile_dark.save(os.path.join(logo_dir, "hkquran_app_tile_dark.png"), format="PNG")

# 3. Create Multi-Resolution Windows ICO from the user's chosen logo
ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
# Use tile_light or emblem_square_trans
tile_light.save(os.path.join(logo_dir, "app_icon.ico"), format="ICO", sizes=ico_sizes)
tile_light.save(r"e:\Apps\new\windows\runner\resources\app_icon.ico", format="ICO", sizes=ico_sizes)
tile_light.save(r"e:\Apps\new\assets\app_icon.ico", format="ICO", sizes=ico_sizes)

# Copy to artifacts directory for preview
import shutil
shutil.copy(os.path.join(logo_dir, "hkquran_app_icon.png"), os.path.join(artifact_dir, "user_logo_main.png"))
shutil.copy(os.path.join(logo_dir, "hkquran_app_tile_light.png"), os.path.join(artifact_dir, "user_logo_tile_light.png"))
shutil.copy(os.path.join(logo_dir, "hkquran_app_tile_dark.png"), os.path.join(artifact_dir, "user_logo_tile_dark.png"))
shutil.copy(os.path.join(logo_dir, "hkquran_emblem_transparent.png"), os.path.join(artifact_dir, "user_logo_emblem.png"))

print("Suite generated and copied to artifacts.")
