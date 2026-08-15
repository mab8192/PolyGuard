#!/usr/bin/env python3
"""
generate_enemies.py
Generates clean, cropped geometric 2D vector-style enemy sprites for Poly Guard 2D.
"""

import os
from PIL import Image, ImageDraw

def get_project_root() -> str:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(current_dir, "..", ".."))

def create_supersampled(size: int = 64, factor: int = 4):
    ss_size = size * factor
    img = Image.new("RGBA", (ss_size, ss_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return img, draw, factor, ss_size

# 1. Grunt: Solid Beveled Cyan Diamond
def draw_grunt() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    r = 18 * f
    
    # Outer dark border
    draw.regular_polygon((cx, cy, r), 4, rotation=45, fill=(18, 55, 60, 255), outline=(0, 245, 212, 255), width=int(2.5 * f))
    
    p_top = (cx, cy - r + 3*f)
    p_right = (cx + r - 3*f, cy)
    p_bot = (cx, cy + r - 3*f)
    p_left = (cx - r + 3*f, cy)
    p_center = (cx, cy)
    
    draw.polygon([p_top, p_right, p_center], fill=(135, 205, 212, 255))
    draw.polygon([p_top, p_left, p_center], fill=(110, 185, 192, 255))
    draw.polygon([p_left, p_bot, p_center], fill=(80, 150, 158, 255))
    draw.polygon([p_right, p_bot, p_center], fill=(60, 125, 132, 255))
    
    draw.line([p_top, p_bot], fill=(200, 255, 250, 150), width=int(1.2 * f))
    draw.line([p_left, p_right], fill=(200, 255, 250, 150), width=int(1.2 * f))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 2. Heavy: Fortified Dark-Teal Armored Diamond
def draw_heavy() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    r_out = 23 * f
    
    draw.regular_polygon((cx, cy, r_out), 4, rotation=45, fill=(12, 38, 44, 255), outline=(0, 215, 235, 255), width=int(3.2 * f))
    
    r_mid = 18 * f
    draw.regular_polygon((cx, cy, r_mid), 4, rotation=45, fill=(22, 68, 76, 255), outline=(8, 28, 32, 255), width=int(2 * f))
    
    p_top = (cx, cy - r_mid + 2*f)
    p_right = (cx + r_mid - 2*f, cy)
    p_bot = (cx, cy + r_mid - 2*f)
    p_left = (cx - r_mid + 2*f, cy)
    p_center = (cx, cy)
    
    draw.polygon([p_top, p_right, p_center], fill=(55, 135, 145, 255))
    draw.polygon([p_top, p_left, p_center], fill=(42, 115, 125, 255))
    draw.polygon([p_left, p_bot, p_center], fill=(30, 90, 98, 255))
    draw.polygon([p_right, p_bot, p_center], fill=(22, 70, 78, 255))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 3. Light: Pure Hollow Transparent Wireframe Diamond
def draw_light() -> Image.Image:
    s = 256
    f = 4
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = s / 2, s / 2
    
    r_out = 14 * f
    r_in = 10.5 * f
    
    draw.regular_polygon((cx, cy, r_out), 4, rotation=45, fill=(0, 245, 212, 255), outline=(140, 255, 240, 255), width=int(1.5 * f))
    
    mask = Image.new("L", (s, s), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.regular_polygon((cx, cy, r_in), 4, rotation=45, fill=255)
    
    img_data = img.load()
    mask_data = mask.load()
    for y in range(s):
        for x in range(s):
            if mask_data[x, y] == 255:
                img_data[x, y] = (0, 0, 0, 0)
                
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 4. Tank: Armored Bulwark Wedge / Siege Ram
def draw_tank() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    
    pts = [
        (cx + 24 * f, cy),             # front prow tip
        (cx + 12 * f, cy - 20 * f),    # top front angled shoulder
        (cx - 20 * f, cy - 20 * f),    # top rear corner
        (cx - 22 * f, cy - 14 * f),    # rear notch top
        (cx - 22 * f, cy + 14 * f),    # rear notch bot
        (cx - 20 * f, cy + 20 * f),    # bot rear corner
        (cx + 12 * f, cy + 20 * f),    # bot front angled shoulder
    ]
    
    draw.polygon(pts, fill=(12, 38, 12, 255), outline=(40, 215, 40, 255), width=int(3 * f))
    
    p_upper = [
        (cx + 21 * f, cy),
        (cx + 10 * f, cy - 17 * f),
        (cx - 17 * f, cy - 17 * f),
        (cx - 19 * f, cy),
    ]
    draw.polygon(p_upper, fill=(45, 175, 40, 255))
    
    p_lower = [
        (cx + 21 * f, cy),
        (cx + 10 * f, cy + 17 * f),
        (cx - 17 * f, cy + 17 * f),
        (cx - 19 * f, cy),
    ]
    draw.polygon(p_lower, fill=(25, 120, 25, 255))
    
    draw.polygon([(cx + 21*f, cy), (cx + 10*f, cy - 17*f), (cx + 4*f, cy)], fill=(65, 215, 55, 255))
    draw.polygon([(cx + 21*f, cy), (cx + 10*f, cy + 17*f), (cx + 4*f, cy)], fill=(35, 150, 30, 255))
    
    draw.line([(cx - 18 * f, cy), (cx + 20 * f, cy)], fill=(120, 255, 110, 200), width=int(1.8 * f))
    draw.rectangle([(cx - 20*f, cy - 10*f), (cx - 14*f, cy + 10*f)], fill=(16, 50, 16, 255), outline=(30, 140, 30, 255), width=int(1.5*f))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 5. Sniper: Golden 4-Point Cross-Star
def draw_sniper() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    
    pts = [
        (cx + 24 * f, cy),             # front point
        (cx + 6 * f, cy - 6 * f),
        (cx + 2 * f, cy - 19 * f),     # top point
        (cx - 5 * f, cy - 6 * f),
        (cx - 17 * f, cy),            # back point
        (cx - 5 * f, cy + 6 * f),
        (cx + 2 * f, cy + 19 * f),     # bottom point
        (cx + 6 * f, cy + 6 * f),
    ]
    
    draw.polygon(pts, fill=(45, 35, 5, 255), outline=(255, 220, 30, 255), width=int(2.5 * f))
    
    draw.polygon([(cx + 21*f, cy), (cx + 5.5*f, cy - 5.5*f), (cx, cy)], fill=(245, 205, 35, 255))
    draw.polygon([(cx + 2*f, cy - 16.5*f), (cx + 5.5*f, cy - 5.5*f), (cx, cy)], fill=(255, 220, 55, 255))
    draw.polygon([(cx + 2*f, cy - 16.5*f), (cx - 4.5*f, cy - 5.5*f), (cx, cy)], fill=(215, 175, 20, 255))
    draw.polygon([(cx - 14.5*f, cy), (cx - 4.5*f, cy - 5.5*f), (cx, cy)], fill=(175, 135, 10, 255))
    draw.polygon([(cx - 14.5*f, cy), (cx - 4.5*f, cy + 5.5*f), (cx, cy)], fill=(155, 120, 5, 255))
    draw.polygon([(cx + 2*f, cy + 16.5*f), (cx - 4.5*f, cy + 5.5*f), (cx, cy)], fill=(185, 145, 15, 255))
    draw.polygon([(cx + 2*f, cy + 16.5*f), (cx + 5.5*f, cy + 5.5*f), (cx, cy)], fill=(210, 170, 25, 255))
    draw.polygon([(cx + 21*f, cy), (cx + 5.5*f, cy + 5.5*f), (cx, cy)], fill=(195, 155, 20, 255))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 6. Speeder: Aerodynamic Neon Yellow Arrowhead Dart
def draw_speeder() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    
    pts = [
        (cx + 21 * f, cy),            # nose
        (cx - 15 * f, cy - 15 * f),    # top wing
        (cx - 7 * f, cy - 4 * f),     # top notch
        (cx - 10 * f, cy),            # center notch
        (cx - 7 * f, cy + 4 * f),     # bottom notch
        (cx - 15 * f, cy + 15 * f),    # bottom wing
    ]
    
    draw.polygon(pts, fill=(50, 45, 0, 255), outline=(255, 245, 10, 255), width=int(2.5 * f))
    
    draw.polygon([(cx + 18.5*f, cy), (cx - 13*f, cy - 13*f), (cx - 6*f, cy - 3*f), (cx - 8*f, cy)], fill=(255, 240, 25, 255))
    draw.polygon([(cx + 18.5*f, cy), (cx - 13*f, cy + 13*f), (cx - 6*f, cy + 3*f), (cx - 8*f, cy)], fill=(225, 195, 0, 255))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 7. Ghost: Phased Spectral Translucent Kite
def draw_ghost() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    
    pts = [(cx + 21 * f, cy), (cx - 2 * f, cy - 16 * f), (cx - 19 * f, cy), (cx - 2 * f, cy + 16 * f)]
    
    draw.polygon([(cx + 23*f, cy), (cx - 2*f, cy - 18*f), (cx - 21*f, cy), (cx - 2*f, cy + 18*f)], fill=(160, 80, 245, 45))
    draw.polygon(pts, fill=(90, 30, 165, 190), outline=(220, 165, 255, 240), width=int(2.5 * f))
    draw.polygon([(cx + 18*f, cy), (cx - 2*f, cy - 13.5*f), (cx - 16*f, cy)], fill=(185, 115, 255, 170))
    draw.polygon([(cx + 18*f, cy), (cx - 2*f, cy + 13.5*f), (cx - 16*f, cy)], fill=(130, 55, 215, 170))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 8. Splitter: Tri-Segmented Dividing Polygon
def draw_splitter() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    r = 19 * f
    
    draw.regular_polygon((cx, cy, r), 6, rotation=0, fill=(15, 50, 56, 255), outline=(0, 245, 212, 255), width=int(2.5 * f))
    
    p0 = (cx, cy)
    p1 = (cx - 14 * f, cy - 9 * f)
    p2 = (cx, cy - 16 * f)
    p3 = (cx + 14 * f, cy - 9 * f)
    p4 = (cx + 14 * f, cy + 9 * f)
    p5 = (cx - 14 * f, cy + 9 * f)
    p6 = (cx, cy + 16 * f)
    
    draw.polygon([p0, p1, p2], fill=(100, 180, 190, 255), outline=(0, 255, 230, 255), width=int(1.5*f))
    draw.polygon([p0, p2, p3], fill=(70, 150, 160, 255), outline=(0, 255, 230, 255), width=int(1.5*f))
    draw.polygon([p0, p3, p4, p6], fill=(50, 125, 135, 255), outline=(0, 255, 230, 255), width=int(1.5*f))
    draw.polygon([p0, p6, p5, p1], fill=(60, 138, 148, 255), outline=(0, 255, 230, 255), width=int(1.5*f))
    
    draw.line([(cx, cy), (cx, cy - 16*f)], fill=(0, 255, 240, 255), width=int(2.5*f))
    draw.line([(cx, cy), (cx - 14*f, cy + 9*f)], fill=(0, 255, 240, 255), width=int(2.5*f))
    draw.line([(cx, cy), (cx + 14*f, cy + 9*f)], fill=(0, 255, 240, 255), width=int(2.5*f))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

# 9. Citadel: Monolithic Hexagon Apex Dreadnought
def draw_citadel() -> Image.Image:
    img, draw, f, s = create_supersampled(64, 4)
    cx, cy = s / 2, s / 2
    r = 25 * f
    
    draw.regular_polygon((cx, cy, r), 6, rotation=30, fill=(28, 30, 34, 255), outline=(190, 45, 60, 255), width=int(3 * f))
    
    ir = 19 * f
    draw.regular_polygon((cx, cy, ir), 6, rotation=30, fill=(52, 56, 62, 255), outline=(18, 20, 24, 255), width=int(2 * f))
    draw.polygon([(cx, cy), (cx - ir*0.866, cy - ir*0.5), (cx, cy - ir), (cx + ir*0.866, cy - ir*0.5)], fill=(72, 78, 86, 255))
    
    return img.resize((64, 64), Image.Resampling.LANCZOS)

GENERATORS = {
    "grunt.png": draw_grunt,
    "heavy.png": draw_heavy,
    "light.png": draw_light,
    "tank.png": draw_tank,
    "sniper.png": draw_sniper,
    "speeder.png": draw_speeder,
    "ghost.png": draw_ghost,
    "splitter.png": draw_splitter,
    "citadel.png": draw_citadel,
}

def generate_all_enemies(output_dir: str = None) -> list[str]:
    if output_dir is None:
        output_dir = os.path.join(get_project_root(), "src", "textures", "enemies")
    os.makedirs(output_dir, exist_ok=True)
    
    generated = []
    for name, gen_fn in GENERATORS.items():
        im = gen_fn()
        bbox = im.getbbox()
        if bbox:
            im = im.crop(bbox)
        target_path = os.path.join(output_dir, name)
        im.save(target_path, "PNG")
        print(f"Generated {name} (size: {im.size}) -> {target_path}")
        generated.append(target_path)
    return generated

if __name__ == "__main__":
    generate_all_enemies()
