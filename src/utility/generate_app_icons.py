#!/usr/bin/env python3
"""
generate_app_icons.py
Generates high-resolution, cohesive cyber/vector app icons for Poly Guard 2D.
Follows the exact visual style:
- Dark faceted tactical background (#0a1222, #070a12)
- Geometric shield / cyber polygon emblem with neon cyan / electric blue outlines
- Glowing concentric conduits and central core
- Standard main launcher icons (192x192, 512x512, 1024x1024)
- Android adaptive icon foreground (432x432) and background (432x432)
- Updates Android build res mipmaps directly
"""

import os
import math
from PIL import Image, ImageDraw

def get_project_root() -> str:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(current_dir, "..", ".."))

def draw_shield_badge(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, scale: float):
    """Draws a high-tech geometric defense crest / polygon shield."""
    pts = [
        (cx, cy - r * 0.95),                  # Top vertex
        (cx + r * 0.78, cy - r * 0.65),       # Upper right facet
        (cx + r * 0.88, cy + r * 0.10),       # Mid-right shoulder
        (cx + r * 0.55, cy + r * 0.70),       # Lower right taper
        (cx, cy + r * 1.02),                  # Bottom spear tip
        (cx - r * 0.55, cy + r * 0.70),       # Lower left taper
        (cx - r * 0.88, cy + r * 0.10),       # Mid-left shoulder
        (cx - r * 0.78, cy - r * 0.65),       # Upper left facet
    ]
    
    # Outer dark chassis
    draw.polygon(pts, fill=(12, 20, 35, 255), outline=(0, 240, 255, 255), width=int(5 * scale))
    
    # Inset facet ring
    inset_factor = 0.84
    pts_inner = [(cx + (px - cx) * inset_factor, cy + (py - cy) * inset_factor) for px, py in pts]
    draw.polygon(pts_inner, fill=(16, 28, 48, 255), outline=(0, 190, 220, 180), width=int(2.5 * scale))
    
    # Left / right shading division
    poly_left = [(cx, cy - r * 0.95 * inset_factor)] + pts_inner[5:] + [(cx, cy + r * 1.02 * inset_factor)]
    draw.polygon(poly_left, fill=(24, 40, 68, 120))
    
    # High-contrast neon cyan crease lines from center to outer vertices
    for px, py in pts_inner[::2]:
        draw.line([(cx, cy), (px, py)], fill=(0, 220, 255, 100), width=int(1.8 * scale))

def draw_core_emblem(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, scale: float):
    """Draws the glowing central reactor core with satellite nodes and crosshairs."""
    c_cyan_neon = (0, 245, 255, 255)
    c_cyan_bright = (180, 255, 255, 255)
    c_white = (255, 255, 255, 255)
    c_dark_core = (8, 16, 28, 255)
    
    # Cardinal and diagonal circuit conduit arms
    arm_len = r * 0.58
    for i in range(4):
        ang = i * (math.pi / 2.0) + (math.pi / 4.0)
        cos_a, sin_a = math.cos(ang), math.sin(ang)
        x2 = cx + cos_a * arm_len
        y2 = cy + sin_a * arm_len
        
        # Conduit line
        draw.line([(cx, cy), (x2, y2)], fill=c_cyan_neon, width=int(3 * scale))
        
        # Node diamond pad
        draw.regular_polygon((x2, y2, 6 * scale), 4, rotation=45, fill=c_dark_core, outline=c_cyan_neon, width=int(2 * scale))
        draw.regular_polygon((x2, y2, 3 * scale), 4, rotation=45, fill=c_cyan_bright)

    # Concentric orbital defense rings
    draw.ellipse([cx - r * 0.42, cy - r * 0.42, cx + r * 0.42, cy + r * 0.42], fill=c_dark_core, outline=c_cyan_neon, width=int(3.5 * scale))
    draw.ellipse([cx - r * 0.32, cy - r * 0.32, cx + r * 0.32, cy + r * 0.32], fill=(14, 26, 44, 255), outline=(0, 180, 215, 160), width=int(2 * scale))

    # Inner glowing polygon / diamond reactor
    draw.regular_polygon((cx, cy, r * 0.22), 4, rotation=45, fill=c_cyan_neon, outline=c_white, width=int(2.5 * scale))
    draw.regular_polygon((cx, cy, r * 0.12), 4, rotation=45, fill=c_white)

def generate_full_icon(size: int = 512) -> Image.Image:
    """Generates standard full standalone launcher icon with square/rounded base."""
    scale = size / 128.0
    ss = 2
    sw, sh = int(size * ss), int(size * ss)
    scale_ss = scale * ss
    
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = sw / 2.0, sh / 2.0
    
    # Background squircle / rounded rect container
    corner_r = 28 * scale_ss
    bg_margin = 4 * scale_ss
    draw.rounded_rectangle([bg_margin, bg_margin, sw - bg_margin, sh - bg_margin], radius=corner_r, fill=(7, 11, 20, 255), outline=(0, 180, 210, 255), width=int(3 * scale_ss))
    
    # Subtle inner border
    draw.rounded_rectangle([bg_margin + 4 * scale_ss, bg_margin + 4 * scale_ss, sw - bg_margin - 4 * scale_ss, sh - bg_margin - 4 * scale_ss], radius=corner_r - 4 * scale_ss, outline=(0, 240, 255, 70), width=int(1.5 * scale_ss))
    
    # Main defense emblem
    r = 44 * scale_ss
    draw_shield_badge(draw, cx, cy, r, scale_ss)
    draw_core_emblem(draw, cx, cy, r, scale_ss)
    
    return img.resize((size, size), Image.Resampling.LANCZOS)

def generate_adaptive_foreground(size: int = 432) -> Image.Image:
    """Generates Android adaptive icon foreground layer (transparent background)."""
    scale = size / 128.0
    ss = 2
    sw, sh = int(size * ss), int(size * ss)
    scale_ss = scale * ss
    
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = sw / 2.0, sh / 2.0
    
    # Emblem sized appropriately for adaptive safe-zone (inner 66%)
    r = 30 * scale_ss
    draw_shield_badge(draw, cx, cy, r, scale_ss)
    draw_core_emblem(draw, cx, cy, r, scale_ss)
    
    return img.resize((size, size), Image.Resampling.LANCZOS)

def generate_adaptive_background(size: int = 432) -> Image.Image:
    """Generates Android adaptive icon background layer (solid/patterned)."""
    scale = size / 128.0
    ss = 2
    sw, sh = int(size * ss), int(size * ss)
    scale_ss = scale * ss
    
    img = Image.new("RGBA", (sw, sh), (7, 11, 20, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = sw / 2.0, sh / 2.0
    
    # Subtle cyber grid / hex background pattern
    grid_spacing = 24 * scale_ss
    for x in range(0, sw + int(grid_spacing), int(grid_spacing)):
        draw.line([(x, 0), (x, sh)], fill=(14, 22, 38, 255), width=int(1.5 * scale_ss))
    for y in range(0, sh + int(grid_spacing), int(grid_spacing)):
        draw.line([(0, y), (sw, y)], fill=(14, 22, 38, 255), width=int(1.5 * scale_ss))
        
    # Concentric ambient radar circles
    for circ_r in [38 * scale_ss, 58 * scale_ss]:
        draw.ellipse([cx - circ_r, cy - circ_r, cx + circ_r, cy + circ_r], outline=(0, 200, 230, 40), width=int(1.5 * scale_ss))
        
    return img.resize((size, size), Image.Resampling.LANCZOS)

def generate_all_app_icons():
    root = get_project_root()
    icons_dir = os.path.join(root, "src", "textures", "app_icons")
    os.makedirs(icons_dir, exist_ok=True)
    
    print("Generating Poly Guard App Icons...")
    
    # 1. Primary icon sizes for launcher & exports
    icon_1024 = generate_full_icon(1024)
    icon_512 = generate_full_icon(512)
    icon_192 = generate_full_icon(192)
    
    p_1024 = os.path.join(icons_dir, "icon_1024.png")
    p_512 = os.path.join(icons_dir, "icon_512.png")
    p_192 = os.path.join(icons_dir, "icon_192.png")
    
    icon_1024.save(p_1024, "PNG")
    icon_512.save(p_512, "PNG")
    icon_192.save(p_192, "PNG")
    print(f"Saved: {p_1024}")
    print(f"Saved: {p_512}")
    print(f"Saved: {p_192}")
    
    # Also update root icon.png
    root_icon_png = os.path.join(root, "icon.png")
    icon_512.save(root_icon_png, "PNG")
    print(f"Saved: {root_icon_png}")
    
    # 2. Adaptive Icons
    fg_432 = generate_adaptive_foreground(432)
    bg_432 = generate_adaptive_background(432)
    
    p_fg = os.path.join(icons_dir, "adaptive_foreground_432.png")
    p_bg = os.path.join(icons_dir, "adaptive_background_432.png")
    fg_432.save(p_fg, "PNG")
    bg_432.save(p_bg, "PNG")
    print(f"Saved: {p_fg}")
    print(f"Saved: {p_bg}")
    
    # 3. Android build template mipmap sync
    android_res = os.path.join(root, "android", "build", "res")
    if os.path.exists(android_res):
        density_map = {
            "mipmap-mdpi-v4": (48, 108),
            "mipmap-hdpi-v4": (72, 162),
            "mipmap-xhdpi-v4": (96, 216),
            "mipmap-xxhdpi-v4": (144, 324),
            "mipmap-xxxhdpi-v4": (192, 432),
            "mipmap": (192, 432),
        }
        for folder, (icon_sz, adapt_sz) in density_map.items():
            fpath = os.path.join(android_res, folder)
            if os.path.exists(fpath):
                ic = generate_full_icon(icon_sz)
                ic.save(os.path.join(fpath, "icon.webp"), "WEBP")
                afg = generate_adaptive_foreground(adapt_sz)
                afg.save(os.path.join(fpath, "icon_foreground.webp"), "WEBP")
                abg = generate_adaptive_background(adapt_sz)
                abg.save(os.path.join(fpath, "icon_background.webp"), "WEBP")
        
        drawable_dir = os.path.join(android_res, "drawable")
        if os.path.exists(drawable_dir):
            sp_icon = generate_full_icon(64)
            sp_icon.save(os.path.join(drawable_dir, "splash_icon.webp"), "WEBP")
        print("Updated Android build res mipmaps.")

if __name__ == "__main__":
    generate_all_app_icons()
