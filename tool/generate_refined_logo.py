import os
import subprocess
from PIL import Image

output_dir = r"e:\Apps\new\assets\logo"
os.makedirs(output_dir, exist_ok=True)
chrome_exe = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

# Refined Design 1: Flagship Masterpiece (The Sacred Mushaf, Rehal & Golden Recitation Waves)
svg_flagship = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <!-- Background Gradients -->
    <radialGradient id="bgGrad" cx="50%" cy="38%" r="72%">
      <stop offset="0%" stop-color="#161F33"/>
      <stop offset="40%" stop-color="#0D1322"/>
      <stop offset="75%" stop-color="#060912"/>
      <stop offset="100%" stop-color="#020306"/>
    </radialGradient>
    
    <radialGradient id="ambientGlow" cx="50%" cy="42%" r="48%">
      <stop offset="0%" stop-color="#F59E0B" stop-opacity="0.45"/>
      <stop offset="35%" stop-color="#D97706" stop-opacity="0.18"/>
      <stop offset="70%" stop-color="#4F46E5" stop-opacity="0.04"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>

    <!-- Multi-stop Luxury Gold Gradients -->
    <linearGradient id="goldBright" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="20%" stop-color="#FEF08A"/>
      <stop offset="45%" stop-color="#F59E0B"/>
      <stop offset="75%" stop-color="#D97706"/>
      <stop offset="100%" stop-color="#92400E"/>
    </linearGradient>

    <linearGradient id="goldPageLeft" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFBEB"/>
      <stop offset="30%" stop-color="#FEF3C7"/>
      <stop offset="70%" stop-color="#FDE68A"/>
      <stop offset="100%" stop-color="#D97706"/>
    </linearGradient>

    <linearGradient id="goldPageRight" x1="100%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFBEB"/>
      <stop offset="30%" stop-color="#FEF3C7"/>
      <stop offset="70%" stop-color="#FDE68A"/>
      <stop offset="100%" stop-color="#D97706"/>
    </linearGradient>

    <linearGradient id="goldSpine" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#92400E"/>
      <stop offset="50%" stop-color="#FEF08A"/>
      <stop offset="100%" stop-color="#78350F"/>
    </linearGradient>

    <linearGradient id="rehalGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#D97706"/>
      <stop offset="50%" stop-color="#92400E"/>
      <stop offset="100%" stop-color="#451A03"/>
    </linearGradient>

    <linearGradient id="borderGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FDE68A" stop-opacity="0.85"/>
      <stop offset="30%" stop-color="#F59E0B" stop-opacity="0.3"/>
      <stop offset="70%" stop-color="#D97706" stop-opacity="0.7"/>
      <stop offset="100%" stop-color="#78350F" stop-opacity="0.2"/>
    </linearGradient>

    <linearGradient id="waveGrad" x1="0%" y1="100%" x2="0%" y2="0%">
      <stop offset="0%" stop-color="#D97706"/>
      <stop offset="30%" stop-color="#F59E0B"/>
      <stop offset="70%" stop-color="#FDE047"/>
      <stop offset="100%" stop-color="#FFFFFF"/>
    </linearGradient>

    <!-- Filters -->
    <filter id="softGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="14" result="blur"/>
      <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>

    <filter id="starGlow" x="-60%" y="-60%" width="220%" height="220%">
      <feGaussianBlur stdDeviation="24" result="blur2"/>
      <feComposite in="SourceGraphic" in2="blur2" operator="over"/>
    </filter>

    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="16" stdDeviation="18" flood-color="#000000" flood-opacity="0.85"/>
    </filter>
  </defs>

  <!-- 1. Squircle Canvas -->
  <rect x="20" y="20" width="984" height="984" rx="224" fill="url(#bgGrad)"/>
  <rect x="22" y="22" width="980" height="980" rx="222" fill="none" stroke="url(#borderGrad)" stroke-width="4"/>

  <!-- 2. Ambient Golden Light -->
  <circle cx="512" cy="430" r="380" fill="url(#ambientGlow)"/>

  <!-- 3. Islamic Sacred Geometry Rosette Watermark -->
  <g opacity="0.09" stroke="#FDE68A" stroke-width="1.5" fill="none">
    <circle cx="512" cy="430" r="280"/>
    <circle cx="512" cy="430" r="340" stroke-dasharray="8 6"/>
    <circle cx="512" cy="430" r="390"/>
    <!-- 12-pointed rosette rays -->
    <polygon points="512,150 540,350 740,320 590,430 740,540 540,510 512,710 484,510 284,540 434,430 284,320 484,350"/>
    <polygon points="512,150 540,350 740,320 590,430 740,540 540,510 512,710 484,510 284,540 434,430 284,320 484,350" transform="rotate(30 512 430)"/>
  </g>

  <!-- 4. REHAL (TRADITIONAL CARVED WOODEN BOOKSTAND) -->
  <g filter="url(#shadow)">
    <!-- Rear crossing Rehal shadow / depth -->
    <path d="M430 590 L340 710 Q512 660 684 710 L594 590 Z" fill="#2A1405" opacity="0.8"/>

    <!-- Left Leg of Rehal -->
    <path d="M420 580 
             L310 705 
             C330 715, 360 720, 390 715 
             L465 620 
             L512 650 
             L450 575 Z" 
          fill="url(#rehalGrad)" stroke="#F59E0B" stroke-width="1.5" stroke-opacity="0.5"/>

    <!-- Right Leg of Rehal (Interlocking front) -->
    <path d="M604 580 
             L714 705 
             C694 715, 664 720, 634 715 
             L559 620 
             L512 650 
             L574 575 Z" 
          fill="url(#rehalGrad)" stroke="#F59E0B" stroke-width="1.5" stroke-opacity="0.5"/>

    <!-- Moorish Cutout Arch in Rehal Center Base -->
    <path d="M440 710 C460 670, 512 655, 512 655 C512 655, 564 670, 584 710 Z" fill="#0A0E17"/>
    <path d="M440 710 C460 670, 512 655, 512 655 C512 655, 564 670, 584 710" fill="none" stroke="url(#goldBright)" stroke-width="2.5"/>
  </g>

  <!-- 5. AUDIO FREQUENCY SOUNDWAVES (RISING FROM VERSES) -->
  <g filter="url(#softGlow)">
    <!-- 7 Equalizer Pillars symbolizing 7 Sab'a Mathani (Surah Al-Fatiha) -->
    <!-- Bar 1 (Outer Left) -->
    <rect x="360" y="340" width="14" height="85" rx="7" fill="url(#waveGrad)" opacity="0.7"/>
    <!-- Bar 2 -->
    <rect x="400" y="295" width="14" height="145" rx="7" fill="url(#waveGrad)" opacity="0.82"/>
    <!-- Bar 3 -->
    <rect x="440" y="250" width="14" height="205" rx="7" fill="url(#waveGrad)" opacity="0.94"/>
    
    <!-- Central Wave Pillar -->
    <rect x="505" y="215" width="14" height="255" rx="7" fill="url(#waveGrad)"/>

    <!-- Bar 5 -->
    <rect x="570" y="250" width="14" height="205" rx="7" fill="url(#waveGrad)" opacity="0.94"/>
    <!-- Bar 6 -->
    <rect x="610" y="295" width="14" height="145" rx="7" fill="url(#waveGrad)" opacity="0.82"/>
    <!-- Bar 7 (Outer Right) -->
    <rect x="650" y="340" width="14" height="85" rx="7" fill="url(#waveGrad)" opacity="0.7"/>
  </g>

  <!-- 6. SACRED RUB EL HIZB (8-POINTED DIVINE STAR) -->
  <g filter="url(#starGlow)" transform="translate(512, 175)">
    <!-- Square 1 -->
    <rect x="-26" y="-26" width="52" height="52" rx="7" fill="url(#goldBright)"/>
    <!-- Square 2 rotated 45deg -->
    <rect x="-26" y="-26" width="52" height="52" rx="7" fill="url(#goldBright)" transform="rotate(45)"/>
    <!-- Center circle and jewel -->
    <circle cx="0" cy="0" r="14" fill="#0D1322"/>
    <circle cx="0" cy="0" r="8" fill="#FFFBEB"/>
    <!-- Radiating divine light sparkles -->
    <path d="M0 -46 L4 -10 L46 0 L4 10 L0 46 L-4 10 L-46 0 L-4 -10 Z" fill="#FFFFFF" opacity="0.95"/>
    <circle cx="0" cy="0" r="3" fill="#FFFFFF"/>
  </g>

  <!-- 7. THE SACRED MUSHAF (ELEGANT OPEN BOOK) -->
  <g filter="url(#shadow)">
    <!-- Bottom Cover / Leather Binding Trim -->
    <!-- Left Cover -->
    <path d="M512 605 
             C470 595, 340 560, 230 475 
             L224 495 
             C334 580, 464 615, 512 625 Z" 
          fill="#78350F" stroke="#F59E0B" stroke-width="1.5"/>
    <!-- Right Cover -->
    <path d="M512 605 
             C554 595, 684 560, 794 475 
             L800 495 
             C690 580, 560 615, 512 625 Z" 
          fill="#78350F" stroke="#F59E0B" stroke-width="1.5"/>

    <!-- Gilded Golden Page Rim (Page Stack Depth) -->
    <path d="M230 475 C340 560, 470 595, 512 605 C554 595, 684 560, 794 475 L796 488 C686 573, 556 608, 512 618 C468 608, 338 573, 228 488 Z" 
          fill="url(#goldBright)"/>

    <!-- LEFT PAGE (Graceful Flowing Parchment Curve) -->
    <path d="M512 590 
             C460 575, 340 535, 236 455 
             C230 450, 230 440, 238 436 
             C350 420, 465 470, 512 510 Z" 
          fill="url(#goldPageLeft)" stroke="#D97706" stroke-width="1.5"/>

    <!-- Left Page Layer (Inner Page Shading) -->
    <path d="M512 565 
             C465 552, 355 515, 260 445 
             C255 442, 255 435, 262 432 
             C360 422, 465 465, 512 505 Z" 
          fill="url(#goldPageLeft)" opacity="0.85"/>

    <!-- Left Page Verses / Calligraphic Gold Foil Lines -->
    <g opacity="0.65" stroke="url(#goldBright)" stroke-linecap="round">
      <line x1="290" y1="455" x2="480" y2="520" stroke-width="3"/>
      <line x1="310" y1="475" x2="475" y2="538" stroke-width="2.5"/>
      <line x1="330" y1="495" x2="470" y2="556" stroke-width="2"/>
    </g>
    <!-- Left Page Surah Header Medallion -->
    <circle cx="380" cy="485" r="7" fill="url(#goldBright)" opacity="0.8"/>
    <circle cx="380" cy="485" r="4" fill="#0D1322"/>

    <!-- RIGHT PAGE (Graceful Flowing Parchment Curve) -->
    <path d="M512 590 
             C564 575, 684 535, 788 455 
             C794 450, 794 440, 786 436 
             C674 420, 559 470, 512 510 Z" 
          fill="url(#goldPageRight)" stroke="#D97706" stroke-width="1.5"/>

    <!-- Right Page Layer (Inner Page Shading) -->
    <path d="M512 565 
             C559 552, 669 515, 764 445 
             C769 442, 769 435, 762 432 
             C664 422, 559 465, 512 505 Z" 
          fill="url(#goldPageRight)" opacity="0.85"/>

    <!-- Right Page Verses / Calligraphic Gold Foil Lines -->
    <g opacity="0.65" stroke="url(#goldBright)" stroke-linecap="round">
      <line x1="734" y1="455" x2="544" y2="520" stroke-width="3"/>
      <line x1="714" y1="475" x2="549" y2="538" stroke-width="2.5"/>
      <line x1="694" y1="495" x2="554" y2="556" stroke-width="2"/>
    </g>
    <!-- Right Page Surah Header Medallion -->
    <circle cx="644" cy="485" r="7" fill="url(#goldBright)" opacity="0.8"/>
    <circle cx="644" cy="485" r="4" fill="#0D1322"/>

    <!-- Book Center Spine (Luminous Gilded Ridge) -->
    <path d="M508 506 Q512 502 516 506 L515 595 Q512 598 509 595 Z" fill="url(#goldSpine)"/>
    <line x1="512" y1="504" x2="512" y2="596" stroke="#FFFFFF" stroke-width="2" opacity="0.8"/>
  </g>

  <!-- 8. TYPOGRAPHY & BRANDING -->
  <g text-anchor="middle" id="brandText" filter="url(#shadow)">
    <!-- "HKQURAN" Primary Logotype -->
    <text x="512" y="812" 
          fill="url(#goldBright)" 
          font-family="system-ui, -apple-system, 'Segoe UI', Roboto, 'Cinzel', 'Trajan Pro', sans-serif" 
          font-size="64" 
          font-weight="900" 
          letter-spacing="18">HKQURAN</text>

    <!-- Refined Arabic Subtitle -->
    <text x="512" y="865" 
          fill="#FDE68A" 
          font-family="'Traditional Arabic', 'UthmanicHafs', 'Amiri', 'Segoe UI', serif" 
          font-size="28" 
          font-weight="600" 
          letter-spacing="5" 
          opacity="0.9">الـقُـرْآنُ الْـكَـرِيـمُ • تِـلَاوَةٌ وَخُـشُـوعٌ</text>
  </g>
</svg>'''

# Save Refined SVG
flagship_svg_path = os.path.join(output_dir, "hkquran_flagship.svg")
with open(flagship_svg_path, "w", encoding="utf-8") as f:
    f.write(svg_flagship)

# Create HTML wrapper
html_path = os.path.join(output_dir, "hkquran_flagship.html")
with open(html_path, "w", encoding="utf-8") as f:
    f.write(f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: 1024px; height: 1024px; overflow: hidden; background: transparent; }}
  svg {{ width: 1024px; height: 1024px; display: block; }}
</style>
</head>
<body>
{svg_flagship}
</body>
</html>''')

# Render to 1024x1024 PNG
png_path = os.path.join(output_dir, "hkquran_flagship.png")
cmd = [
    chrome_exe,
    "--headless=new",
    f"--screenshot={png_path}",
    "--window-size=1024,1024",
    "--default-background-color=00000000",
    "--hide-scrollbars",
    f"file:///{html_path.replace(os.sep, '/')}"
]
subprocess.run(cmd, check=True)
print("Rendered: hkquran_flagship.png (1024x1024)")

# Generate Transparent version (no squircle background)
svg_transparent = svg_flagship.replace('<rect x="20" y="20" width="984" height="984" rx="224" fill="url(#bgGrad)"/>', '').replace('<rect x="22" y="22" width="980" height="980" rx="222" fill="none" stroke="url(#borderGrad)" stroke-width="4"/>', '')
trans_svg_path = os.path.join(output_dir, "hkquran_flagship_transparent.svg")
with open(trans_svg_path, "w", encoding="utf-8") as f:
    f.write(svg_transparent)

trans_html_path = os.path.join(output_dir, "hkquran_flagship_transparent.html")
with open(trans_html_path, "w", encoding="utf-8") as f:
    f.write(f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: 1024px; height: 1024px; overflow: hidden; background: transparent; }}
  svg {{ width: 1024px; height: 1024px; display: block; }}
</style>
</head>
<body>
{svg_transparent}
</body>
</html>''')

trans_png_path = os.path.join(output_dir, "hkquran_flagship_transparent.png")
cmd = [
    chrome_exe,
    "--headless=new",
    f"--screenshot={trans_png_path}",
    "--window-size=1024,1024",
    "--default-background-color=00000000",
    "--hide-scrollbars",
    f"file:///{trans_html_path.replace(os.sep, '/')}"
]
subprocess.run(cmd, check=True)
print("Rendered: hkquran_flagship_transparent.png (1024x1024)")

# Generate Windows .ico with all sizes
img = Image.open(png_path)
ico_path = os.path.join(output_dir, "app_icon.ico")
img.save(ico_path, format="ICO", sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])

# Copy to windows resources so the app gets updated
win_ico = r"e:\Apps\new\windows\runner\resources\app_icon.ico"
img.save(win_ico, format="ICO", sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
print("Updated windows/runner/resources/app_icon.ico successfully.")
