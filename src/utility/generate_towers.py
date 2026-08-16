#!/usr/bin/env python3
"""
generate_towers.py
Generates cohesive, high-contrast cyber/neon vector textures for all Poly Guard 2D towers and traps.
All textures are supersampled with Lanczos filtering and tightly cropped using bounding-box.
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

# =========================================================================
# 1. SOLID TOWERS (FULL 64x64 FOOTPRINT)
# =========================================================================

def generate_archer_tower_texture(output_path: str = None) -> str:
    """Full 64x64 solid cyber kinetic gun turret (omnidirectional/symmetrical)."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "archer_tower.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (14, 18, 24, 255)
    c_base_mid = (26, 36, 48, 255)
    c_turret_dark = (18, 26, 36, 255)
    c_turret_light = (60, 85, 112, 255)
    c_neon_cyan = (0, 245, 212, 255)
    c_neon_bright = (190, 255, 250, 255)

    # 1. Full 64x64 solid base with 2px margin
    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_base_dark, outline=(10, 14, 20, 255), width=int(2.5 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_base_mid)

    # 4 Corner Fortification Lugs
    for ox, oy in [(-21 * f, -21 * f), (21 * f, -21 * f), (-21 * f, 21 * f), (21 * f, 21 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_base_dark, outline=c_neon_cyan, width=int(1.2 * f))

    # 2. Central 360-degree Turret Platform Ring
    draw.ellipse([cx - 18 * f, cy - 18 * f, cx + 18 * f, cy + 18 * f], fill=c_base_dark, outline=c_neon_cyan, width=int(2 * f))
    draw.ellipse([cx - 13 * f, cy - 13 * f, cx + 13 * f, cy + 13 * f], fill=c_turret_dark)

    # 3. Omnidirectional 4-Way Symmetrical Kinetic Hub
    for i in range(4):
        ang = i * (math.pi / 2.0)
        px = cx + math.cos(ang) * 12 * f
        py = cy + math.sin(ang) * 12 * f
        draw.line([cx, cy, px, py], fill=c_turret_light, width=int(3 * f))
        draw.line([cx, cy, px, py], fill=c_neon_bright, width=int(1.2 * f))

    # 4. Central Kinetic Diamond Core / Emitter
    draw.regular_polygon((cx, cy, 8 * f), 4, rotation=45, fill=c_turret_dark, outline=c_neon_cyan, width=int(1.8 * f))
    draw.regular_polygon((cx, cy, 4.5 * f), 4, rotation=45, fill=c_neon_bright, outline=c_neon_cyan, width=int(1.2 * f))

    return save_cropped_sprite(img, (64, 64), output_path, "archer_tower")

def generate_bomb_tower_texture(output_path: str = None) -> str:
    """Full 64x64 solid cyber heavy plasma mortar dome (omnidirectional/symmetrical)."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "bomb_tower.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (16, 18, 22, 255)
    c_base_mid = (32, 38, 46, 255)
    c_turret_dark = (22, 26, 32, 255)
    c_neon_orange = (255, 140, 20, 255)
    c_neon_yellow = (255, 230, 60, 255)

    # 1. Full 64x64 solid base
    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_base_dark, outline=(10, 12, 16, 255), width=int(2.5 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_base_mid)

    # 4 Corner Hazard Lugs
    for ox, oy in [(-21 * f, -21 * f), (21 * f, -21 * f), (-21 * f, 21 * f), (21 * f, 21 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_base_dark, outline=c_neon_orange, width=int(1.2 * f))

    # 2. Heavy Octagonal Mortar Breech
    draw.regular_polygon((cx, cy, 19 * f), 8, rotation=22.5, fill=c_base_dark, outline=c_neon_orange, width=int(2 * f))
    draw.ellipse([cx - 13 * f, cy - 13 * f, cx + 13 * f, cy + 13 * f], fill=c_turret_dark, outline=(12, 14, 18, 255), width=int(1.5 * f))

    # 3. Central Heavy Mortar Bore & Glowing Plasma Shell
    draw.ellipse([cx - 9 * f, cy - 9 * f, cx + 9 * f, cy + 9 * f], fill=(8, 10, 12, 255), outline=c_neon_orange, width=int(2 * f))
    draw.ellipse([cx - 5.5 * f, cy - 5.5 * f, cx + 5.5 * f, cy + 5.5 * f], fill=c_neon_orange)
    draw.ellipse([cx - 2.5 * f, cy - 2.5 * f, cx + 2.5 * f, cy + 2.5 * f], fill=c_neon_yellow)

    return save_cropped_sprite(img, (64, 64), output_path, "bomb_tower")

def generate_tesla_tower_texture(output_path: str = None) -> str:
    """Full 64x64 solid cyber Tesla arc spire (omnidirectional/symmetrical)."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "tesla_tower.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (14, 18, 26, 255)
    c_base_mid = (26, 34, 50, 255)
    c_electric_cyan = (0, 235, 255, 255)
    c_core_white = (220, 255, 255, 255)

    # 1. Full 64x64 solid base
    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_base_dark, outline=(10, 14, 20, 255), width=int(2.5 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_base_mid)

    # 4 Corner Conduit Lugs
    for ox, oy in [(-21 * f, -21 * f), (21 * f, -21 * f), (-21 * f, 21 * f), (21 * f, 21 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_base_dark, outline=c_electric_cyan, width=int(1.2 * f))
        draw.line([cx + ox, cy + oy, cx, cy], fill=c_electric_cyan, width=int(1.2 * f))

    # 2. Central Conductor Ring
    draw.ellipse([cx - 17 * f, cy - 17 * f, cx + 17 * f, cy + 17 * f], fill=c_base_dark, outline=c_electric_cyan, width=int(2 * f))

    # 4 Radial Arc Prongs
    for i in range(4):
        ang = i * (math.pi / 2.0)
        px = cx + math.cos(ang) * 15 * f
        py = cy + math.sin(ang) * 15 * f
        draw.line([cx, cy, px, py], fill=c_electric_cyan, width=int(2.2 * f))
        draw.regular_polygon((px, py, 3.5 * f), 4, rotation=45, fill=c_core_white, outline=c_electric_cyan, width=int(1.2 * f))

    # Central Spire Diamond Node
    draw.regular_polygon((cx, cy, 8 * f), 4, rotation=45, fill=c_base_dark, outline=c_electric_cyan, width=int(1.8 * f))
    draw.regular_polygon((cx, cy, 4.5 * f), 4, rotation=45, fill=c_core_white, outline=c_electric_cyan, width=int(1.2 * f))

    return save_cropped_sprite(img, (64, 64), output_path, "tesla_tower")

def generate_barricade_texture(output_path: str = None) -> str:
    """Full 64x64 solid cyber Hard-Light Barricade with armored amber shield core."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "barricade.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (14, 18, 24, 255)
    c_mid = (28, 36, 48, 255)
    c_light = (58, 75, 98, 255)
    c_neon_amber = (255, 175, 20, 255)
    c_amber_bright = (255, 235, 150, 255)

    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_dark, outline=(10, 12, 16, 255), width=int(2.5 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_mid)

    for ox, oy in [(-21 * f, -21 * f), (21 * f, -21 * f), (-21 * f, 21 * f), (21 * f, 21 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 5 * f), 4, rotation=45, fill=c_dark, outline=c_neon_amber, width=int(1.5 * f))

    draw.regular_polygon((cx, cy, 16 * f), 8, rotation=22.5, fill=c_dark, outline=c_neon_amber, width=int(2 * f))
    draw.polygon([(cx, cy - 12 * f), (cx + 12 * f, cy), (cx, cy + 12 * f), (cx - 12 * f, cy)], fill=c_light, outline=c_dark, width=int(1.2 * f))
    draw.polygon([(cx, cy - 10 * f), (cx + 10 * f, cy), (cx, cy), (cx - 10 * f, cy)], fill=c_amber_bright)
    draw.polygon([(cx, cy), (cx + 10 * f, cy), (cx, cy + 10 * f), (cx - 10 * f, cy)], fill=c_neon_amber)

    return save_cropped_sprite(img, (64, 64), output_path, "barricade")

# =========================================================================
# 2. ROTATING TURRETS (45-DEGREE ROTATION SUPPORT) & DIRECTIONAL WALLS
# =========================================================================

def generate_arrow_wall_texture(output_path: str = None) -> str:
    """16x64 thin directional cyber barricade with glowing arrow embrasures."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "arrow_wall.png")

    width, height = 16, 64
    scale = 8
    sw, sh = width * scale, height * scale
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = scale

    c_dark = (14, 18, 24, 255)
    c_mid = (26, 36, 48, 255)
    c_light = (55, 78, 102, 255)
    c_neon_cyan = (0, 245, 212, 255)
    c_neon_bright = (190, 255, 250, 255)

    draw.rounded_rectangle([1 * s, 1 * s, 15 * s - 1, 63 * s - 1], radius=2 * s, fill=c_dark, outline=(10, 14, 20, 255), width=int(1.2 * s))
    draw.rounded_rectangle([2 * s, 2 * s, 14 * s - 1, 62 * s - 1], radius=1.5 * s, fill=c_mid)

    draw.line([2 * s, 2 * s, 14 * s, 2 * s], fill=c_light, width=int(1.5 * s))
    draw.line([2 * s, 2 * s, 2 * s, 62 * s], fill=c_light, width=int(1.5 * s))

    draw.rectangle([1.5 * s, 4 * s, 4.5 * s, 60 * s], fill=c_dark, outline=c_neon_cyan, width=int(0.8 * s))

    bracket_ys = [16 * s, 32 * s, 48 * s]
    for bky in bracket_ys:
        draw.rectangle([1.5 * s, bky - 1.2 * s, 14.5 * s, bky + 1.2 * s], fill=c_dark, outline=(10, 14, 20, 255), width=int(0.6 * s))
        draw.line([2 * s, bky - 0.6 * s, 14 * s, bky - 0.6 * s], fill=c_neon_cyan, width=int(0.6 * s))

    slot_centers = [9 * s, 24 * s, 40 * s, 56 * s]
    for sy in slot_centers:
        slit_pts = [
            (6 * s, sy - 3.5 * s),
            (14.5 * s, sy - 2 * s),
            (15 * s, sy),
            (14.5 * s, sy + 2 * s),
            (6 * s, sy + 3.5 * s),
            (7.5 * s, sy),
        ]
        draw.polygon(slit_pts, fill=(10, 12, 16, 255), outline=c_neon_cyan, width=int(0.8 * s))
        arrow_tip = [
            (9 * s, sy - 1.5 * s),
            (15.2 * s, sy),
            (9 * s, sy + 1.5 * s),
            (10.5 * s, sy),
        ]
        draw.polygon(arrow_tip, fill=c_neon_bright, outline=c_neon_cyan, width=int(0.5 * s))

    return save_cropped_sprite(img, (width, height), output_path, "arrow_wall")

def generate_crossbow_texture(output_path: str = None) -> str:
    """Cyber Crossbow turret with circular/octagonal swivel base filling the full 64x64 area for 45-deg rotation."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "crossbow.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (14, 18, 24, 255)
    c_base_mid = (26, 36, 48, 255)
    c_turret_dark = (18, 26, 36, 255)
    c_turret_mid = (40, 58, 78, 255)
    c_turret_light = (70, 98, 128, 255)

    c_neon_cyan = (0, 245, 212, 255)
    c_neon_bright = (190, 255, 250, 255)

    # 1. Circular/Octagonal base extended to the border (r=30*f, diameter 60px)
    r_base = 30 * f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_base_dark, outline=(10, 14, 20, 255), width=int(2.5 * f))
    draw.regular_polygon((cx, cy, r_base - 3.5 * f), 8, rotation=22.5, fill=c_base_mid)
    
    # Outer Octagon Neon Accents
    for i in range(8):
        ang = (i * 45 + 22.5) * math.pi / 180.0
        px = cx + math.cos(ang) * (r_base - 5 * f)
        py = cy + math.sin(ang) * (r_base - 5 * f)
        draw.regular_polygon((px, py, 2.5 * f), 4, rotation=45, fill=c_base_dark, outline=c_neon_cyan, width=int(1.0 * f))

    # 2. Central 360-degree Swivel Ring Platform
    draw.ellipse([cx - 18 * f, cy - 18 * f, cx + 18 * f, cy + 18 * f], fill=c_base_dark, outline=c_neon_cyan, width=int(2 * f))
    draw.ellipse([cx - 13 * f, cy - 13 * f, cx + 13 * f, cy + 13 * f], fill=c_turret_dark)

    # 3. Heavy Crossbow Barrel / Center Rail Body (Length from x=-18 to x=+26)
    body_pts = [
        (cx - 18 * f, cy - 6 * f),
        (cx + 10 * f, cy - 6 * f),
        (cx + 26 * f, cy - 3.5 * f),
        (cx + 26 * f, cy + 3.5 * f),
        (cx + 10 * f, cy + 6 * f),
        (cx - 18 * f, cy + 6 * f),
    ]
    draw.polygon(body_pts, fill=c_turret_mid, outline=c_turret_dark, width=int(1.8 * f))
    draw.polygon([(cx - 17 * f, cy - 5 * f), (cx + 10 * f, cy - 5 * f), (cx + 25 * f, cy), (cx - 17 * f, cy)], fill=c_turret_light)
    draw.polygon([(cx - 17 * f, cy), (cx + 25 * f, cy), (cx + 10 * f, cy + 5 * f), (cx - 17 * f, cy + 5 * f)], fill=c_turret_dark)

    # 4. Wide Reinforced Kinetic Crossbow Limbs (Sweeping forward from center to edges)
    limb_upper = [
        (cx - 3 * f, cy - 5 * f),
        (cx + 10 * f, cy - 25 * f),
        (cx + 17 * f, cy - 25 * f),
        (cx + 7 * f, cy - 5 * f),
    ]
    draw.polygon(limb_upper, fill=c_turret_mid, outline=c_neon_cyan, width=int(2 * f))
    limb_lower = [
        (cx - 3 * f, cy + 5 * f),
        (cx + 10 * f, cy + 25 * f),
        (cx + 17 * f, cy + 25 * f),
        (cx + 7 * f, cy + 5 * f),
    ]
    draw.polygon(limb_lower, fill=c_turret_dark, outline=c_neon_cyan, width=int(2 * f))

    draw.regular_polygon((cx + 13.5 * f, cy - 25 * f, 3 * f), 4, rotation=45, fill=c_neon_bright, outline=c_neon_cyan, width=int(1.2 * f))
    draw.regular_polygon((cx + 13.5 * f, cy + 25 * f, 3 * f), 4, rotation=45, fill=c_neon_bright, outline=c_neon_cyan, width=int(1.2 * f))

    # 5. Neon Energy Bowstring (connecting limb tips back to central nock at x=-6)
    draw.line([(cx + 13.5 * f, cy - 24 * f), (cx - 6 * f, cy)], fill=c_neon_bright, width=int(2.5 * f))
    draw.line([(cx + 13.5 * f, cy + 24 * f), (cx - 6 * f, cy)], fill=c_neon_bright, width=int(2.5 * f))

    # 6. Primed Hyper-Kinetic Bolt in Rail
    bolt_pts = [
        (cx - 5 * f, cy - 2.5 * f),
        (cx + 21 * f, cy - 2.5 * f),
        (cx + 29 * f, cy),
        (cx + 21 * f, cy + 2.5 * f),
        (cx - 5 * f, cy + 2.5 * f),
    ]
    draw.polygon(bolt_pts, fill=c_neon_bright, outline=c_neon_cyan, width=int(1.5 * f))

    draw.ellipse([cx - 10 * f, cy - 4.5 * f, cx - 1 * f, cy + 4.5 * f], fill=c_base_dark, outline=c_neon_cyan, width=int(1.5 * f))
    draw.ellipse([cx - 8 * f, cy - 2.5 * f, cx - 3 * f, cy + 2.5 * f], fill=c_neon_bright)

    return save_cropped_sprite(img, (64, 64), output_path, "crossbow")

def generate_flamethrower_texture(output_path: str = None) -> str:
    """Cyber Flamethrower turret with circular/octagonal swivel base filling the full 64x64 area for 45-deg rotation."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "flamethrower.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark_hull = (16, 18, 24, 255)
    c_mid_hull = (28, 38, 50, 255)
    c_metal_light = (70, 90, 115, 255)
    c_neon_orange = (255, 120, 20, 255)
    c_neon_crimson = (235, 40, 30, 255)
    c_neon_yellow = (255, 230, 60, 255)

    # 1. Circular/Octagonal base extended to the border (r=30*f, diameter 60px)
    r_base = 30 * f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_dark_hull, outline=(10, 12, 16, 255), width=int(2.5 * f))
    draw.regular_polygon((cx, cy, r_base - 3.5 * f), 8, rotation=22.5, fill=c_mid_hull)

    # Outer Octagon Hazard Trims
    for i in range(8):
        ang = (i * 45 + 22.5) * math.pi / 180.0
        px = cx + math.cos(ang) * (r_base - 5 * f)
        py = cy + math.sin(ang) * (r_base - 5 * f)
        draw.regular_polygon((px, py, 2.5 * f), 4, rotation=45, fill=c_dark_hull, outline=c_neon_orange, width=int(1.0 * f))

    # 2. Central 360-degree Swivel Turret Ring
    draw.ellipse([cx - 18 * f, cy - 18 * f, cx + 18 * f, cy + 18 * f], fill=c_dark_hull, outline=c_neon_orange, width=int(2 * f))
    draw.ellipse([cx - 13 * f, cy - 13 * f, cx + 13 * f, cy + 13 * f], fill=c_mid_hull)

    # 3. Dual High-Pressure Fuel/Plasma Tanks (Upper and Lower flanks)
    draw.rounded_rectangle([cx - 21 * f, cy - 21 * f, cx - 2 * f, cy - 9 * f], radius=3 * f, fill=c_neon_crimson, outline=c_dark_hull, width=int(1.8 * f))
    draw.line([cx - 19 * f, cy - 15 * f, cx - 4 * f, cy - 15 * f], fill=c_neon_yellow, width=int(1.8 * f))
    draw.regular_polygon((cx - 21 * f, cy - 15 * f, 2.5 * f), 4, rotation=45, fill=c_metal_light)

    draw.rounded_rectangle([cx - 21 * f, cy + 9 * f, cx - 2 * f, cy + 21 * f], radius=3 * f, fill=c_neon_crimson, outline=c_dark_hull, width=int(1.8 * f))
    draw.line([cx - 19 * f, cy + 15 * f, cx - 4 * f, cy + 15 * f], fill=c_neon_yellow, width=int(1.8 * f))
    draw.regular_polygon((cx - 21 * f, cy + 15 * f, 2.5 * f), 4, rotation=45, fill=c_metal_light)

    # 4. Central Heavy Flame Projector Cannon & Heat Cowl (x=-14 to x=+27)
    cowl_pts = [
        (cx - 14 * f, cy - 7.5 * f),
        (cx + 8 * f, cy - 7.5 * f),
        (cx + 22 * f, cy - 12 * f),
        (cx + 27 * f, cy - 12 * f),
        (cx + 27 * f, cy + 12 * f),
        (cx + 22 * f, cy + 12 * f),
        (cx + 8 * f, cy + 7.5 * f),
        (cx - 14 * f, cy + 7.5 * f),
    ]
    draw.polygon(cowl_pts, fill=c_mid_hull, outline=c_dark_hull, width=int(2 * f))
    draw.polygon([(cx - 13 * f, cy - 6.5 * f), (cx + 8 * f, cy - 6.5 * f), (cx + 22 * f, cy - 10.5 * f), (cx + 26 * f, cy), (cx - 13 * f, cy)], fill=c_metal_light)
    draw.polygon([(cx - 13 * f, cy), (cx + 26 * f, cy), (cx + 22 * f, cy + 10.5 * f), (cx + 8 * f, cy + 6.5 * f), (cx - 13 * f, cy + 6.5 * f)], fill=c_dark_hull)

    for vx in [cx - 6 * f, cx, cx + 6 * f]:
        draw.line([vx, cy - 5 * f, vx, cy + 5 * f], fill=c_neon_orange, width=int(1.5 * f))

    # 5. Flared Plasma Projector Nozzle Core & Pilot Ignition Flame
    draw.polygon([(cx + 22 * f, cy - 10 * f), (cx + 29 * f, cy - 8 * f), (cx + 29 * f, cy + 8 * f), (cx + 22 * f, cy + 10 * f)], fill=c_neon_orange, outline=c_neon_crimson, width=int(1.5 * f))
    draw.ellipse([cx + 22 * f, cy - 5 * f, cx + 30 * f, cy + 5 * f], fill=c_neon_yellow)
    draw.ellipse([cx + 24 * f, cy - 2.5 * f, cx + 29.5 * f, cy + 2.5 * f], fill=(255, 255, 255, 255))

    draw.ellipse([cx - 5 * f, cy - 4 * f, cx + 3 * f, cy + 4 * f], fill=c_dark_hull, outline=c_neon_orange, width=int(1.5 * f))
    draw.ellipse([cx - 3 * f, cy - 2 * f, cx + 1 * f, cy + 2 * f], fill=c_neon_yellow)

    return save_cropped_sprite(img, (64, 64), output_path, "flamethrower")

# =========================================================================
# 3. FLOOR TRAPS (NON-SOLID, FULL 64x64 FOOTPRINT)
# =========================================================================

def generate_brimstone_texture(output_path: str = None) -> str:
    """Cyber Magma / Thermal Plate with glowing heat slits and center core."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "brimstone.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (16, 18, 22, 255)
    c_plate_mid = (30, 32, 40, 255)
    c_neon_crimson = (255, 60, 20, 255)
    c_magma_orange = (255, 140, 20, 255)
    c_magma_yellow = (255, 230, 80, 255)

    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_plate_dark, outline=(10, 12, 14, 255), width=int(2 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_plate_mid)
    draw.rounded_rectangle([8 * f, 8 * f, sw - 8 * f, sh - 8 * f], radius=2.5 * f, fill=(12, 14, 16, 255), outline=c_neon_crimson, width=int(1.8 * f))

    for vy in [-12 * f, -4 * f, 4 * f, 12 * f]:
        span = 14 * f if abs(vy) < 8 * f else 10 * f
        draw.rounded_rectangle([cx - span, cy + vy - 2 * f, cx + span, cy + vy + 2 * f], radius=1.5 * f, fill=c_neon_crimson, outline=c_magma_orange, width=int(1 * f))
        draw.line([cx - span + 2 * f, cy + vy, cx + span - 2 * f, cy + vy], fill=c_magma_yellow, width=int(1.2 * f))

    draw.regular_polygon((cx, cy, 6 * f), 4, rotation=45, fill=c_magma_yellow, outline=c_neon_crimson, width=int(1.2 * f))

    return save_cropped_sprite(img, (64, 64), output_path, "brimstone")

def generate_tar_trap_texture(output_path: str = None) -> str:
    """Cyber Stasis / Tar Pad with neon gold border and smooth dark polymer surface."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "tar_trap.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0
    f = factor = 4

    c_plate_dark = (14, 16, 20, 255)
    c_plate_mid = (24, 28, 34, 255)
    c_neon_gold = (235, 175, 25, 255)
    c_tar_base = (16, 20, 26, 255)
    c_tar_surface = (28, 34, 42, 255)
    c_gold_sheen = (255, 220, 100, 255)

    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_plate_dark, outline=(8, 10, 12, 255), width=int(2 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_plate_mid)
    draw.rounded_rectangle([8 * f, 8 * f, sw - 8 * f, sh - 8 * f], radius=2.5 * f, fill=c_tar_base, outline=c_neon_gold, width=int(1.8 * f))
    draw.rounded_rectangle([10 * f, 10 * f, sw - 10 * f, sh - 10 * f], radius=1.5 * f, fill=c_tar_surface)

    draw.line([11 * f, 11 * f, sw - 11 * f, 11 * f], fill=c_gold_sheen, width=int(1.5 * f))
    draw.line([11 * f, 11 * f, 11 * f, sh - 11 * f], fill=c_gold_sheen, width=int(1.5 * f))
    draw.line([sw - 11 * f, 11 * f, sw - 11 * f, sh - 11 * f], fill=c_tar_base, width=int(1.2 * f))
    draw.line([11 * f, sh - 11 * f, sw - 11 * f, sh - 11 * f], fill=c_tar_base, width=int(1.2 * f))

    return save_cropped_sprite(img, (64, 64), output_path, "tar_trap")

def generate_poison_trap_texture(output_path: str = None) -> str:
    """Cyber Caustic / Bio-Toxic Trap Plate with glowing purple fume slits and center core."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "poison_trap.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (16, 14, 22, 255)
    c_plate_mid = (30, 24, 40, 255)
    c_neon_purple = (195, 45, 245, 255)
    c_toxic_purple = (150, 25, 200, 255)
    c_toxic_bright = (245, 170, 255, 255)

    # 1. Dark outer border plate
    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_plate_dark, outline=(10, 8, 14, 255), width=int(2 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_plate_mid)

    # 2. Toxic Vent Chamber
    draw.rounded_rectangle([8 * f, 8 * f, sw - 8 * f, sh - 8 * f], radius=2.5 * f, fill=(12, 10, 16, 255), outline=c_neon_purple, width=int(1.8 * f))

    # 3. Horizontal Toxic Fume Slits
    for vy in [-12 * f, -4 * f, 4 * f, 12 * f]:
        span = 14 * f if abs(vy) < 8 * f else 10 * f
        draw.rounded_rectangle([cx - span, cy + vy - 2 * f, cx + span, cy + vy + 2 * f], radius=1.5 * f, fill=c_toxic_purple, outline=c_neon_purple, width=int(1 * f))
        draw.line([cx - span + 2 * f, cy + vy, cx + span - 2 * f, cy + vy], fill=c_toxic_bright, width=int(1.2 * f))

    # 4. Central Toxic Diamond Node
    draw.regular_polygon((cx, cy, 6 * f), 4, rotation=45, fill=c_toxic_bright, outline=c_neon_purple, width=int(1.2 * f))

    return save_cropped_sprite(img, (64, 64), output_path, "poison_trap")

def generate_displacer_texture(output_path: str = None) -> str:
    """Cyber Displacer floor trap texture with neon purple/cyan warp vortex conduits."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "displacer.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (14, 16, 26, 255)
    c_plate_mid = (26, 28, 48, 255)
    c_warp_purple = (185, 45, 255, 255)
    c_warp_cyan = (0, 240, 255, 255)
    c_core_white = (245, 220, 255, 255)

    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_plate_dark, outline=(10, 12, 20, 255), width=int(2 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_plate_mid)
    draw.ellipse([cx - 24 * f, cy - 24 * f, cx + 24 * f, cy + 24 * f], fill=c_plate_dark, outline=c_warp_purple, width=int(2 * f))

    for ox, oy in [(-20 * f, -20 * f), (20 * f, -20 * f), (-20 * f, 20 * f), (20 * f, 20 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4 * f), 4, rotation=45, fill=c_plate_dark, outline=c_warp_cyan, width=int(1.2 * f))
        draw.line([cx + ox, cy + oy, cx, cy], fill=c_warp_purple, width=int(1.2 * f))

    draw.ellipse([cx - 16 * f, cy - 16 * f, cx + 16 * f, cy + 16 * f], outline=c_warp_cyan, width=int(1.8 * f))
    draw.ellipse([cx - 9 * f, cy - 9 * f, cx + 9 * f, cy + 9 * f], fill=c_plate_dark, outline=c_warp_purple, width=int(2 * f))
    draw.regular_polygon((cx, cy, 6 * f), 4, rotation=45, fill=c_core_white, outline=c_warp_purple, width=int(1.5 * f))

    return save_cropped_sprite(img, (64, 64), output_path, "displacer")

def generate_ice_trap_texture(output_path: str = None) -> str:
    """Clean flat cyber Ice Trap floor texture with an icy blue sheet and neon cyan border."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "ice_trap.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_frame_dark = (10, 18, 26, 255)
    c_frame_mid = (20, 36, 50, 255)
    c_neon_cyan = (0, 245, 230, 255)
    c_ice_base = (38, 92, 118, 255)
    c_ice_surface = (68, 142, 172, 255)
    c_ice_light = (130, 215, 240, 255)

    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_frame_dark, outline=(6, 12, 18, 255), width=int(2 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_frame_mid)
    draw.rounded_rectangle([8 * f, 8 * f, sw - 8 * f, sh - 8 * f], radius=2.5 * f, fill=c_ice_base, outline=c_neon_cyan, width=int(1.8 * f))
    draw.rounded_rectangle([10 * f, 10 * f, sw - 10 * f, sh - 10 * f], radius=1.5 * f, fill=c_ice_surface)

    draw.line([11 * f, 11 * f, sw - 11 * f, 11 * f], fill=c_ice_light, width=int(1.5 * f))
    draw.line([11 * f, 11 * f, 11 * f, sh - 11 * f], fill=c_ice_light, width=int(1.5 * f))
    draw.line([sw - 11 * f, 11 * f, sw - 11 * f, sh - 11 * f], fill=c_ice_base, width=int(1.2 * f))
    draw.line([11 * f, sh - 11 * f, sw - 11 * f, sh - 11 * f], fill=c_ice_base, width=int(1.2 * f))

    return save_cropped_sprite(img, (64, 64), output_path, "ice_trap")

def generate_corrosive_vapor_texture(output_path: str = None) -> str:
    """Cyber Corrosive Vapor floor trap texture with hazard borders and glowing acid green vents."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "corrosive_vapor.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (16, 22, 16, 255)
    c_plate_mid = (30, 42, 28, 255)
    c_hazard_yellow = (210, 200, 20, 255)
    c_acid_green = (50, 245, 60, 255)
    c_acid_bright = (190, 255, 140, 255)

    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_plate_dark, outline=(10, 15, 10, 255), width=int(2 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_plate_mid)
    draw.line([6 * f, 8 * f, 6 * f, sh - 8 * f], fill=c_hazard_yellow, width=int(2 * f))
    draw.line([sw - 6 * f, 8 * f, sw - 6 * f, sh - 8 * f], fill=c_hazard_yellow, width=int(2 * f))

    draw.ellipse([cx - 20 * f, cy - 20 * f, cx + 20 * f, cy + 20 * f], fill=c_plate_dark, outline=c_acid_green, width=int(2 * f))

    vent_ys = [-12 * f, -6 * f, 0, 6 * f, 12 * f]
    for vy in vent_ys:
        span = 14 * f if abs(vy) < 8 * f else 10 * f
        draw.rounded_rectangle([cx - span, cy + vy - 1.8 * f, cx + span, cy + vy + 1.8 * f], radius=1.5 * f, fill=(0, 0, 0, 255), outline=c_acid_green, width=int(1.2 * f))
        draw.line([cx - span + 2 * f, cy + vy, cx + span - 2 * f, cy + vy], fill=c_acid_bright, width=int(1.2 * f))

    draw.ellipse([cx - 3.5 * f, cy - 3.5 * f, cx + 3.5 * f, cy + 3.5 * f], fill=c_acid_bright)

    return save_cropped_sprite(img, (64, 64), output_path, "corrosive_vapor")

# =========================================================================
# ALL TOWERS ENTRYPOINT
# =========================================================================

def generate_all_towers():
    generate_archer_tower_texture()
    generate_arrow_wall_texture()
    generate_crossbow_texture()
    generate_flamethrower_texture()
    generate_bomb_tower_texture()
    generate_tesla_tower_texture()
    generate_barricade_texture()
    generate_brimstone_texture()
    generate_tar_trap_texture()
    generate_poison_trap_texture()
    generate_displacer_texture()
    generate_ice_trap_texture()
    generate_corrosive_vapor_texture()

if __name__ == "__main__":
    generate_all_towers()
