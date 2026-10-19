import os
import subprocess
from PIL import Image

output_dir = r"e:\Apps\new\assets\logo"
os.makedirs(output_dir, exist_ok=True)
chrome_exe = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

# 1. Concept 1: Flagship Squircle App Icon (Noor & Audio Quran)
svg_concept1 = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <!-- Background Gradients -->
    <radialGradient id="bgGrad" cx="50%" cy="40%" r="70%">
      <stop offset="0%" stop-color="#182236"/>
      <stop offset="45%" stop-color="#0E1322"/>
      <stop offset="85%" stop-color="#070912"/>
      <stop offset="100%" stop-color="#030408"/>
    </radialGradient>
    
    <radialGradient id="ambientGlow" cx="50%" cy="46%" r="50%">
      <stop offset="0%" stop-color="#E5A83B" stop-opacity="0.38"/>
      <stop offset="40%" stop-color="#C5851F" stop-opacity="0.14"/>
      <stop offset="75%" stop-color="#6B46C1" stop-opacity="0.04"/>
      <stop offset="100%" stop-color="#000" stop-opacity="0"/>
    </radialGradient>

    <!-- Luxury Gold Gradients -->
    <linearGradient id="goldLight" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFF5D6"/>
      <stop offset="25%" stop-color="#FDE047"/>
      <stop offset="50%" stop-color="#F59E0B"/>
      <stop offset="75%" stop-color="#D97706"/>
      <stop offset="100%" stop-color="#B45309"/>
    </linearGradient>

    <linearGradient id="goldReflect" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#D97706"/>
      <stop offset="30%" stop-color="#FEF08A"/>
      <stop offset="55%" stop-color="#F59E0B"/>
      <stop offset="85%" stop-color="#FEF9C3"/>
      <stop offset="100%" stop-color="#92400E"/>
    </linearGradient>

    <linearGradient id="borderGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FDE68A" stop-opacity="0.75"/>
      <stop offset="35%" stop-color="#D97706" stop-opacity="0.3"/>
      <stop offset="70%" stop-color="#B45309" stop-opacity="0.6"/>
      <stop offset="100%" stop-color="#78350F" stop-opacity="0.25"/>
    </linearGradient>

    <linearGradient id="waveGrad" x1="0%" y1="100%" x2="0%" y2="0%">
      <stop offset="0%" stop-color="#B45309"/>
      <stop offset="35%" stop-color="#F59E0B"/>
      <stop offset="70%" stop-color="#FDE047"/>
      <stop offset="100%" stop-color="#FFFBEB"/>
    </linearGradient>

    <!-- Filters -->
    <filter id="softGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="16" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>

    <filter id="starGlow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="22" result="blur2"/>
      <feComposite in="SourceGraphic" in2="blur2" operator="over"/>
    </filter>

    <filter id="shadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="16" stdDeviation="20" flood-color="#000000" flood-opacity="0.8"/>
    </filter>
  </defs>

  <!-- Squircle Base Canvas -->
  <rect x="24" y="24" width="976" height="976" rx="224" fill="url(#bgGrad)"/>
  
  <!-- Subtle Border Stroke -->
  <rect x="26" y="26" width="972" height="972" rx="222" fill="none" stroke="url(#borderGrad)" stroke-width="4"/>

  <!-- Ambient Light Sphere -->
  <circle cx="512" cy="450" r="380" fill="url(#ambientGlow)"/>

  <!-- Subtle Islamic Geometric Ring Background Pattern -->
  <g opacity="0.10" stroke="#FDE68A" stroke-width="1.5" fill="none">
    <circle cx="512" cy="450" r="280"/>
    <circle cx="512" cy="450" r="340" stroke-dasharray="6,6"/>
    <circle cx="512" cy="450" r="390"/>
    <polygon points="512,170 570,360 792,450 570,540 512,730 454,540 232,450 454,360"/>
    <polygon points="512,170 570,360 792,450 570,540 512,730 454,540 232,450 454,360" transform="rotate(45 512 450)"/>
  </g>

  <!-- MAIN EMBLEM GROUP -->
  <g filter="url(#shadow)">
    
    <!-- Sound Waves Rising From The Center Spine -->
    <g filter="url(#softGlow)">
      <!-- Wave Bar 1 (Outer Left) -->
      <rect x="332" y="360" width="14" height="65" rx="7" fill="url(#waveGrad)" opacity="0.65"/>
      <!-- Wave Bar 2 -->
      <rect x="368" y="325" width="14" height="110" rx="7" fill="url(#waveGrad)" opacity="0.78"/>
      <!-- Wave Bar 3 -->
      <rect x="404" y="295" width="14" height="155" rx="7" fill="url(#waveGrad)" opacity="0.88"/>
      <!-- Wave Bar 4 -->
      <rect x="440" y="270" width="14" height="195" rx="7" fill="url(#waveGrad)" opacity="0.96"/>
      
      <!-- Central Pillar Wave (Center Spine) -->
      <rect x="505" y="248" width="14" height="235" rx="7" fill="url(#goldLight)"/>

      <!-- Wave Bar 4 (Right) -->
      <rect x="570" y="270" width="14" height="195" rx="7" fill="url(#waveGrad)" opacity="0.96"/>
      <!-- Wave Bar 3 (Right) -->
      <rect x="606" y="295" width="14" height="155" rx="7" fill="url(#waveGrad)" opacity="0.88"/>
      <!-- Wave Bar 2 (Right) -->
      <rect x="642" y="325" width="14" height="110" rx="7" fill="url(#waveGrad)" opacity="0.78"/>
      <!-- Wave Bar 1 (Outer Right) -->
      <rect x="678" y="360" width="14" height="65" rx="7" fill="url(#waveGrad)" opacity="0.65"/>
    </g>

    <!-- Divine Star / Rub El Hizb at the Top of Center Wave -->
    <g filter="url(#starGlow)" transform="translate(512, 215)">
      <!-- Outer diamond 1 -->
      <rect x="-24" y="-24" width="48" height="48" rx="6" fill="url(#goldLight)"/>
      <!-- Outer diamond 2 (rotated 45) -->
      <rect x="-24" y="-24" width="48" height="48" rx="6" fill="url(#goldReflect)" transform="rotate(45)"/>
      <!-- Inner star core -->
      <circle cx="0" cy="0" r="11" fill="#FFFBEB"/>
      <!-- Brilliant sparkle cross -->
      <path d="M0 -40 L4 -8 L40 0 L4 8 L0 40 L-4 8 L-40 0 L-4 -8 Z" fill="#FFFFFF" opacity="0.9"/>
    </g>

    <!-- Quran Sacred Book Base / Stand (Rehal Foundation) -->
    <g>
      <path d="M370 655 C420 615, 470 590, 512 585 C554 590, 604 615, 654 655 C610 680, 558 695, 512 695 C466 695, 414 680, 370 655 Z" 
            fill="url(#goldReflect)" opacity="0.65"/>
      <path d="M415 660 Q512 625 609 660 L622 675 Q512 640 402 675 Z" fill="url(#goldLight)"/>
    </g>

    <!-- THE HOLY QURAN OPEN PAGES -->
    <!-- Left Wing / Book Page -->
    <path d="M512 580 
             C470 570, 340 535, 248 455 
             C238 446, 232 433, 235 420 
             C238 407, 249 397, 262 399
             C360 417, 465 473, 512 520 Z" 
          fill="url(#goldLight)"/>
    
    <!-- Left Wing Inner Page Shading / Page Depth -->
    <path d="M512 550 
             C472 541, 360 507, 280 437 
             C272 430, 268 419, 270 410
             C358 429, 458 483, 512 520 Z" 
          fill="url(#goldReflect)" opacity="0.92"/>
    
    <!-- Left Page Delicate Golden Flourish / Accent Lines -->
    <path d="M305 445 C380 467, 450 510, 495 545" stroke="#FFF7ED" stroke-width="2.5" stroke-linecap="round" fill="none" opacity="0.75"/>
    <path d="M335 465 C395 485, 445 523, 480 551" stroke="#FFF7ED" stroke-width="1.5" stroke-linecap="round" fill="none" opacity="0.45"/>

    <!-- Right Wing / Book Page -->
    <path d="M512 580 
             C554 570, 684 535, 776 455 
             C786 446, 792 433, 789 420 
             C786 407, 775 397, 762 399
             C664 417, 559 473, 512 520 Z" 
          fill="url(#goldReflect)"/>

    <!-- Right Wing Inner Page Shading -->
    <path d="M512 550 
             C552 541, 664 507, 744 437 
             C752 430, 756 419, 754 410
             C666 429, 566 483, 512 520 Z" 
          fill="url(#goldLight)" opacity="0.95"/>

    <!-- Right Page Delicate Golden Flourish / Accent Lines -->
    <path d="M719 445 C644 467, 574 510, 529 545" stroke="#FFF7ED" stroke-width="2.5" stroke-linecap="round" fill="none" opacity="0.75"/>
    <path d="M689 465 C629 485, 579 523, 544 551" stroke="#FFF7ED" stroke-width="1.5" stroke-linecap="round" fill="none" opacity="0.45"/>

    <!-- Book Center Spine Ridge -->
    <path d="M508 517 Q512 513 516 517 L515 583 Q512 585 509 583 Z" fill="#FFFBEB" filter="url(#softGlow)"/>

  </g>

  <!-- TYPOGRAPHY / BRAND NAME -->
  <g text-anchor="middle" id="brandText">
    <!-- "HKQURAN" Primary Logotype -->
    <text x="512" y="805" 
          fill="url(#goldLight)" 
          font-family="system-ui, -apple-system, 'Segoe UI', Roboto, 'Cinzel', 'Trajan Pro', sans-serif" 
          font-size="64" 
          font-weight="800" 
          letter-spacing="18"
          filter="url(#shadow)">HKQURAN</text>

    <!-- Elegant Arabic Subtitle -->
    <text x="512" y="860" 
          fill="#FDE68A" 
          font-family="'Traditional Arabic', 'UthmanicHafs', 'Amiri', 'Segoe UI', serif" 
          font-size="28" 
          font-weight="500" 
          letter-spacing="6" 
          opacity="0.85">القرآن الكريم • صوت وخشوع</text>
  </g>
</svg>'''

# 2. Concept 2: Transparent Emblem (Clean cut without squircle background)
svg_concept2 = svg_concept1.replace('<rect x="24" y="24" width="976" height="976" rx="224" fill="url(#bgGrad)"/>', '').replace('<rect x="26" y="26" width="972" height="972" rx="222" fill="none" stroke="url(#borderGrad)" stroke-width="4"/>', '')

# 3. Concept 3: Modern Minimalist Vinyl Quran Disc (Iconic circular edition)
svg_concept3 = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="discGrad" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#181D2E"/>
      <stop offset="60%" stop-color="#0E121F"/>
      <stop offset="85%" stop-color="#070912"/>
      <stop offset="100%" stop-color="#020306"/>
    </radialGradient>
    <linearGradient id="goldRim" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FEF08A"/>
      <stop offset="35%" stop-color="#F59E0B"/>
      <stop offset="70%" stop-color="#D97706"/>
      <stop offset="100%" stop-color="#78350F"/>
    </linearGradient>
    <linearGradient id="crescentGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFBEB"/>
      <stop offset="30%" stop-color="#FDE047"/>
      <stop offset="70%" stop-color="#F59E0B"/>
      <stop offset="100%" stop-color="#B45309"/>
    </linearGradient>
    <radialGradient id="centerGlow" cx="50%" cy="48%" r="45%">
      <stop offset="0%" stop-color="#F59E0B" stop-opacity="0.45"/>
      <stop offset="60%" stop-color="#D97706" stop-opacity="0.12"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <filter id="glow3">
      <feGaussianBlur stdDeviation="14" result="b"/>
      <feComposite in="SourceGraphic" in2="b" operator="over"/>
    </filter>
  </defs>

  <circle cx="512" cy="512" r="480" fill="url(#discGrad)"/>
  <circle cx="512" cy="512" r="474" fill="none" stroke="url(#goldRim)" stroke-width="6"/>

  <circle cx="512" cy="512" r="430" fill="none" stroke="#FDE68A" stroke-width="1.2" opacity="0.12"/>
  <circle cx="512" cy="512" r="385" fill="none" stroke="#FDE68A" stroke-width="1.5" stroke-dasharray="8 8" opacity="0.15"/>
  <circle cx="512" cy="512" r="340" fill="none" stroke="#FDE68A" stroke-width="1.2" opacity="0.1"/>
  <circle cx="512" cy="512" r="290" fill="none" stroke="#FDE68A" stroke-width="1.5" stroke-dasharray="12 6" opacity="0.18"/>

  <circle cx="512" cy="480" r="280" fill="url(#centerGlow)"/>

  <g filter="url(#glow3)">
    <path d="M470 190 C290 210 180 350 195 530 C210 700 360 805 525 805 C405 765 315 670 305 530 C295 390 375 270 470 190 Z" 
          fill="url(#crescentGrad)"/>
    
    <path d="M512 600 C460 590, 390 560, 350 500 C400 505, 470 535, 512 555 Z" fill="url(#crescentGrad)"/>
    <path d="M512 600 C564 590, 634 560, 674 500 C624 505, 554 535, 512 555 Z" fill="url(#goldRim)"/>

    <rect x="420" y="370" width="14" height="120" rx="7" fill="url(#crescentGrad)" opacity="0.8"/>
    <rect x="455" y="330" width="14" height="170" rx="7" fill="url(#crescentGrad)" opacity="0.9"/>
    <rect x="490" y="290" width="14" height="220" rx="7" fill="url(#crescentGrad)"/>
    <rect x="525" y="315" width="14" height="190" rx="7" fill="url(#crescentGrad)"/>
    <rect x="560" y="350" width="14" height="145" rx="7" fill="url(#crescentGrad)" opacity="0.9"/>
    <rect x="595" y="390" width="14" height="95" rx="7" fill="url(#crescentGrad)" opacity="0.8"/>

    <polygon points="512,220 520,240 542,242 525,258 530,280 512,268 494,280 499,258 482,242 504,240" fill="#FFFFFF"/>
  </g>

  <text x="512" y="735" 
        fill="url(#crescentGrad)" 
        font-family="system-ui, -apple-system, sans-serif" 
        font-size="52" 
        font-weight="800" 
        letter-spacing="14" 
        text-anchor="middle">HKQURAN</text>
  <text x="512" y="780" 
        fill="#FDE68A" 
        font-family="'Amiri', 'Traditional Arabic', serif" 
        font-size="24" 
        letter-spacing="4" 
        opacity="0.8" 
        text-anchor="middle">الـقـرآن الـكـريـم</text>
</svg>'''

# 4. Concept 4: Horizontal Header Logo (Emblem + Typography for Splash / Web / Documentation)
svg_horizontal = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 400" width="1200" height="400">
  <defs>
    <radialGradient id="hbgGrad" cx="30%" cy="50%" r="80%">
      <stop offset="0%" stop-color="#141B2D"/>
      <stop offset="60%" stop-color="#0A0E17"/>
      <stop offset="100%" stop-color="#04060A"/>
    </radialGradient>
    <linearGradient id="hGold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFF5D6"/>
      <stop offset="30%" stop-color="#FDE047"/>
      <stop offset="70%" stop-color="#F59E0B"/>
      <stop offset="100%" stop-color="#B45309"/>
    </linearGradient>
    <filter id="hGlow">
      <feGaussianBlur stdDeviation="12" result="b"/>
      <feComposite in="SourceGraphic" in2="b" operator="over"/>
    </filter>
  </defs>

  <!-- Background Card -->
  <rect x="10" y="10" width="1180" height="380" rx="40" fill="url(#hbgGrad)" stroke="#FDE68A" stroke-width="2" stroke-opacity="0.3"/>

  <!-- Left Icon Mark (Scaled down version of flagship emblem) -->
  <g transform="translate(40, -100) scale(0.6)">
    <!-- Main emblem elements -->
    <g filter="url(#hGlow)">
      <!-- Audio bars -->
      <rect x="332" y="360" width="14" height="65" rx="7" fill="url(#hGold)" opacity="0.65"/>
      <rect x="368" y="325" width="14" height="110" rx="7" fill="url(#hGold)" opacity="0.78"/>
      <rect x="404" y="295" width="14" height="155" rx="7" fill="url(#hGold)" opacity="0.88"/>
      <rect x="440" y="270" width="14" height="195" rx="7" fill="url(#hGold)" opacity="0.96"/>
      <rect x="505" y="248" width="14" height="235" rx="7" fill="url(#hGold)"/>
      <rect x="570" y="270" width="14" height="195" rx="7" fill="url(#hGold)" opacity="0.96"/>
      <rect x="606" y="295" width="14" height="155" rx="7" fill="url(#hGold)" opacity="0.88"/>
      <rect x="642" y="325" width="14" height="110" rx="7" fill="url(#hGold)" opacity="0.78"/>
      <rect x="678" y="360" width="14" height="65" rx="7" fill="url(#hGold)" opacity="0.65"/>
    </g>
    <!-- Star -->
    <g transform="translate(512, 215)">
      <rect x="-24" y="-24" width="48" height="48" rx="6" fill="url(#hGold)"/>
      <rect x="-24" y="-24" width="48" height="48" rx="6" fill="url(#hGold)" transform="rotate(45)"/>
      <circle cx="0" cy="0" r="10" fill="#FFFFFF"/>
    </g>
    <!-- Book Wings -->
    <path d="M512 580 C470 570, 340 535, 248 455 C238 446, 232 433, 235 420 C238 407, 249 397, 262 399 C360 417, 465 473, 512 520 Z" fill="url(#hGold)"/>
    <path d="M512 580 C554 570, 684 535, 776 455 C786 446, 792 433, 789 420 C786 407, 775 397, 762 399 C664 417, 559 473, 512 520 Z" fill="url(#hGold)"/>
  </g>

  <!-- Vertical Divider Line -->
  <line x1="440" y1="90" x2="440" y2="310" stroke="#FDE68A" stroke-width="1.5" stroke-opacity="0.3"/>

  <!-- Typography Right Side -->
  <g transform="translate(480, 0)">
    <text x="0" y="190" 
          fill="url(#hGold)" 
          font-family="system-ui, -apple-system, sans-serif" 
          font-size="78" 
          font-weight="900" 
          letter-spacing="16">HKQURAN</text>
    
    <text x="0" y="245" 
          fill="#FDE68A" 
          font-family="'Amiri', 'Traditional Arabic', serif" 
          font-size="30" 
          font-weight="600" 
          letter-spacing="4" 
          opacity="0.9">القرآن الكريم • تلاوات وأذكار</text>

    <text x="0" y="295" 
          fill="#94A3B8" 
          font-family="system-ui, -apple-system, sans-serif" 
          font-size="17" 
          font-weight="500" 
          letter-spacing="3" 
          opacity="0.8">IMMERSIVE DESKTOP AUDIO PLAYER</text>
  </g>
</svg>'''

files = [
    ("hkquran_app_icon.svg", svg_concept1, 1024, 1024, "hkquran_app_icon.png"),
    ("hkquran_transparent.svg", svg_concept2, 1024, 1024, "hkquran_transparent.png"),
    ("hkquran_vinyl_logo.svg", svg_concept3, 1024, 1024, "hkquran_vinyl_logo.png"),
    ("hkquran_banner.svg", svg_horizontal, 1200, 400, "hkquran_banner.png"),
]

for svg_name, svg_content, w, h, png_name in files:
    svg_path = os.path.join(output_dir, svg_name)
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(svg_content)
    
    # Create HTML wrapper for perfect headless Chrome rendering
    html_content = f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: {w}px; height: {h}px; overflow: hidden; background: transparent; }}
  svg {{ width: {w}px; height: {h}px; display: block; }}
</style>
</head>
<body>
{svg_content}
</body>
</html>'''
    html_path = os.path.join(output_dir, svg_name.replace(".svg", ".html"))
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    
    png_path = os.path.join(output_dir, png_name)
    cmd = [
        chrome_exe,
        "--headless=new",
        f"--screenshot={png_path}",
        f"--window-size={w},{h}",
        "--default-background-color=00000000",
        "--hide-scrollbars",
        f"file:///{html_path.replace(os.sep, '/')}"
    ]
    subprocess.run(cmd, check=True)
    print(f"Rendered: {png_name} ({w}x{h})")

# Generate sizes for app icons
base_icon_png = os.path.join(output_dir, "hkquran_app_icon.png")
if os.path.exists(base_icon_png):
    img = Image.open(base_icon_png)
    
    # 512x512
    img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(output_dir, "icon_512.png"))
    # 256x256
    img.resize((256, 256), Image.Resampling.LANCZOS).save(os.path.join(output_dir, "icon_256.png"))
    # 128x128
    img.resize((128, 128), Image.Resampling.LANCZOS).save(os.path.join(output_dir, "icon_128.png"))
    # 64x64
    img.resize((64, 64), Image.Resampling.LANCZOS).save(os.path.join(output_dir, "icon_64.png"))
    # 32x32
    img.resize((32, 32), Image.Resampling.LANCZOS).save(os.path.join(output_dir, "icon_32.png"))
    
    # Multi-resolution Windows .ico
    ico_path = os.path.join(output_dir, "app_icon.ico")
    img.save(ico_path, format="ICO", sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
    print("Generated multi-resolution ICO file:", ico_path)

print("All logos generated successfully.")
