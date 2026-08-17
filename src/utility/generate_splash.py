#!/usr/bin/env python3
"""
generate_splash.py
Generates the clean minimalist portrait splash screen (1080x1920) for Poly Guard
featuring the centered tactical POLY GUARD logo banner over a solid dark background.
"""

import os
from PIL import Image, ImageDraw, ImageFont

def get_project_root() -> str:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(current_dir, "..", ".."))

def generate_splash(output_path: str = None, width: int = 1080, height: int = 1920) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "splash.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    root = get_project_root()
    
    # 2x supersampling for pristine antialiased typography & border lines
    ss = 2
    sw, sh = width * ss, height * ss
    
    # Clean solid dark background
    bg_color = (8, 12, 22, 255)
    base = Image.new("RGBA", (sw, sh), bg_color)
    
    cx, cy = sw / 2.0, sh / 2.0
    
    # -------------------------------------------------------------
    # Centered Tactical "POLY GUARD" Banner
    # -------------------------------------------------------------
    font_bold_path = os.path.join(root, "vendor", "Severin Meyer", "Oxanium-Bold.ttf")
    if os.path.exists(font_bold_path):
        font_title = ImageFont.truetype(font_bold_path, size=int(124 * ss))
    else:
        font_title = ImageFont.load_default()

    logo_layer = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    ld = ImageDraw.Draw(logo_layer)
    
    badge_w = int(920 * ss)
    badge_h = int(220 * ss)
    bx1 = cx - badge_w / 2.0
    by1 = cy - badge_h / 2.0
    bx2 = cx + badge_w / 2.0
    by2 = cy + badge_h / 2.0
    cut = int(34 * ss)
    
    badge_poly = [
        (bx1 + cut, by1),
        (bx2 - cut, by1),
        (bx2, by1 + cut),
        (bx2, by2 - cut),
        (bx2 - cut, by2),
        (bx1 + cut, by2),
        (bx1, by2 - cut),
        (bx1, by1 + cut)
    ]
    
    # Frosted Panel
    ld.polygon(badge_poly, fill=(10, 18, 34, 255))
    # Electric Cyan Neon Outer Border
    ld.polygon(badge_poly, outline=(0, 240, 220, 255), width=int(3.5 * ss))
    
    # Inner border line
    badge_inner = [
        (bx1 + cut + 6 * ss, by1 + 6 * ss),
        (bx2 - cut - 6 * ss, by1 + 6 * ss),
        (bx2 - 6 * ss, by1 + cut + 6 * ss),
        (bx2 - 6 * ss, by2 - cut - 6 * ss),
        (bx2 - cut - 6 * ss, by2 - 6 * ss),
        (bx1 + cut + 6 * ss, by2 - 6 * ss),
        (bx1 + 6 * ss, by2 - cut - 6 * ss),
        (bx1 + 6 * ss, by1 + cut + 6 * ss)
    ]
    ld.polygon(badge_inner, outline=(0, 240, 220, 120), width=int(1.5 * ss))
    
    # Corner accent gold pins
    for px, py in [(bx1, by1), (bx2, by1), (bx2, by2), (bx1, by2)]:
        ld.rectangle([px - 5 * ss, py - 5 * ss, px + 5 * ss, py + 5 * ss], fill=(255, 215, 50, 255))

    # Main Title: "POLY GUARD" (Centered inside banner)
    title_text = "POLY GUARD"
    t_bbox = font_title.getbbox(title_text)
    tw = t_bbox[2] - t_bbox[0]
    th = t_bbox[3] - t_bbox[1]
    tx = cx - tw / 2.0
    ty = cy - th / 2.0 - int(10 * ss)
    
    # Text drop shadow
    ld.text((tx + 4 * ss, ty + 6 * ss), title_text, font=font_title, fill=(0, 0, 0, 220))
    # Outer cyan bloom
    for off in [-3 * ss, 3 * ss]:
        ld.text((tx + off, ty), title_text, font=font_title, fill=(0, 240, 220, 120))
        ld.text((tx, ty + off), title_text, font=font_title, fill=(0, 240, 220, 120))
    # Crisp white core text
    ld.text((tx, ty), title_text, font=font_title, fill=(250, 255, 255, 255))

    base.alpha_composite(logo_layer)

    # -------------------------------------------------------------
    # High-Quality Lanczos Downsampling to 1080x1920
    # -------------------------------------------------------------
    final_img = base.resize((width, height), Image.Resampling.LANCZOS)
    final_img.save(output_path)
    print(f"Generated Clean Portrait Splash Screen (1080x1920): {output_path}")
    return output_path

if __name__ == "__main__":
    generate_splash()
