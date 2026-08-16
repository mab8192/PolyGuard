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
    """Full 64x64 solid fortified archer watchtower with wooden deck and arrow battlements."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "archer_tower.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    # Palette: Stonework, warm reinforced wood, bronze trim, and gold/white arrow accents
    c_stone_dark = (24, 28, 36, 255)
    c_stone_mid = (42, 50, 62, 255)
    c_stone_light = (70, 82, 100, 255)
    c_wood_dark = (95, 60, 36, 255)
    c_wood_mid = (145, 95, 55, 255)
    c_wood_light = (180, 120, 75, 255)
    c_metal_ring = (55, 62, 75, 255)
    c_gold = (245, 190, 50, 255)
    c_gold_bright = (255, 225, 120, 255)
    c_arrow_white = (240, 245, 255, 255)

    # 1. Solid fortified stone base (64x64 with 2px margin)
    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_stone_dark, outline=(14, 16, 22, 255), width=int(2.5 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_stone_mid)

    # 4 Corner Fortification Battlements (Crenellations)
    battlement_size = 6 * f
    for ox, oy in [(-20 * f, -20 * f), (20 * f, -20 * f), (-20 * f, 20 * f), (20 * f, 20 * f)]:
        draw.rectangle([cx + ox - battlement_size/2, cy + oy - battlement_size/2, cx + ox + battlement_size/2, cy + oy + battlement_size/2], fill=c_stone_light, outline=c_stone_dark, width=int(1.2 * f))

    # 2. Warm Wooden Tower Deck
    deck_margin = 11 * f
    draw.rounded_rectangle([deck_margin, deck_margin, sw - deck_margin, sh - deck_margin], radius=2 * f, fill=c_wood_mid, outline=c_wood_dark, width=int(1.5 * f))
    
    # Wooden deck planking lines
    for dy in [-10 * f, -4 * f, 2 * f, 8 * f]:
        draw.line([deck_margin + 2 * f, cy + dy, sw - deck_margin - 2 * f, cy + dy], fill=c_wood_dark, width=int(1.0 * f))

    # 3. Central Archer Turret Platform / Ring
    draw.ellipse([cx - 15 * f, cy - 15 * f, cx + 15 * f, cy + 15 * f], fill=c_stone_dark, outline=c_metal_ring, width=int(2 * f))
    draw.ellipse([cx - 11 * f, cy - 11 * f, cx + 11 * f, cy + 11 * f], fill=c_wood_dark)

    # 4. Clean 4-Way Arrow Cross / Ballista Hub
    arrow_len = 13 * f
    head_size = 4.5 * f
    for i in range(4):
        ang = i * (math.pi / 2.0)
        cos_a = math.cos(ang)
        sin_a = math.sin(ang)
        
        # Arrow shaft
        tip_x = cx + cos_a * arrow_len
        tip_y = cy + sin_a * arrow_len
        draw.line([cx, cy, tip_x, tip_y], fill=c_wood_light, width=int(2.5 * f))
        draw.line([cx, cy, tip_x, tip_y], fill=c_gold, width=int(1.2 * f))
        
        # Triangular Arrowhead
        perp_x = -sin_a * head_size * 0.7
        perp_y = cos_a * head_size * 0.7
        base_x = tip_x - cos_a * head_size
        base_y = tip_y - sin_a * head_size
        
        head_pts = [
            (tip_x, tip_y),
            (base_x + perp_x, base_y + perp_y),
            (base_x - perp_x, base_y - perp_y)
        ]
        draw.polygon(head_pts, fill=c_arrow_white, outline=c_stone_dark, width=int(1.0 * f))

    # 5. Center Pivot Cap (Golden Bullseye / Capstone)
    draw.ellipse([cx - 4.5 * f, cy - 4.5 * f, cx + 4.5 * f, cy + 4.5 * f], fill=c_gold, outline=c_stone_dark, width=int(1.2 * f))
    draw.ellipse([cx - 2 * f, cy - 2 * f, cx + 2 * f, cy + 2 * f], fill=c_gold_bright)

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
    """16x64 thin directional fortified arrow wall with wooden planks and arrow slits."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "arrow_wall.png")

    width, height = 16, 64
    scale = 8
    sw, sh = width * scale, height * scale
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = scale

    c_stone_dark = (24, 28, 36, 255)
    c_stone_mid = (42, 50, 62, 255)
    c_stone_light = (70, 82, 100, 255)
    c_wood_dark = (95, 60, 36, 255)
    c_wood_mid = (145, 95, 55, 255)
    c_wood_light = (180, 120, 75, 255)
    c_metal = (55, 62, 75, 255)
    c_gold = (245, 190, 50, 255)
    c_arrow_white = (240, 245, 255, 255)

    # 1. Outer fortified stone/metal frame
    draw.rounded_rectangle([1 * s, 1 * s, 15 * s - 1, 63 * s - 1], radius=2 * s, fill=c_stone_dark, outline=(14, 16, 22, 255), width=int(1.2 * s))
    draw.rounded_rectangle([2 * s, 2 * s, 14 * s - 1, 62 * s - 1], radius=1.5 * s, fill=c_wood_mid)

    # Wood plank grain lines
    for dy in [8 * s, 16 * s, 24 * s, 32 * s, 40 * s, 48 * s, 56 * s]:
        draw.line([2 * s, dy, 14 * s, dy], fill=c_wood_dark, width=int(0.8 * s))

    # Left reinforced stone backing spine
    draw.rectangle([1.5 * s, 3 * s, 4.5 * s, 61 * s], fill=c_stone_mid, outline=c_stone_dark, width=int(0.8 * s))

    # Iron reinforcement bands & rivets
    bracket_ys = [16 * s, 32 * s, 48 * s]
    for bky in bracket_ys:
        draw.rectangle([1.5 * s, bky - 1.5 * s, 14.5 * s, bky + 1.5 * s], fill=c_metal, outline=c_stone_dark, width=int(0.8 * s))
        draw.ellipse([3 * s, bky - 0.8 * s, 4.5 * s, bky + 0.8 * s], fill=c_gold)
        draw.ellipse([11.5 * s, bky - 0.8 * s, 13 * s, bky + 0.8 * s], fill=c_gold)

    # 4 Arrow Slits / Embrasures pointing right (+X)
    slot_centers = [9 * s, 24 * s, 40 * s, 56 * s]
    for sy in slot_centers:
        slit_pts = [
            (5.5 * s, sy - 3.2 * s),
            (14.5 * s, sy - 1.8 * s),
            (15 * s, sy),
            (14.5 * s, sy + 1.8 * s),
            (5.5 * s, sy + 3.2 * s),
            (7 * s, sy),
        ]
        draw.polygon(slit_pts, fill=c_stone_dark, outline=c_metal, width=int(0.8 * s))
        
        # Arrow shaft & broadhead tip
        draw.line([(6 * s, sy), (13.5 * s, sy)], fill=c_wood_light, width=int(1.2 * s))
        arrow_tip = [
            (10 * s, sy - 1.8 * s),
            (15.2 * s, sy),
            (10 * s, sy + 1.8 * s),
            (11 * s, sy),
        ]
        draw.polygon(arrow_tip, fill=c_arrow_white, outline=c_stone_dark, width=int(0.6 * s))
        draw.line([(6 * s, sy - 1 * s), (6 * s, sy + 1 * s)], fill=c_gold, width=int(0.8 * s))

    return save_cropped_sprite(img, (width, height), output_path, "arrow_wall")

def generate_crossbow_texture(output_path: str = None) -> str:
    """Fortified Heavy Crossbow / Ballista Turret matching the warm wood & stone archer style."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "crossbow.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (24, 28, 36, 255)
    c_stone_mid = (42, 50, 62, 255)
    c_stone_light = (70, 82, 100, 255)
    c_wood_dark = (95, 60, 36, 255)
    c_wood_mid = (145, 95, 55, 255)
    c_wood_light = (180, 120, 75, 255)
    c_metal = (55, 62, 75, 255)
    c_metal_light = (85, 96, 115, 255)
    c_gold = (245, 190, 50, 255)
    c_gold_bright = (255, 225, 120, 255)
    c_arrow_white = (240, 245, 255, 255)

    # 1. Circular/Octagonal stone foundation base (diameter 60px)
    r_base = 30 * f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_stone_dark, outline=(14, 16, 22, 255), width=int(2.5 * f))
    draw.regular_polygon((cx, cy, r_base - 3.5 * f), 8, rotation=22.5, fill=c_stone_mid)
    
    # 8 Perimeter stone battlements / iron lugs
    for i in range(8):
        ang = (i * 45 + 22.5) * math.pi / 180.0
        px = cx + math.cos(ang) * (r_base - 5 * f)
        py = cy + math.sin(ang) * (r_base - 5 * f)
        draw.regular_polygon((px, py, 2.8 * f), 4, rotation=45, fill=c_stone_light, outline=c_stone_dark, width=int(1.0 * f))

    # 2. Central Swivel Ring Platform with Wood Inlay
    draw.ellipse([cx - 18 * f, cy - 18 * f, cx + 18 * f, cy + 18 * f], fill=c_stone_dark, outline=c_metal, width=int(2 * f))
    draw.ellipse([cx - 13 * f, cy - 13 * f, cx + 13 * f, cy + 13 * f], fill=c_wood_mid, outline=c_wood_dark, width=int(1.2 * f))

    # 3. Heavy Ballista Chassis / Stock (Pointing +X)
    body_pts = [
        (cx - 18 * f, cy - 6 * f),
        (cx + 10 * f, cy - 6 * f),
        (cx + 26 * f, cy - 3.5 * f),
        (cx + 26 * f, cy + 3.5 * f),
        (cx + 10 * f, cy + 6 * f),
        (cx - 18 * f, cy + 6 * f),
    ]
    draw.polygon(body_pts, fill=c_wood_dark, outline=c_stone_dark, width=int(1.8 * f))
    draw.polygon([(cx - 17 * f, cy - 5 * f), (cx + 10 * f, cy - 5 * f), (cx + 25 * f, cy), (cx - 17 * f, cy)], fill=c_wood_light)
    draw.polygon([(cx - 17 * f, cy), (cx + 25 * f, cy), (cx + 10 * f, cy + 5 * f), (cx - 17 * f, cy + 5 * f)], fill=c_wood_mid)

    # Steel flight groove / guide rail
    draw.line([(cx - 14 * f, cy), (cx + 25 * f, cy)], fill=c_metal, width=int(2.0 * f))

    # 4. Powerful Sweeping Composite Crossbow Limbs (Curving forward from center to tips)
    limb_upper = [
        (cx - 3 * f, cy - 5 * f),
        (cx + 10 * f, cy - 25 * f),
        (cx + 17 * f, cy - 25 * f),
        (cx + 7 * f, cy - 5 * f),
    ]
    draw.polygon(limb_upper, fill=c_wood_mid, outline=c_metal, width=int(1.8 * f))
    draw.polygon([(cx + 2 * f, cy - 5 * f), (cx + 15 * f, cy - 24 * f), (cx + 11 * f, cy - 24 * f), (cx - 1 * f, cy - 5 * f)], fill=c_wood_light)

    limb_lower = [
        (cx - 3 * f, cy + 5 * f),
        (cx + 10 * f, cy + 25 * f),
        (cx + 17 * f, cy + 25 * f),
        (cx + 7 * f, cy + 5 * f),
    ]
    draw.polygon(limb_lower, fill=c_wood_dark, outline=c_metal, width=int(1.8 * f))
    draw.polygon([(cx + 2 * f, cy + 5 * f), (cx + 15 * f, cy + 24 * f), (cx + 11 * f, cy + 24 * f), (cx - 1 * f, cy + 5 * f)], fill=c_wood_mid)

    # Bronze limb tip caps / pulleys
    draw.regular_polygon((cx + 13.5 * f, cy - 25 * f, 3.2 * f), 4, rotation=45, fill=c_gold, outline=c_stone_dark, width=int(1.2 * f))
    draw.regular_polygon((cx + 13.5 * f, cy + 25 * f, 3.2 * f), 4, rotation=45, fill=c_gold, outline=c_stone_dark, width=int(1.2 * f))

    # 5. Heavy Taut Bowstring (Drawn back from limb tips to central trigger notch at x=-6)
    draw.line([(cx + 13.5 * f, cy - 24 * f), (cx - 6 * f, cy)], fill=(225, 230, 240, 255), width=int(2.2 * f))
    draw.line([(cx + 13.5 * f, cy + 24 * f), (cx - 6 * f, cy)], fill=(225, 230, 240, 255), width=int(2.2 * f))

    # 6. Primed Heavy Ballista Bolt / Quarrel in Rail
    draw.line([(cx - 5 * f, cy), (cx + 22 * f, cy)], fill=c_wood_light, width=int(2.5 * f))
    
    # Sharp broadhead arrowhead
    bolt_head = [
        (cx + 29 * f, cy),
        (cx + 21 * f, cy - 3.5 * f),
        (cx + 23 * f, cy),
        (cx + 21 * f, cy + 3.5 * f),
    ]
    draw.polygon(bolt_head, fill=c_arrow_white, outline=c_stone_dark, width=int(1.0 * f))

    # Golden fletching & trigger housing
    draw.polygon([(cx - 5 * f, cy - 2.5 * f), (cx - 1 * f, cy), (cx - 5 * f, cy + 2.5 * f)], fill=c_gold)
    draw.ellipse([cx - 10 * f, cy - 4.5 * f, cx - 1 * f, cy + 4.5 * f], fill=c_stone_dark, outline=c_gold, width=int(1.2 * f))
    draw.ellipse([cx - 7.5 * f, cy - 2.5 * f, cx - 3.5 * f, cy + 2.5 * f], fill=c_gold_bright)

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

def generate_carpet_bomb_artillery_texture(output_path: str = None) -> str:
    """Cyber Carpet Bomb Artillery turret with twin long-range heavy cannons and hazard trims (90-deg rotation)."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "carpet_bomb_artillery.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark_hull = (16, 18, 24, 255)
    c_mid_hull = (28, 36, 48, 255)
    c_metal_light = (65, 85, 110, 255)
    c_metal_highlight = (95, 120, 150, 255)
    c_neon_orange = (255, 130, 20, 255)
    c_neon_amber = (255, 185, 30, 255)
    c_neon_crimson = (235, 45, 35, 255)
    c_hazard_yellow = (255, 215, 0, 255)
    c_hazard_black = (20, 22, 28, 255)

    # 1. 64x64 Solid Base with beveled armor corners
    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_dark_hull, outline=(10, 12, 16, 255), width=int(2.5 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_mid_hull)

    # 4 Corner Fortification Anchor Lugs
    for ox, oy in [(-21 * f, -21 * f), (21 * f, -21 * f), (-21 * f, 21 * f), (21 * f, 21 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_dark_hull, outline=c_neon_orange, width=int(1.2 * f))

    # 2. Central 360-degree Heavy Swivel Ring
    draw.ellipse([cx - 19 * f, cy - 19 * f, cx + 19 * f, cy + 19 * f], fill=c_dark_hull, outline=c_neon_orange, width=int(2 * f))
    draw.ellipse([cx - 14 * f, cy - 14 * f, cx + 14 * f, cy + 14 * f], fill=c_mid_hull)

    # 3. Rear Heavy Counter-weight / Ammo Breech Housing (x=-23 to x=-4)
    draw.rounded_rectangle([cx - 23 * f, cy - 15 * f, cx - 4 * f, cy + 15 * f], radius=3 * f, fill=c_dark_hull, outline=c_neon_crimson, width=int(1.8 * f))
    draw.rounded_rectangle([cx - 21 * f, cy - 13 * f, cx - 6 * f, cy + 13 * f], radius=2 * f, fill=c_mid_hull)

    # Rear Hazard Chevrons (Yellow / Black stripes)
    for hy in [-10 * f, -5 * f, 0, 5 * f, 10 * f]:
        draw.line([cx - 20 * f, cy + hy, cx - 7 * f, cy + hy], fill=c_hazard_yellow, width=int(1.6 * f))

    # 4. Heavy Twin Artillery Barrels (Upper and Lower) pointing forward to +X (x=-4 to x=+28)
    for barrel_y in [-7 * f, 7 * f]:
        # Recoil Hydraulic Sleeve (x=-5 to x=+8)
        draw.rounded_rectangle([cx - 5 * f, cy + barrel_y - 4 * f, cx + 9 * f, cy + barrel_y + 4 * f], radius=2 * f, fill=c_metal_light, outline=c_dark_hull, width=int(1.5 * f))
        draw.line([cx - 4 * f, cy + barrel_y - 2 * f, cx + 8 * f, cy + barrel_y - 2 * f], fill=c_metal_highlight, width=int(1.2 * f))

        # Main Heavy Barrel Tube (x=+8 to x=+25)
        draw.rectangle([cx + 8 * f, cy + barrel_y - 2.8 * f, cx + 25 * f, cy + barrel_y + 2.8 * f], fill=c_mid_hull, outline=c_dark_hull, width=int(1.2 * f))
        draw.line([cx + 9 * f, cy + barrel_y, cx + 24 * f, cy + barrel_y], fill=c_neon_orange, width=int(1.2 * f))

        # Flared Muzzle Brake with Gas Vents (x=+25 to x=+29)
        muzzle_pts = [
            (cx + 25 * f, cy + barrel_y - 4.5 * f),
            (cx + 29 * f, cy + barrel_y - 3.5 * f),
            (cx + 29 * f, cy + barrel_y + 3.5 * f),
            (cx + 25 * f, cy + barrel_y + 4.5 * f),
        ]
        draw.polygon(muzzle_pts, fill=c_metal_light, outline=c_neon_orange, width=int(1.5 * f))
        draw.line([cx + 27 * f, cy + barrel_y - 4 * f, cx + 27 * f, cy + barrel_y + 4 * f], fill=c_neon_amber, width=int(1.5 * f))

    # 5. Center Breech Turret Mantlet & Targeting Optical Pod
    draw.polygon([
        (cx - 10 * f, cy - 10 * f),
        (cx + 7 * f, cy - 8 * f),
        (cx + 12 * f, cy),
        (cx + 7 * f, cy + 8 * f),
        (cx - 10 * f, cy + 10 * f),
    ], fill=c_dark_hull, outline=c_neon_orange, width=int(1.8 * f))

    # Central Glowing Targeting Lens / Sensor Eye
    draw.ellipse([cx + 1 * f, cy - 4 * f, cx + 9 * f, cy + 4 * f], fill=c_dark_hull, outline=c_neon_crimson, width=int(1.2 * f))
    draw.ellipse([cx + 3 * f, cy - 2.2 * f, cx + 7.5 * f, cy + 2.2 * f], fill=c_neon_amber)
    draw.ellipse([cx + 4.5 * f, cy - 1 * f, cx + 6.5 * f, cy + 1 * f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), output_path, "carpet_bomb_artillery")

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

def generate_spike_trap_texture(output_path: str = None) -> str:
    """Fortified ground spike trap with heavy stone/iron floor frame, floor grating, and sharp steel spikes."""
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "spike_trap.png")

    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (24, 28, 36, 255)
    c_stone_mid = (42, 50, 62, 255)
    c_grate_dark = (16, 20, 26, 255)
    c_grate_iron = (55, 65, 80, 255)
    c_steel_dark = (110, 125, 145, 255)
    c_steel_mid = (175, 195, 220, 255)
    c_steel_bright = (245, 250, 255, 255)
    c_gold = (245, 190, 50, 255)

    # 1. Fortified outer stone/iron plate base
    draw.rounded_rectangle([2 * f, 2 * f, sw - 2 * f, sh - 2 * f], radius=4 * f, fill=c_stone_dark, outline=(14, 16, 22, 255), width=int(2.5 * f))
    draw.rounded_rectangle([5 * f, 5 * f, sw - 5 * f, sh - 5 * f], radius=3 * f, fill=c_stone_mid)

    # Corner brass rivets
    for ox, oy in [(-22 * f, -22 * f), (22 * f, -22 * f), (-22 * f, 22 * f), (22 * f, 22 * f)]:
        draw.ellipse([cx + ox - 2.5 * f, cy + oy - 2.5 * f, cx + ox + 2.5 * f, cy + oy + 2.5 * f], fill=c_gold, outline=c_stone_dark, width=int(1 * f))

    # 2. Recessed floor pit & grating
    draw.rounded_rectangle([9 * f, 9 * f, sw - 9 * f, sh - 9 * f], radius=2 * f, fill=c_grate_dark, outline=c_grate_iron, width=int(1.5 * f))

    # Floor grate grid channels
    grid_coords = [-14 * f, -7 * f, 0, 7 * f, 14 * f]
    for g in grid_coords:
        draw.line([cx + g, 10 * f, cx + g, sh - 10 * f], fill=c_grate_iron, width=int(1.0 * f))
        draw.line([10 * f, cy + g, sw - 10 * f, cy + g], fill=c_grate_iron, width=int(1.0 * f))

    # 3. 4x4 Grid of Sharpened Steel Pyramidal Spikes protruding upward
    spike_offsets = [-13 * f, -4.5 * f, 4.5 * f, 13 * f]
    spike_r = 4.0 * f

    for sx in spike_offsets:
        for sy in spike_offsets:
            spx = cx + sx
            spy = cy + sy

            # Diamond spike base
            base_pts = [
                (spx, spy - spike_r),
                (spx + spike_r, spy),
                (spx, spy + spike_r),
                (spx - spike_r, spy)
            ]
            draw.polygon(base_pts, fill=c_steel_dark, outline=c_stone_dark, width=int(0.8 * f))

            # Faceted left highlight & right shadow for sharp 3D pyramid look
            left_facet = [(spx, spy - spike_r), (spx, spy), (spx - spike_r, spy)]
            top_facet = [(spx, spy - spike_r), (spx + spike_r, spy), (spx, spy)]
            bot_facet = [(spx - spike_r, spy), (spx, spy), (spx, spy + spike_r)]
            right_facet = [(spx, spy), (spx + spike_r, spy), (spx, spy + spike_r)]

            draw.polygon(left_facet, fill=c_steel_bright)
            draw.polygon(top_facet, fill=c_steel_mid)
            draw.polygon(bot_facet, fill=c_steel_mid)
            draw.polygon(right_facet, fill=c_steel_dark)

            # Center needle apex glint
            draw.ellipse([spx - 0.8 * f, spy - 0.8 * f, spx + 0.8 * f, spy + 0.8 * f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), output_path, "spike_trap")

# =========================================================================
# ALL TOWERS ENTRYPOINT
# =========================================================================

def generate_all_towers():
    generate_archer_tower_texture()
    generate_arrow_wall_texture()
    generate_crossbow_texture()
    generate_flamethrower_texture()
    generate_carpet_bomb_artillery_texture()
    generate_bomb_tower_texture()
    generate_tesla_tower_texture()
    generate_barricade_texture()
    generate_brimstone_texture()
    generate_tar_trap_texture()
    generate_poison_trap_texture()
    generate_displacer_texture()
    generate_ice_trap_texture()
    generate_corrosive_vapor_texture()
    generate_spike_trap_texture()

if __name__ == "__main__":
    generate_all_towers()
