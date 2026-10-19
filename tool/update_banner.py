import os
import subprocess
import shutil

output_dir = r"e:\Apps\new\assets\logo"
chrome_exe = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
artifact_dir = r"C:\Users\Salah eddine\.gemini\antigravity-ide\brain\c6e9ea42-d199-4bd9-8266-392859f82a44"

svg_banner = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1350 420" width="1350" height="420">
  <defs>
    <radialGradient id="hbgGrad" cx="30%" cy="50%" r="80%">
      <stop offset="0%" stop-color="#182236"/>
      <stop offset="50%" stop-color="#0E1322"/>
      <stop offset="85%" stop-color="#070912"/>
      <stop offset="100%" stop-color="#030408"/>
    </radialGradient>
    <linearGradient id="hGold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="25%" stop-color="#FEF08A"/>
      <stop offset="55%" stop-color="#F59E0B"/>
      <stop offset="85%" stop-color="#D97706"/>
      <stop offset="100%" stop-color="#92400E"/>
    </linearGradient>
    <linearGradient id="pageGold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFBEB"/>
      <stop offset="40%" stop-color="#FEF08A"/>
      <stop offset="100%" stop-color="#D97706"/>
    </linearGradient>
    <filter id="hGlow">
      <feGaussianBlur stdDeviation="12" result="b"/>
      <feComposite in="SourceGraphic" in2="b" operator="over"/>
    </filter>
    <filter id="hShadow">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.8"/>
    </filter>
  </defs>

  <!-- Background Card -->
  <rect x="12" y="12" width="1326" height="396" rx="44" fill="url(#hbgGrad)" stroke="#FDE68A" stroke-width="2.5" stroke-opacity="0.35"/>

  <!-- Left Icon Mark (Flagship emblem scaled) -->
  <g transform="translate(-10, -85) scale(0.55)" filter="url(#hShadow)">
    <!-- Stand -->
    <path d="M420 580 L310 705 C330 715, 360 720, 390 715 L465 620 L512 650 L450 575 Z" fill="#92400E"/>
    <path d="M604 580 L714 705 C694 715, 664 720, 634 715 L559 620 L512 650 L574 575 Z" fill="#92400E"/>
    <path d="M440 710 C460 670, 512 655, 512 655 C512 655, 564 670, 584 710" fill="none" stroke="url(#hGold)" stroke-width="3"/>

    <!-- Audio Bars -->
    <g filter="url(#hGlow)">
      <rect x="360" y="340" width="14" height="85" rx="7" fill="url(#hGold)" opacity="0.7"/>
      <rect x="400" y="295" width="14" height="145" rx="7" fill="url(#hGold)" opacity="0.82"/>
      <rect x="440" y="250" width="14" height="205" rx="7" fill="url(#hGold)" opacity="0.94"/>
      <rect x="505" y="215" width="14" height="255" rx="7" fill="url(#hGold)"/>
      <rect x="570" y="250" width="14" height="205" rx="7" fill="url(#hGold)" opacity="0.94"/>
      <rect x="610" y="295" width="14" height="145" rx="7" fill="url(#hGold)" opacity="0.82"/>
      <rect x="650" y="340" width="14" height="85" rx="7" fill="url(#hGold)" opacity="0.7"/>
    </g>

    <!-- Star -->
    <g transform="translate(512, 175)">
      <rect x="-26" y="-26" width="52" height="52" rx="7" fill="url(#hGold)"/>
      <rect x="-26" y="-26" width="52" height="52" rx="7" fill="url(#hGold)" transform="rotate(45)"/>
      <circle cx="0" cy="0" r="10" fill="#FFFFFF"/>
    </g>

    <!-- Book Pages -->
    <path d="M230 475 C340 560, 470 595, 512 605 C554 595, 684 560, 794 475 L796 488 C686 573, 556 608, 512 618 C468 608, 338 573, 228 488 Z" fill="url(#hGold)"/>
    <path d="M512 590 C460 575, 340 535, 236 455 C230 450, 230 440, 238 436 C350 420, 465 470, 512 510 Z" fill="url(#pageGold)"/>
    <path d="M512 590 C564 575, 684 535, 788 455 C794 450, 794 440, 786 436 C674 420, 559 470, 512 510 Z" fill="url(#pageGold)"/>
    <line x1="512" y1="504" x2="512" y2="596" stroke="#FFFFFF" stroke-width="3"/>
  </g>

  <!-- Divider Line -->
  <line x1="450" y1="85" x2="450" y2="335" stroke="#FDE68A" stroke-width="1.5" stroke-opacity="0.35"/>

  <!-- Brand Typography -->
  <g transform="translate(510, 0)" filter="url(#hShadow)">
    <text x="0" y="175" 
          fill="url(#hGold)" 
          font-family="system-ui, -apple-system, 'Segoe UI', Roboto, 'Cinzel', sans-serif" 
          font-size="80" 
          font-weight="900" 
          letter-spacing="16">HKQURAN</text>
    
    <text x="0" y="240" 
          fill="#FDE68A" 
          font-family="'Traditional Arabic', 'UthmanicHafs', 'Amiri', serif" 
          font-size="34" 
          font-weight="600" 
          letter-spacing="5" 
          opacity="0.95">الـقُـرْآنُ الْـكَـرِيـمُ • تِـلَاوَاتٌ وَأَذْكَـارٌ</text>

    <text x="0" y="300" 
          fill="#94A3B8" 
          font-family="system-ui, -apple-system, sans-serif" 
          font-size="19" 
          font-weight="600" 
          letter-spacing="4" 
          opacity="0.85">IMMERSIVE DESKTOP AUDIO PLAYER</text>
  </g>
</svg>'''

banner_svg_path = os.path.join(output_dir, "hkquran_banner.svg")
with open(banner_svg_path, "w", encoding="utf-8") as f:
    f.write(svg_banner)

banner_html_path = os.path.join(output_dir, "hkquran_banner.html")
with open(banner_html_path, "w", encoding="utf-8") as f:
    f.write(f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: 1350px; height: 420px; overflow: hidden; background: transparent; }}
  svg {{ width: 1350px; height: 420px; display: block; }}
</style>
</head>
<body>
{svg_banner}
</body>
</html>''')

banner_png_path = os.path.join(output_dir, "hkquran_banner.png")
cmd = [
    chrome_exe,
    "--headless=new",
    f"--screenshot={banner_png_path}",
    "--window-size=1350,420",
    "--default-background-color=00000000",
    "--hide-scrollbars",
    f"file:///{banner_html_path.replace(os.sep, '/')}"
]
subprocess.run(cmd, check=True)
shutil.copy(banner_png_path, os.path.join(artifact_dir, "hkquran_banner.png"))
print("Banner perfected and copied.")
