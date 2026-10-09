"""Generate Foxpiry launcher + store assets from removebg master."""
from PIL import Image
import os

MASTER = 'assets/branding/fox.png'
TEAL = (15, 118, 110, 255)  # #0F766E
WHITE = (255, 255, 255, 255)
CREAM = (255, 247, 237, 255)

os.makedirs('assets/branding', exist_ok=True)
fox = Image.open(MASTER).convert('RGBA')
fox.save('assets/branding/fox.png')
print('master:', fox.size)

# Tight-crop to visible art so launcher icons fill the frame
# (fox.png carries wide transparent margins).
_alpha = fox.split()[3]
_bbox = _alpha.point(lambda v: 255 if v > 32 else 0).getbbox()
_pad = 12
_tight = fox.crop((
    max(0, _bbox[0] - _pad),
    max(0, _bbox[1] - _pad),
    min(fox.width, _bbox[2] + _pad),
    min(fox.height, _bbox[3] + _pad),
))
print('tight:', _tight.size)

def paste_center(bg_size, fox_frac, bg_color=None, img=None):
    """Fox centered at fox_frac of canvas (contain-fit). Transparent if bg_color None."""
    src = fox if img is None else img
    if bg_color is None:
        canvas = Image.new('RGBA', (bg_size, bg_size), (0, 0, 0, 0))
    else:
        canvas = Image.new('RGBA', (bg_size, bg_size), bg_color)
    s = int(bg_size * fox_frac)
    w, h = src.size
    scale = min(s / w, s / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    f = src.resize((nw, nh), Image.LANCZOS)
    canvas.paste(f, ((bg_size - nw) // 2, (bg_size - nh) // 2), f)
    return canvas

# 1. Play Store listing icon 512 (opaque white)
play = paste_center(512, 0.92, WHITE, _tight).convert('RGB')
play.save('assets/branding/play_icon_512.png')
print('play 512 ok')

# 2. Legacy mipmap launcher (opaque white) + round copies
dens = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for d, px in dens.items():
    p = f'android/app/src/main/res/mipmap-{d}'
    os.makedirs(p, exist_ok=True)
    icon = paste_center(px, 0.90, WHITE, _tight).convert('RGB')
    icon.save(f'{p}/ic_launcher.png')
    icon.save(f'{p}/ic_launcher_round.png')
print('legacy mipmaps ok')

# 3. Adaptive foreground (transparent, 108dp grid, fox in safe zone)
fore = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
for d, px in fore.items():
    p = f'android/app/src/main/res/mipmap-{d}'
    fg = paste_center(px, 0.64, None, _tight)
    fg.save(f'{p}/ic_launcher_foreground.png')
print('adaptive foregrounds ok')

# 4. anydpi adaptive xml
anydpi = 'android/app/src/main/res/mipmap-anydpi-v26'
os.makedirs(anydpi, exist_ok=True)
xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
open(f'{anydpi}/ic_launcher.xml', 'w').write(xml)
open(f'{anydpi}/ic_launcher_round.xml', 'w').write(xml)
print('adaptive xml ok')

# 5. splash source image (fox w/ padding, transparent)
splash = paste_center(1024, 0.55, None)
splash.save('assets/branding/splash_image.png')
print('splash source ok')
