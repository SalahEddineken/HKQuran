import os
from PIL import Image

logo_dir = r"e:\Apps\new\assets\logo"

old_files = [
    "hkquran_app_icon.html",
    "hkquran_app_icon.svg",
    "hkquran_flagship.html",
    "hkquran_flagship.png",
    "hkquran_flagship.svg",
    "hkquran_flagship_transparent.html",
    "hkquran_flagship_transparent.png",
    "hkquran_flagship_transparent.svg",
    "hkquran_transparent.html",
    "hkquran_transparent.png",
    "hkquran_transparent.svg",
    "hkquran_vinyl_logo.html",
    "hkquran_vinyl_logo.png",
    "hkquran_vinyl_logo.svg",
    "hkquran_banner.html",
    "hkquran_banner.png",
    "hkquran_banner.svg",
    "Green and White Simple Al-Kareem Qur'an Center Logo.png"
]

removed = []
for f in old_files:
    p = os.path.join(logo_dir, f)
    if os.path.exists(p):
        os.remove(p)
        removed.append(f)

print(f"Removed {len(removed)} old files:")
for r in removed:
    print(" -", r)

# Regenerate standard sizes from user's master logo
master_path = os.path.join(logo_dir, "hkquran_app_icon.png")
if os.path.exists(master_path):
    img = Image.open(master_path)
    for size in [512, 256, 128, 64, 32]:
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(logo_dir, f"icon_{size}.png"))
    print("Successfully regenerated icon sizes (512, 256, 128, 64, 32) from user logo.")
