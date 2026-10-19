import os
from PIL import Image

logo_dir = r"e:\Apps\new\assets\logo"
web_dir = r"e:\Apps\new\web"
web_icons_dir = os.path.join(web_dir, "icons")
os.makedirs(web_icons_dir, exist_ok=True)

# Master sources
master_square = os.path.join(logo_dir, "hkquran_app_icon.png")
master_emblem = os.path.join(logo_dir, "hkquran_emblem_transparent.png")
tile_dark = os.path.join(logo_dir, "hkquran_app_tile_dark.png")
tile_light = os.path.join(logo_dir, "hkquran_app_tile_light.png")

img_master = Image.open(master_square).convert("RGBA")
img_tile = Image.open(tile_dark).convert("RGBA")

# 1. Favicon (64x64 & 32x32)
favicon_64 = img_master.resize((64, 64), Image.Resampling.LANCZOS)
favicon_64.save(os.path.join(web_dir, "favicon.png"), format="PNG")
print("Saved web/favicon.png")

# Also save favicon.ico
img_master.save(os.path.join(web_dir, "favicon.ico"), format="ICO", sizes=[(64, 64), (32, 32), (16, 16)])
print("Saved web/favicon.ico")

# 2. PWA Standard Icons (192x192 and 512x512)
icon_192 = img_master.resize((192, 192), Image.Resampling.LANCZOS)
icon_192.save(os.path.join(web_icons_dir, "Icon-192.png"), format="PNG")

icon_512 = img_master.resize((512, 512), Image.Resampling.LANCZOS)
icon_512.save(os.path.join(web_icons_dir, "Icon-512.png"), format="PNG")
print("Saved web/icons/Icon-192.png and Icon-512.png")

# 3. Maskable PWA Icons (Safe zone padding: 80% content within dark emerald tile)
for size in [192, 512]:
    tile_resized = img_tile.resize((size, size), Image.Resampling.LANCZOS)
    tile_resized.save(os.path.join(web_icons_dir, f"Icon-maskable-{size}.png"), format="PNG")
print("Saved web/icons/Icon-maskable-192.png and Icon-maskable-512.png")

print("All web icon assets successfully updated.")
