#!/usr/bin/env python3
"""
generate_tower_variants.py
Generates cohesive, high-contrast cyber/neon vector textures for all 34 Poly Guard 2D tower specializations.
All textures are supersampled with Lanczos filtering and tightly cropped.
"""

import os
import math
from PIL import Image, ImageDraw

def get_project_root() -> str:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(current_dir, "..", ".."))

def create_canvas(width=64, height=64, factor=4):
    ss_w, ss_h = width * factor, height * factor
    img = Image.new("RGBA", (ss_w, ss_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return img, draw, factor, ss_w, ss_h

def save_cropped_sprite(img: Image.Image, size: tuple[int, int], output_path: str, label: str) -> str:
    final_img = img.resize(size, Image.Resampling.LANCZOS)
    bbox = final_img.getbbox()
    if bbox:
        final_img = final_img.crop(bbox)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    final_img.save(output_path, "PNG")
    print(f"Generated {label}: {output_path} (size: {final_img.size})")
    return output_path

VARIANTS_DIR = os.path.join(get_project_root(), "src", "textures", "towers", "variants")

# =========================================================================
# 1. ARCHER TOWER VARIANTS
# =========================================================================

def gen_archer_arcane():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_stone = (20, 22, 34, 255)
    c_stone_mid = (36, 40, 60, 255)
    c_violet_deck = (50, 30, 75, 255)
    c_arcane_cyan = (0, 235, 255, 255)
    c_arcane_purple = (185, 55, 255, 255)
    c_bright = (230, 250, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_stone, outline=(12, 14, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_stone_mid)
    
    # 4 Runic corner nodes
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx+ox, cy+oy, 4.5*f), 4, rotation=45, fill=c_stone, outline=c_arcane_cyan, width=int(1.2*f))
        draw.ellipse([cx+ox-1.5*f, cy+oy-1.5*f, cx+ox+1.5*f, cy+oy+1.5*f], fill=c_arcane_purple)

    deck_m = 11*f
    draw.rounded_rectangle([deck_m, deck_m, sw-deck_m, sh-deck_m], radius=2*f, fill=c_violet_deck, outline=c_arcane_purple, width=int(1.5*f))
    
    # Turret ring & glowing cross
    draw.ellipse([cx-15*f, cy-15*f, cx+15*f, cy+15*f], fill=c_stone, outline=c_arcane_cyan, width=int(2*f))
    draw.ellipse([cx-11*f, cy-11*f, cx+11*f, cy+11*f], fill=(25, 15, 40, 255))
    
    arrow_len = 13*f
    head_size = 5.0*f
    for i in range(4):
        ang = i * (math.pi / 2.0)
        tx, ty = cx + math.cos(ang) * arrow_len, cy + math.sin(ang) * arrow_len
        draw.line([cx, cy, tx, ty], fill=c_arcane_cyan, width=int(2.5*f))
        head_pts = [(tx, ty), (tx - math.cos(ang)*head_size - math.sin(ang)*head_size*0.7, ty - math.sin(ang)*head_size + math.cos(ang)*head_size*0.7),
                    (tx - math.cos(ang)*head_size + math.sin(ang)*head_size*0.7, ty - math.sin(ang)*head_size - math.cos(ang)*head_size*0.7)]
        draw.polygon(head_pts, fill=c_bright, outline=c_arcane_purple, width=int(1.2*f))

    draw.ellipse([cx-4.5*f, cy-4.5*f, cx+4.5*f, cy+4.5*f], fill=c_arcane_purple, outline=c_arcane_cyan, width=int(1.2*f))
    draw.ellipse([cx-2*f, cy-2*f, cx+2*f, cy+2*f], fill=c_bright)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "archer_tower_arcane.png"), "archer_tower_arcane")

def gen_archer_piercer():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_stone = (28, 20, 20, 255)
    c_stone_mid = (50, 36, 36, 255)
    c_deck = (40, 25, 25, 255)
    c_crimson = (245, 40, 40, 255)
    c_gold = (255, 200, 40, 255)
    c_steel = (250, 250, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_stone, outline=(18, 12, 12, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_stone_mid)
    
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx+ox, cy+oy, 4.5*f), 4, rotation=45, fill=c_stone, outline=c_gold, width=int(1.2*f))
        draw.ellipse([cx+ox-1.5*f, cy+oy-1.5*f, cx+ox+1.5*f, cy+oy+1.5*f], fill=c_crimson)

    deck_m = 11*f
    draw.rounded_rectangle([deck_m, deck_m, sw-deck_m, sh-deck_m], radius=2*f, fill=c_deck, outline=c_crimson, width=int(1.5*f))
    
    draw.ellipse([cx-15*f, cy-15*f, cx+15*f, cy+15*f], fill=c_stone, outline=c_gold, width=int(2*f))
    draw.ellipse([cx-11*f, cy-11*f, cx+11*f, cy+11*f], fill=(20, 15, 15, 255))
    
    arrow_len = 14*f
    head_size = 5.5*f
    for i in range(4):
        ang = i * (math.pi / 2.0)
        tx, ty = cx + math.cos(ang) * arrow_len, cy + math.sin(ang) * arrow_len
        draw.line([cx, cy, tx, ty], fill=c_gold, width=int(2.5*f))
        head_pts = [(tx, ty), (tx - math.cos(ang)*head_size - math.sin(ang)*head_size*0.5, ty - math.sin(ang)*head_size + math.cos(ang)*head_size*0.5),
                    (tx - math.cos(ang)*head_size + math.sin(ang)*head_size*0.5, ty - math.sin(ang)*head_size - math.cos(ang)*head_size*0.5)]
        draw.polygon(head_pts, fill=c_crimson, outline=c_steel, width=int(1.2*f))

    draw.ellipse([cx-4.5*f, cy-4.5*f, cx+4.5*f, cy+4.5*f], fill=c_gold, outline=c_crimson, width=int(1.2*f))
    draw.ellipse([cx-2*f, cy-2*f, cx+2*f, cy+2*f], fill=c_steel)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "archer_tower_piercer.png"), "archer_tower_piercer")

# =========================================================================
# 2. ARROW WALL VARIANTS
# =========================================================================

def gen_arrow_wall_arcane():
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    c_stone = (20, 22, 34, 255)
    c_stone_mid = (36, 40, 60, 255)
    c_cyan = (0, 235, 255, 255)
    c_purple = (185, 55, 255, 255)
    c_bright = (230, 250, 255, 255)

    draw.rounded_rectangle([1*s, 1*s, 15*s-1, 63*s-1], radius=2*s, fill=c_stone, outline=(12, 14, 22, 255), width=int(1.2*s))
    draw.rounded_rectangle([2*s, 2*s, 14*s-1, 62*s-1], radius=1.5*s, fill=c_stone_mid)
    draw.rectangle([1.5*s, 3*s, 4.5*s, 61*s], fill=c_stone, outline=c_cyan, width=int(0.8*s))

    for sy in [9*s, 24*s, 40*s, 56*s]:
        slit_pts = [(5.5*s, sy-3.2*s), (14.5*s, sy-1.8*s), (15*s, sy), (14.5*s, sy+1.8*s), (5.5*s, sy+3.2*s), (7*s, sy)]
        draw.polygon(slit_pts, fill=c_stone, outline=c_purple, width=int(0.8*s))
        draw.line([(6*s, sy), (13.5*s, sy)], fill=c_cyan, width=int(1.4*s))
        arrow_tip = [(10*s, sy-1.8*s), (15.2*s, sy), (10*s, sy+1.8*s), (11*s, sy)]
        draw.polygon(arrow_tip, fill=c_bright, outline=c_purple, width=int(0.6*s))

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "arrow_wall_arcane.png"), "arrow_wall_arcane")

def gen_arrow_wall_piercer():
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    c_stone = (28, 20, 20, 255)
    c_stone_mid = (48, 32, 32, 255)
    c_crimson = (245, 40, 40, 255)
    c_gold = (255, 200, 40, 255)
    c_steel = (250, 250, 255, 255)

    draw.rounded_rectangle([1*s, 1*s, 15*s-1, 63*s-1], radius=2*s, fill=c_stone, outline=(18, 10, 10, 255), width=int(1.2*s))
    draw.rounded_rectangle([2*s, 2*s, 14*s-1, 62*s-1], radius=1.5*s, fill=c_stone_mid)
    draw.rectangle([1.5*s, 3*s, 4.5*s, 61*s], fill=c_stone, outline=c_gold, width=int(0.8*s))

    for sy in [9*s, 24*s, 40*s, 56*s]:
        slit_pts = [(5.5*s, sy-3.2*s), (14.5*s, sy-1.8*s), (15*s, sy), (14.5*s, sy+1.8*s), (5.5*s, sy+3.2*s), (7*s, sy)]
        draw.polygon(slit_pts, fill=c_stone, outline=c_gold, width=int(0.8*s))
        draw.line([(6*s, sy), (13.5*s, sy)], fill=c_gold, width=int(1.4*s))
        arrow_tip = [(10*s, sy-1.8*s), (15.2*s, sy), (10*s, sy+1.8*s), (11*s, sy)]
        draw.polygon(arrow_tip, fill=c_crimson, outline=c_steel, width=int(0.6*s))

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "arrow_wall_piercer.png"), "arrow_wall_piercer")

# =========================================================================
# 3. ARTILLERY VARIANTS
# =========================================================================

def gen_artillery_thermite():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (22, 16, 14, 255)
    c_mid = (40, 28, 24, 255)
    c_magma = (255, 100, 20, 255)
    c_yellow = (255, 220, 50, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(14, 8, 6, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    
    # Swivel
    draw.ellipse([cx-19*f, cy-19*f, cx+19*f, cy+19*f], fill=c_dark, outline=c_magma, width=int(2*f))
    draw.ellipse([cx-14*f, cy-14*f, cx+14*f, cy+14*f], fill=c_mid)

    # Glowing thermite barrels
    for by in [-7*f, 7*f]:
        draw.rounded_rectangle([cx-5*f, cy+by-4*f, cx+9*f, cy+by+4*f], radius=2*f, fill=c_dark, outline=c_magma, width=int(1.5*f))
        draw.rectangle([cx+8*f, cy+by-2.8*f, cx+25*f, cy+by+2.8*f], fill=c_magma, outline=c_dark, width=int(1.2*f))
        draw.line([cx+9*f, cy+by, cx+24*f, cy+by], fill=c_yellow, width=int(1.8*f))

    # Mantlet lens
    draw.ellipse([cx+1*f, cy-4*f, cx+9*f, cy+4*f], fill=c_dark, outline=c_magma, width=int(1.2*f))
    draw.ellipse([cx+3*f, cy-2*f, cx+7*f, cy+2*f], fill=c_yellow)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "artillery_thermite.png"), "artillery_thermite")

def gen_artillery_salvo():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (16, 18, 24, 255)
    c_mid = (30, 36, 48, 255)
    c_cyan = (0, 225, 255, 255)
    c_amber = (255, 185, 30, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(10, 12, 16, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    
    draw.ellipse([cx-19*f, cy-19*f, cx+19*f, cy+19*f], fill=c_dark, outline=c_cyan, width=int(2*f))
    draw.ellipse([cx-14*f, cy-14*f, cx+14*f, cy+14*f], fill=c_mid)

    # Triple salvo barrel layout
    for by in [-9*f, 0, 9*f]:
        draw.rectangle([cx+5*f, cy+by-2.2*f, cx+26*f, cy+by+2.2*f], fill=c_mid, outline=c_dark, width=int(1.0*f))
        draw.line([cx+6*f, cy+by, cx+25*f, cy+by], fill=c_cyan, width=int(1.2*f))

    draw.ellipse([cx+1*f, cy-4*f, cx+9*f, cy+4*f], fill=c_dark, outline=c_amber, width=int(1.2*f))
    draw.ellipse([cx+3*f, cy-2*f, cx+7*f, cy+2*f], fill=c_cyan)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "artillery_salvo.png"), "artillery_salvo")

# =========================================================================
# 4. BARRICADE VARIANTS
# =========================================================================

def gen_barricade_spikes():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (22, 18, 16, 255)
    c_mid = (42, 34, 30, 255)
    c_crimson = (245, 60, 40, 255)
    c_steel = (240, 240, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(14, 10, 8, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)

    # Perimeter spikes
    for ang in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(ang)
        px = cx + math.cos(rad) * 22 * f
        py = cy + math.sin(rad) * 22 * f
        draw.regular_polygon((px, py, 4.5*f), 3, rotation=ang+90, fill=c_steel, outline=c_crimson, width=int(1.0*f))

    draw.regular_polygon((cx, cy, 14*f), 8, rotation=22.5, fill=c_dark, outline=c_crimson, width=int(2*f))
    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_crimson, outline=c_steel, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "barricade_spikes.png"), "barricade_spikes")

def gen_barricade_spectral():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (16, 20, 32, 255)
    c_mid = (28, 38, 58, 255)
    c_cyan = (0, 245, 255, 255)
    c_magenta = (235, 50, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(8, 12, 20, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)

    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx+ox, cy+oy, 5*f), 4, rotation=45, fill=c_dark, outline=c_cyan, width=int(1.5*f))

    draw.regular_polygon((cx, cy, 16*f), 8, rotation=22.5, fill=c_dark, outline=c_magenta, width=int(2*f))
    draw.polygon([(cx, cy-12*f), (cx+12*f, cy), (cx, cy+12*f), (cx-12*f, cy)], fill=(20, 35, 55, 255), outline=c_cyan, width=int(1.5*f))
    draw.polygon([(cx, cy-8*f), (cx+8*f, cy), (cx, cy+8*f), (cx-8*f, cy)], fill=c_cyan)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "barricade_spectral.png"), "barricade_spectral")

# =========================================================================
# 5. BOMB TOWER VARIANTS
# =========================================================================

def gen_bomb_incendiary():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (22, 16, 18, 255)
    c_mid = (40, 26, 28, 255)
    c_orange = (255, 120, 20, 255)
    c_crimson = (245, 40, 30, 255)
    c_yellow = (255, 230, 60, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(14, 8, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)

    draw.regular_polygon((cx, cy, 19*f), 8, rotation=22.5, fill=c_dark, outline=c_crimson, width=int(2*f))
    draw.ellipse([cx-13*f, cy-13*f, cx+13*f, cy+13*f], fill=(30, 18, 20, 255), outline=c_orange, width=int(1.5*f))
    draw.ellipse([cx-9*f, cy-9*f, cx+9*f, cy+9*f], fill=(12, 6, 8, 255), outline=c_orange, width=int(2*f))
    draw.ellipse([cx-5.5*f, cy-5.5*f, cx+5.5*f, cy+5.5*f], fill=c_orange)
    draw.ellipse([cx-2.5*f, cy-2.5*f, cx+2.5*f, cy+2.5*f], fill=c_yellow)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "bomb_tower_incendiary.png"), "bomb_tower_incendiary")

def gen_bomb_concussion():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (16, 20, 28, 255)
    c_mid = (30, 38, 52, 255)
    c_cyan = (0, 235, 255, 255)
    c_white = (240, 250, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(8, 12, 18, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)

    draw.regular_polygon((cx, cy, 19*f), 8, rotation=22.5, fill=c_dark, outline=c_cyan, width=int(2*f))
    draw.ellipse([cx-13*f, cy-13*f, cx+13*f, cy+13*f], fill=(20, 26, 36, 255), outline=c_cyan, width=int(1.5*f))
    draw.ellipse([cx-9*f, cy-9*f, cx+9*f, cy+9*f], fill=(6, 8, 14, 255), outline=c_white, width=int(2*f))
    draw.ellipse([cx-5.5*f, cy-5.5*f, cx+5.5*f, cy+5.5*f], fill=c_cyan)
    draw.ellipse([cx-2.5*f, cy-2.5*f, cx+2.5*f, cy+2.5*f], fill=c_white)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "bomb_tower_concussion.png"), "bomb_tower_concussion")

# =========================================================================
# 6. BRIMSTONE VARIANTS
# =========================================================================

def gen_brimstone_hellfire():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (22, 14, 14, 255)
    c_mid = (42, 24, 20, 255)
    c_magma = (255, 80, 20, 255)
    c_yellow = (255, 235, 80, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(14, 6, 6, 255), width=int(2*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=(16, 8, 8, 255), outline=c_magma, width=int(1.8*f))

    for vy in [-12*f, -4*f, 4*f, 12*f]:
        span = 14*f if abs(vy) < 8*f else 10*f
        draw.rounded_rectangle([cx-span, cy+vy-2*f, cx+span, cy+vy+2*f], radius=1.5*f, fill=c_magma, outline=c_yellow, width=int(1*f))
        draw.line([cx-span+2*f, cy+vy, cx+span-2*f, cy+vy], fill=(255, 255, 255, 255), width=int(1.4*f))

    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=(255, 255, 255, 255), outline=c_yellow, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "brimstone_hellfire.png"), "brimstone_hellfire")

def gen_brimstone_void():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (18, 14, 26, 255)
    c_mid = (34, 24, 48, 255)
    c_purple = (195, 45, 255, 255)
    c_cyan = (0, 235, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(10, 8, 16, 255), width=int(2*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=(12, 8, 18, 255), outline=c_purple, width=int(1.8*f))

    for vy in [-12*f, -4*f, 4*f, 12*f]:
        span = 14*f if abs(vy) < 8*f else 10*f
        draw.rounded_rectangle([cx-span, cy+vy-2*f, cx+span, cy+vy+2*f], radius=1.5*f, fill=c_purple, outline=c_cyan, width=int(1*f))
        draw.line([cx-span+2*f, cy+vy, cx+span-2*f, cy+vy], fill=(235, 210, 255, 255), width=int(1.4*f))

    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_cyan, outline=c_purple, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "brimstone_void.png"), "brimstone_void")

# =========================================================================
# 7. CORROSIVE VAPOR VARIANTS
# =========================================================================

def gen_corrosive_acid():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (16, 24, 14, 255)
    c_mid = (28, 46, 24, 255)
    c_acid = (80, 255, 40, 255)
    c_bright = (220, 255, 120, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(8, 16, 8, 255), width=int(2*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-20*f, cy-20*f, cx+20*f, cy+20*f], fill=c_dark, outline=c_acid, width=int(2*f))

    for vy in [-12*f, -6*f, 0, 6*f, 12*f]:
        span = 14*f if abs(vy) < 8*f else 10*f
        draw.rounded_rectangle([cx-span, cy+vy-1.8*f, cx+span, cy+vy+1.8*f], radius=1.5*f, fill=(0, 0, 0, 255), outline=c_acid, width=int(1.2*f))
        draw.line([cx-span+2*f, cy+vy, cx+span-2*f, cy+vy], fill=c_bright, width=int(1.5*f))

    draw.ellipse([cx-4*f, cy-4*f, cx+4*f, cy+4*f], fill=c_bright)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "corrosive_vapor_acid.png"), "corrosive_vapor_acid")

def gen_corrosive_volatile():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (14, 24, 26, 255)
    c_mid = (24, 44, 48, 255)
    c_cyan = (0, 245, 220, 255)
    c_bright = (200, 255, 245, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(6, 16, 18, 255), width=int(2*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-20*f, cy-20*f, cx+20*f, cy+20*f], fill=c_dark, outline=c_cyan, width=int(2*f))

    for vy in [-12*f, -6*f, 0, 6*f, 12*f]:
        span = 14*f if abs(vy) < 8*f else 10*f
        draw.rounded_rectangle([cx-span, cy+vy-1.8*f, cx+span, cy+vy+1.8*f], radius=1.5*f, fill=(0, 0, 0, 255), outline=c_cyan, width=int(1.2*f))
        draw.line([cx-span+2*f, cy+vy, cx+span-2*f, cy+vy], fill=c_bright, width=int(1.5*f))

    draw.ellipse([cx-4*f, cy-4*f, cx+4*f, cy+4*f], fill=c_bright)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "corrosive_vapor_volatile.png"), "corrosive_vapor_volatile")

# =========================================================================
# 8. CROSSBOW VARIANTS
# =========================================================================

def gen_crossbow_spectral():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (16, 20, 32, 255)
    c_mid = (30, 38, 58, 255)
    c_cyan = (0, 235, 255, 255)
    c_purple = (185, 55, 255, 255)

    r_base = 30*f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_dark, outline=(10, 14, 22, 255), width=int(2.5*f))
    draw.regular_polygon((cx, cy, r_base-3.5*f), 8, rotation=22.5, fill=c_mid)

    draw.ellipse([cx-18*f, cy-18*f, cx+18*f, cy+18*f], fill=c_dark, outline=c_cyan, width=int(2*f))
    
    # Chassis
    draw.polygon([(cx-18*f, cy-6*f), (cx+10*f, cy-6*f), (cx+26*f, cy-3.5*f), (cx+26*f, cy+3.5*f), (cx+10*f, cy+6*f), (cx-18*f, cy+6*f)], fill=(24, 18, 38, 255), outline=c_cyan, width=int(1.8*f))

    # Glowing spectral limbs
    draw.polygon([(cx-3*f, cy-5*f), (cx+10*f, cy-25*f), (cx+17*f, cy-25*f), (cx+7*f, cy-5*f)], fill=c_purple, outline=c_cyan, width=int(1.8*f))
    draw.polygon([(cx-3*f, cy+5*f), (cx+10*f, cy+25*f), (cx+17*f, cy+25*f), (cx+7*f, cy+5*f)], fill=c_purple, outline=c_cyan, width=int(1.8*f))

    draw.line([(cx+13.5*f, cy-24*f), (cx-6*f, cy)], fill=c_cyan, width=int(2.2*f))
    draw.line([(cx+13.5*f, cy+24*f), (cx-6*f, cy)], fill=c_cyan, width=int(2.2*f))
    
    # Ghost bolt
    draw.line([(cx-5*f, cy), (cx+22*f, cy)], fill=c_cyan, width=int(2.5*f))
    draw.polygon([(cx+29*f, cy), (cx+21*f, cy-3.5*f), (cx+23*f, cy), (cx+21*f, cy+3.5*f)], fill=(240, 255, 255, 255), outline=c_purple, width=int(1.0*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "crossbow_spectral.png"), "crossbow_spectral")

def gen_crossbow_windlass():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (26, 22, 18, 255)
    c_mid = (48, 38, 28, 255)
    c_gold = (245, 190, 40, 255)
    c_steel = (240, 245, 255, 255)

    r_base = 30*f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_dark, outline=(14, 12, 10, 255), width=int(2.5*f))
    draw.regular_polygon((cx, cy, r_base-3.5*f), 8, rotation=22.5, fill=c_mid)

    draw.ellipse([cx-18*f, cy-18*f, cx+18*f, cy+18*f], fill=c_dark, outline=c_gold, width=int(2*f))
    draw.polygon([(cx-18*f, cy-6*f), (cx+10*f, cy-6*f), (cx+26*f, cy-3.5*f), (cx+26*f, cy+3.5*f), (cx+10*f, cy+6*f), (cx-18*f, cy+6*f)], fill=(40, 30, 20, 255), outline=c_gold, width=int(1.8*f))

    # Heavy gold limbs
    draw.polygon([(cx-3*f, cy-5*f), (cx+10*f, cy-25*f), (cx+17*f, cy-25*f), (cx+7*f, cy-5*f)], fill=c_gold, outline=c_dark, width=int(1.8*f))
    draw.polygon([(cx-3*f, cy+5*f), (cx+10*f, cy+25*f), (cx+17*f, cy+25*f), (cx+7*f, cy+5*f)], fill=c_gold, outline=c_dark, width=int(1.8*f))

    draw.line([(cx+13.5*f, cy-24*f), (cx-6*f, cy)], fill=c_steel, width=int(2.2*f))
    draw.line([(cx+13.5*f, cy+24*f), (cx-6*f, cy)], fill=c_steel, width=int(2.2*f))
    
    draw.line([(cx-5*f, cy), (cx+22*f, cy)], fill=c_gold, width=int(2.5*f))
    draw.polygon([(cx+29*f, cy), (cx+21*f, cy-3.5*f), (cx+23*f, cy), (cx+21*f, cy+3.5*f)], fill=c_steel, outline=c_gold, width=int(1.0*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "crossbow_windlass.png"), "crossbow_windlass")

# =========================================================================
# 9. DISPLACER VARIANTS
# =========================================================================

def gen_displacer_warp():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (18, 12, 28, 255)
    c_mid = (34, 22, 50, 255)
    c_magenta = (245, 45, 255, 255)
    c_white = (255, 230, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(10, 6, 16, 255), width=int(2*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-24*f, cy-24*f, cx+24*f, cy+24*f], fill=c_dark, outline=c_magenta, width=int(2*f))

    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx+ox, cy+oy, 4*f), 4, rotation=45, fill=c_dark, outline=c_magenta, width=int(1.2*f))

    draw.ellipse([cx-16*f, cy-16*f, cx+16*f, cy+16*f], outline=c_white, width=int(1.8*f))
    draw.ellipse([cx-9*f, cy-9*f, cx+9*f, cy+9*f], fill=c_dark, outline=c_magenta, width=int(2*f))
    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_white, outline=c_magenta, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "displacer_warp.png"), "displacer_warp")

def gen_displacer_mass():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (14, 20, 32, 255)
    c_mid = (24, 36, 56, 255)
    c_cyan = (0, 245, 255, 255)
    c_white = (230, 255, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(8, 12, 20, 255), width=int(2*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-24*f, cy-24*f, cx+24*f, cy+24*f], fill=c_dark, outline=c_cyan, width=int(2*f))

    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx+ox, cy+oy, 4*f), 4, rotation=45, fill=c_dark, outline=c_cyan, width=int(1.2*f))

    draw.ellipse([cx-16*f, cy-16*f, cx+16*f, cy+16*f], outline=c_cyan, width=int(1.8*f))
    draw.ellipse([cx-9*f, cy-9*f, cx+9*f, cy+9*f], fill=c_dark, outline=c_white, width=int(2*f))
    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_white, outline=c_cyan, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "displacer_mass.png"), "displacer_mass")

# =========================================================================
# 10. FLAMETHROWER VARIANTS
# =========================================================================

def gen_flamethrower_napalm():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (24, 14, 16, 255)
    c_mid = (44, 26, 28, 255)
    c_crimson = (245, 35, 25, 255)
    c_gold = (255, 200, 30, 255)

    r_base = 30*f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_dark, outline=(14, 8, 10, 255), width=int(2.5*f))
    draw.regular_polygon((cx, cy, r_base-3.5*f), 8, rotation=22.5, fill=c_mid)

    draw.ellipse([cx-18*f, cy-18*f, cx+18*f, cy+18*f], fill=c_dark, outline=c_crimson, width=int(2*f))

    # Bright crimson napalm tanks
    draw.rounded_rectangle([cx-21*f, cy-21*f, cx-2*f, cy-9*f], radius=3*f, fill=c_crimson, outline=c_gold, width=int(1.8*f))
    draw.rounded_rectangle([cx-21*f, cy+9*f, cx-2*f, cy+21*f], radius=3*f, fill=c_crimson, outline=c_gold, width=int(1.8*f))

    cowl_pts = [(cx-14*f, cy-7.5*f), (cx+8*f, cy-7.5*f), (cx+22*f, cy-12*f), (cx+27*f, cy-12*f), (cx+27*f, cy+12*f), (cx+22*f, cy+12*f), (cx+8*f, cy+7.5*f), (cx-14*f, cy+7.5*f)]
    draw.polygon(cowl_pts, fill=c_dark, outline=c_crimson, width=int(2*f))
    
    draw.ellipse([cx+22*f, cy-5*f, cx+30*f, cy+5*f], fill=c_gold)
    draw.ellipse([cx+24*f, cy-2.5*f, cx+29.5*f, cy+2.5*f], fill=(255, 255, 255, 255))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "flamethrower_napalm.png"), "flamethrower_napalm")

def gen_flamethrower_turbo():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (18, 22, 28, 255)
    c_mid = (34, 44, 54, 255)
    c_orange = (255, 140, 20, 255)
    c_cyan = (0, 235, 255, 255)

    r_base = 30*f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_dark, outline=(10, 12, 16, 255), width=int(2.5*f))
    draw.regular_polygon((cx, cy, r_base-3.5*f), 8, rotation=22.5, fill=c_mid)

    draw.ellipse([cx-18*f, cy-18*f, cx+18*f, cy+18*f], fill=c_dark, outline=c_cyan, width=int(2*f))

    # Titanium compressor tanks
    draw.rounded_rectangle([cx-21*f, cy-21*f, cx-2*f, cy-9*f], radius=3*f, fill=(40, 52, 66, 255), outline=c_cyan, width=int(1.8*f))
    draw.rounded_rectangle([cx-21*f, cy+9*f, cx-2*f, cy+21*f], radius=3*f, fill=(40, 52, 66, 255), outline=c_cyan, width=int(1.8*f))

    cowl_pts = [(cx-14*f, cy-7.5*f), (cx+8*f, cy-7.5*f), (cx+22*f, cy-12*f), (cx+27*f, cy-12*f), (cx+27*f, cy+12*f), (cx+22*f, cy+12*f), (cx+8*f, cy+7.5*f), (cx-14*f, cy+7.5*f)]
    draw.polygon(cowl_pts, fill=c_mid, outline=c_orange, width=int(2*f))

    draw.ellipse([cx+22*f, cy-5*f, cx+30*f, cy+5*f], fill=c_orange)
    draw.ellipse([cx+24*f, cy-2.5*f, cx+29.5*f, cy+2.5*f], fill=(255, 255, 255, 255))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "flamethrower_turbo.png"), "flamethrower_turbo")

# =========================================================================
# 11. ICE TRAP VARIANTS
# =========================================================================

def gen_ice_permafrost():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_frame = (10, 20, 32, 255)
    c_ice = (45, 110, 145, 255)
    c_cyan = (0, 245, 245, 255)
    c_white = (240, 255, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_frame, outline=(6, 12, 20, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_ice, outline=c_cyan, width=int(1.8*f))

    # Frost needles
    for ang in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(ang)
        px = cx + math.cos(rad) * 12 * f
        py = cy + math.sin(rad) * 12 * f
        draw.line([cx, cy, px, py], fill=c_white, width=int(1.5*f))

    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_white, outline=c_cyan, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "ice_trap_permafrost.png"), "ice_trap_permafrost")

def gen_ice_glaze():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_frame = (8, 24, 30, 255)
    c_ice = (70, 160, 195, 255)
    c_cyan = (0, 255, 230, 255)
    c_white = (245, 255, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_frame, outline=(4, 14, 18, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_ice, outline=c_cyan, width=int(1.8*f))
    draw.line([11*f, 11*f, sw-11*f, 11*f], fill=c_white, width=int(2.0*f))
    draw.line([11*f, 11*f, 11*f, sh-11*f], fill=c_white, width=int(2.0*f))
    draw.line([14*f, sh-14*f, sw-14*f, 14*f], fill=c_cyan, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "ice_trap_glaze.png"), "ice_trap_glaze")

# =========================================================================
# 12. POISON TRAP VARIANTS
# =========================================================================

def gen_poison_rapid():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (16, 20, 18, 255)
    c_purple = (185, 45, 245, 255)
    c_green = (60, 245, 100, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(10, 12, 10, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=(12, 16, 14, 255), outline=c_green, width=int(1.8*f))

    for vy in [-12*f, -4*f, 4*f, 12*f]:
        span = 14*f if abs(vy) < 8*f else 10*f
        draw.rounded_rectangle([cx-span, cy+vy-2*f, cx+span, cy+vy+2*f], radius=1.5*f, fill=c_purple, outline=c_green, width=int(1*f))
        draw.line([cx-span+2*f, cy+vy, cx+span-2*f, cy+vy], fill=(220, 255, 200, 255), width=int(1.2*f))

    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_green, outline=c_purple, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "poison_trap_rapid.png"), "poison_trap_rapid")

def gen_poison_plume():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (20, 12, 28, 255)
    c_purple = (220, 45, 255, 255)
    c_bright = (250, 190, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(12, 8, 18, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=(16, 8, 24, 255), outline=c_purple, width=int(1.8*f))

    # Multi plume nodes
    for ox, oy in [(-8*f, -8*f), (8*f, -8*f), (-8*f, 8*f), (8*f, 8*f)]:
        draw.ellipse([cx+ox-5*f, cy+oy-5*f, cx+ox+5*f, cy+oy+5*f], fill=c_purple, outline=c_bright, width=int(1.2*f))

    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_bright, outline=c_purple, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "poison_trap_plume.png"), "poison_trap_plume")

# =========================================================================
# 13. SOUL LANTERN VARIANTS
# =========================================================================

def gen_soul_split():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (18, 20, 32, 255)
    c_gold = (255, 205, 50, 255)
    c_cyan = (0, 235, 255, 255)
    c_magenta = (235, 55, 255, 255)

    r_base = 30*f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_dark, outline=(12, 14, 22, 255), width=int(2.5*f))
    draw.ellipse([cx-18*f, cy-18*f, cx+18*f, cy+18*f], fill=c_dark, outline=c_gold, width=int(2*f))

    # Triple split prisms
    for ang_deg in [90, 210, 330]:
        rad = math.radians(ang_deg)
        px = cx + math.cos(rad) * 9 * f
        py = cy + math.sin(rad) * 9 * f
        draw.regular_polygon((px, py, 4*f), 3, rotation=ang_deg, fill=c_magenta, outline=c_cyan, width=int(1.2*f))

    draw.ellipse([cx-4*f, cy-4*f, cx+4*f, cy+4*f], fill=(255, 255, 255, 255))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "soul_lantern_split.png"), "soul_lantern_split")

def gen_soul_focus():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (22, 16, 36, 255)
    c_gold = (255, 215, 60, 255)
    c_cyan = (0, 245, 255, 255)

    r_base = 30*f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_dark, outline=(14, 10, 24, 255), width=int(2.5*f))
    draw.ellipse([cx-18*f, cy-18*f, cx+18*f, cy+18*f], fill=c_dark, outline=c_gold, width=int(2*f))

    # Concentric intense laser ring
    draw.ellipse([cx-12*f, cy-12*f, cx+12*f, cy+12*f], outline=c_cyan, width=int(2.0*f))
    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_cyan, outline=(255, 255, 255, 255), width=int(1.5*f))
    draw.ellipse([cx-3*f, cy-3*f, cx+3*f, cy+3*f], fill=(255, 255, 255, 255))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "soul_lantern_focus.png"), "soul_lantern_focus")

# =========================================================================
# 14. SPARKLER VARIANTS
# =========================================================================

def gen_sparkler_prismatic():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (20, 24, 36, 255)
    c_mid = (36, 44, 64, 255)
    c_cyan = (0, 245, 255, 255)
    c_magenta = (245, 50, 255, 255)
    c_gold = (255, 215, 40, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(12, 16, 24, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-16*f, cy-16*f, cx+16*f, cy+16*f], fill=c_dark, outline=c_cyan, width=int(2*f))

    # Multi-color prongs
    colors = [c_cyan, c_magenta, c_gold, (255, 255, 255, 255)]
    for i, ang_deg in enumerate([45, 135, 225, 315]):
        rad = math.radians(ang_deg)
        rx = cx + math.cos(rad) * 14 * f
        ry = cy + math.sin(rad) * 14 * f
        draw.line([cx, cy, rx, ry], fill=colors[i], width=int(2.5*f))
        draw.ellipse([rx-2.5*f, ry-2.5*f, rx+2.5*f, ry+2.5*f], fill=colors[i])

    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=(255, 255, 255, 255), outline=c_cyan, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "sparkler_prismatic.png"), "sparkler_prismatic")

def gen_sparkler_overcharge():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (24, 18, 36, 255)
    c_mid = (44, 32, 64, 255)
    c_violet = (205, 55, 255, 255)
    c_gold = (255, 215, 50, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(14, 10, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-16*f, cy-16*f, cx+16*f, cy+16*f], fill=c_dark, outline=c_violet, width=int(2*f))

    for ang_deg in [45, 135, 225, 315]:
        rad = math.radians(ang_deg)
        rx = cx + math.cos(rad) * 14 * f
        ry = cy + math.sin(rad) * 14 * f
        draw.line([cx, cy, rx, ry], fill=c_gold, width=int(3.0*f))
        draw.ellipse([rx-2.5*f, ry-2.5*f, rx+2.5*f, ry+2.5*f], fill=c_violet)

    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_gold, outline=c_violet, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "sparkler_overcharge.png"), "sparkler_overcharge")

# =========================================================================
# 15. SPIKE TRAP VARIANTS
# =========================================================================

def gen_spike_serrated():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (28, 20, 20, 255)
    c_mid = (46, 32, 32, 255)
    c_crimson = (245, 40, 40, 255)
    c_steel = (245, 250, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(16, 10, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.rounded_rectangle([9*f, 9*f, sw-9*f, sh-9*f], radius=2*f, fill=(18, 12, 12, 255), outline=c_crimson, width=int(1.5*f))

    for sx in [-13*f, -4.5*f, 4.5*f, 13*f]:
        for sy in [-13*f, -4.5*f, 4.5*f, 13*f]:
            spx, spy = cx + sx, cy + sy
            draw.polygon([(spx, spy-4*f), (spx+4*f, spy), (spx, spy+4*f), (spx-4*f, spy)], fill=c_crimson, outline=c_steel, width=int(0.8*f))
            draw.ellipse([spx-0.8*f, spy-0.8*f, spx+0.8*f, spy+0.8*f], fill=(255, 255, 255, 255))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "spike_trap_serrated.png"), "spike_trap_serrated")

def gen_spike_hydraulic():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (24, 22, 18, 255)
    c_mid = (42, 38, 30, 255)
    c_gold = (245, 190, 40, 255)
    c_steel = (240, 245, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(14, 12, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.rounded_rectangle([9*f, 9*f, sw-9*f, sh-9*f], radius=2*f, fill=(16, 14, 12, 255), outline=c_gold, width=int(1.5*f))

    for sx in [-13*f, -4.5*f, 4.5*f, 13*f]:
        for sy in [-13*f, -4.5*f, 4.5*f, 13*f]:
            spx, spy = cx + sx, cy + sy
            draw.polygon([(spx, spy-4*f), (spx+4*f, spy), (spx, spy+4*f), (spx-4*f, spy)], fill=c_steel, outline=c_gold, width=int(0.8*f))
            draw.ellipse([spx-0.8*f, spy-0.8*f, spx+0.8*f, spy+0.8*f], fill=c_gold)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "spike_trap_hydraulic.png"), "spike_trap_hydraulic")

# =========================================================================
# 16. TAR TRAP VARIANTS
# =========================================================================

def gen_tar_hex():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (18, 14, 26, 255)
    c_tar = (24, 18, 38, 255)
    c_purple = (195, 55, 255, 255)
    c_cyan = (0, 235, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(10, 8, 16, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_tar, outline=c_purple, width=int(1.8*f))
    draw.rounded_rectangle([10*f, 10*f, sw-10*f, sh-10*f], radius=1.5*f, fill=(32, 22, 50, 255))

    # Arcane occult runes
    draw.ellipse([cx-12*f, cy-12*f, cx+12*f, cy+12*f], outline=c_purple, width=int(1.5*f))
    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_purple, outline=c_cyan, width=int(1.2*f))
    draw.ellipse([cx-2.5*f, cy-2.5*f, cx+2.5*f, cy+2.5*f], fill=c_cyan)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "tar_trap_hex.png"), "tar_trap_hex")

def gen_tar_acid():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (16, 20, 14, 255)
    c_tar = (20, 32, 18, 255)
    c_acid = (80, 255, 40, 255)
    c_bright = (220, 255, 120, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(8, 14, 8, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_tar, outline=c_acid, width=int(1.8*f))
    draw.rounded_rectangle([10*f, 10*f, sw-10*f, sh-10*f], radius=1.5*f, fill=(28, 44, 24, 255))

    # Acid bubbles
    for ox, oy, r in [(-8*f, -6*f, 3*f), (7*f, -7*f, 4*f), (-6*f, 8*f, 4.5*f), (8*f, 6*f, 3.5*f), (0, 0, 5*f)]:
        draw.ellipse([cx+ox-r, cy+oy-r, cx+ox+r, cy+oy+r], fill=c_acid, outline=c_bright, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "tar_trap_acid.png"), "tar_trap_acid")

# =========================================================================
# 17. TESLA TOWER VARIANTS
# =========================================================================

def gen_tesla_superconductor():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (14, 22, 32, 255)
    c_mid = (26, 40, 60, 255)
    c_cyan = (0, 245, 255, 255)
    c_white = (240, 255, 255, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(8, 14, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-17*f, cy-17*f, cx+17*f, cy+17*f], fill=c_dark, outline=c_cyan, width=int(2*f))

    for i in range(4):
        ang = i * (math.pi / 2.0)
        px, py = cx + math.cos(ang) * 15 * f, cy + math.sin(ang) * 15 * f
        draw.line([cx, cy, px, py], fill=c_white, width=int(2.5*f))
        draw.regular_polygon((px, py, 4*f), 4, rotation=45, fill=c_white, outline=c_cyan, width=int(1.2*f))

    draw.regular_polygon((cx, cy, 8*f), 4, rotation=45, fill=c_cyan, outline=c_white, width=int(1.8*f))
    draw.ellipse([cx-2.5*f, cy-2.5*f, cx+2.5*f, cy+2.5*f], fill=(255, 255, 255, 255))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "tesla_tower_superconductor.png"), "tesla_tower_superconductor")

def gen_tesla_overcharge():
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    c_dark = (22, 14, 32, 255)
    c_mid = (40, 24, 58, 255)
    c_violet = (215, 55, 255, 255)
    c_gold = (255, 215, 50, 255)

    draw.rounded_rectangle([2*f, 2*f, sw-2*f, sh-2*f], radius=4*f, fill=c_dark, outline=(14, 8, 20, 255), width=int(2.5*f))
    draw.rounded_rectangle([5*f, 5*f, sw-5*f, sh-5*f], radius=3*f, fill=c_mid)
    draw.ellipse([cx-17*f, cy-17*f, cx+17*f, cy+17*f], fill=c_dark, outline=c_violet, width=int(2*f))

    for i in range(4):
        ang = i * (math.pi / 2.0)
        px, py = cx + math.cos(ang) * 15 * f, cy + math.sin(ang) * 15 * f
        draw.line([cx, cy, px, py], fill=c_gold, width=int(2.5*f))
        draw.regular_polygon((px, py, 4*f), 4, rotation=45, fill=c_violet, outline=c_gold, width=int(1.2*f))

    draw.regular_polygon((cx, cy, 8*f), 4, rotation=45, fill=c_violet, outline=c_gold, width=int(1.8*f))
    draw.ellipse([cx-2.5*f, cy-2.5*f, cx+2.5*f, cy+2.5*f], fill=c_gold)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "tesla_tower_overcharge.png"), "tesla_tower_overcharge")

# =========================================================================
# MAIN GENERATOR DISPATCHER
# =========================================================================

def generate_all_variants():
    os.makedirs(VARIANTS_DIR, exist_ok=True)
    gen_archer_arcane()
    gen_archer_piercer()
    gen_arrow_wall_arcane()
    gen_arrow_wall_piercer()
    gen_artillery_thermite()
    gen_artillery_salvo()
    gen_barricade_spikes()
    gen_barricade_spectral()
    gen_bomb_incendiary()
    gen_bomb_concussion()
    gen_brimstone_hellfire()
    gen_brimstone_void()
    gen_corrosive_acid()
    gen_corrosive_volatile()
    gen_crossbow_spectral()
    gen_crossbow_windlass()
    gen_displacer_warp()
    gen_displacer_mass()
    gen_flamethrower_napalm()
    gen_flamethrower_turbo()
    gen_ice_permafrost()
    gen_ice_glaze()
    gen_poison_rapid()
    gen_poison_plume()
    gen_soul_split()
    gen_soul_focus()
    gen_sparkler_prismatic()
    gen_sparkler_overcharge()
    gen_spike_serrated()
    gen_spike_hydraulic()
    gen_tar_hex()
    gen_tar_acid()
    gen_tesla_superconductor()
    gen_tesla_overcharge()
    print("Successfully generated all 34 tower specialization variants!")

if __name__ == "__main__":
    generate_all_variants()
