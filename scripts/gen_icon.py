#!/usr/bin/env python3
"""docoach アプリアイコン生成スクリプト"""
from PIL import Image, ImageDraw, ImageFont
import os

OUT = os.path.join(os.path.dirname(__file__),
                   "../docoach/Assets.xcassets/AppIcon.appiconset")

VARIANTS = [
    ("AppIcon.png",        "#1C2B4A", "#FFFFFF"),  # light
    ("AppIcon-dark.png",   "#1C2B4A", "#FFFFFF"),  # dark
    ("AppIcon-tinted.png", "#3A3A3A", "#FFFFFF"),  # tinted
]

SIZE = 1024
TEXT = "dc"

def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def make_icon(filename, bg_hex, fg_hex):
    img = Image.new("RGB", (SIZE, SIZE), hex_to_rgb(bg_hex))
    draw = ImageDraw.Draw(img)

    # フォント（Helvetica Bold → 代替で Arial Bold）
    font_size = 420
    font = None
    for path in [
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Bold.ttf",
        "/System/Library/Fonts/SFCompact.ttf",
    ]:
        if os.path.exists(path):
            try:
                font = ImageFont.truetype(path, font_size, index=1)
                break
            except Exception:
                continue
    if font is None:
        font = ImageFont.load_default()

    # テキストを中央に配置
    bbox = draw.textbbox((0, 0), TEXT, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (SIZE - w) / 2 - bbox[0]
    y = (SIZE - h) / 2 - bbox[1]
    draw.text((x, y), TEXT, fill=hex_to_rgb(fg_hex), font=font)

    img.save(os.path.join(OUT, filename))
    print(f"  ✓ {filename}")

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for args in VARIANTS:
        make_icon(*args)
    print("完了")
