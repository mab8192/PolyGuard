#!/usr/bin/env python3
"""
generate_tower_variants.py
Generates cohesive, high-contrast cyber/neon vector textures for all 34 Poly Guard 2D tower specializations.
All textures are supersampled with Lanczos filtering and tightly cropped.
Maintains visual fidelity, structural elements, and details from the base towers while incorporating specialization themes.
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
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    final_img.save(output_path, "PNG")
    print(f"Generated {label}: {output_path} (size: {final_img.size})")
    return output_path

VARIANTS_DIR = os.path.join(get_project_root(), "src", "textures", "towers", "variants")

# =========================================================================
# 1. ARCHER TOWER VARIANTS
# =========================================================================

def gen_archer_arcane():
    """Arcane Watchtower: runic stone battlements, violet wooden deck, arcane cyan/purple 4-way ballista arrows."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (20, 22, 34, 255)
    c_stone_mid = (36, 40, 60, 255)
    c_stone_light = (65, 75, 105, 255)
    c_wood_dark = (40, 22, 60, 255)
    c_wood_mid = (75, 40, 105, 255)
    c_arcane_cyan = (0, 235, 255, 255)
    c_arcane_purple = (185, 55, 255, 255)
    c_bright = (230, 250, 255, 255)

    # 1. Solid stone base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(12, 14, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    # 4 Corner Fortification Battlements
    battlement_size = 6 * f
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.rectangle([cx + ox - battlement_size/2, cy + oy - battlement_size/2, cx + ox + battlement_size/2, cy + oy + battlement_size/2], fill=c_stone_light, outline=c_stone_dark, width=int(1.2*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_arcane_purple)

    # 2. Violet Deck with plank lines
    deck_m = 11 * f
    draw.rounded_rectangle([deck_m, deck_m, sw-deck_m, sh-deck_m], radius=2*f, fill=c_wood_mid, outline=c_wood_dark, width=int(1.5*f))
    for dy in [-10*f, -4*f, 2*f, 8*f]:
        draw.line([deck_m + 2*f, cy + dy, sw - deck_m - 2*f, cy + dy], fill=c_wood_dark, width=int(1.0*f))

    # 3. Turret Ring
    draw.ellipse([cx-15*f, cy-15*f, cx+15*f, cy+15*f], fill=c_stone_dark, outline=c_arcane_cyan, width=int(2*f))
    draw.ellipse([cx-11*f, cy-11*f, cx+11*f, cy+11*f], fill=(25, 15, 40, 255))

    # 4. Arcane 4-Way Arrow Cross
    arrow_len = 13 * f
    head_size = 5.0 * f
    for i in range(4):
        ang = i * (math.pi / 2.0)
        cos_a, sin_a = math.cos(ang), math.sin(ang)
        tx, ty = cx + cos_a * arrow_len, cy + sin_a * arrow_len
        draw.line([cx, cy, tx, ty], fill=c_arcane_cyan, width=int(2.5*f))
        head_pts = [
            (tx, ty),
            (tx - cos_a * head_size - sin_a * head_size * 0.7, ty - sin_a * head_size + cos_a * head_size * 0.7),
            (tx - cos_a * head_size + sin_a * head_size * 0.7, ty - sin_a * head_size - cos_a * head_size * 0.7)
        ]
        draw.polygon(head_pts, fill=c_bright, outline=c_arcane_purple, width=int(1.2*f))

    # 5. Central Runic Capstone
    draw.ellipse([cx-4.5*f, cy-4.5*f, cx+4.5*f, cy+4.5*f], fill=c_arcane_purple, outline=c_arcane_cyan, width=int(1.2*f))
    draw.ellipse([cx-2*f, cy-2*f, cx+2*f, cy+2*f], fill=c_bright)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "archer_tower_arcane.png"), "archer_tower_arcane")

def gen_archer_piercer():
    """Piercer Archer Tower: reinforced red stone, dark crimson wood deck, gold trim, heavy steel-tipped armor-piercing arrows."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (28, 20, 20, 255)
    c_stone_mid = (50, 36, 36, 255)
    c_stone_light = (85, 60, 60, 255)
    c_wood_dark = (40, 22, 22, 255)
    c_wood_mid = (75, 38, 38, 255)
    c_crimson = (245, 40, 40, 255)
    c_gold = (255, 200, 40, 255)
    c_steel = (250, 250, 255, 255)

    # 1. Solid stone base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(18, 12, 12, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    # 4 Corner Fortification Battlements
    battlement_size = 6 * f
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.rectangle([cx + ox - battlement_size/2, cy + oy - battlement_size/2, cx + ox + battlement_size/2, cy + oy + battlement_size/2], fill=c_stone_light, outline=c_stone_dark, width=int(1.2*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_crimson)

    # 2. Crimson Wood Deck with plank lines
    deck_m = 11 * f
    draw.rounded_rectangle([deck_m, deck_m, sw-deck_m, sh-deck_m], radius=2*f, fill=c_wood_mid, outline=c_wood_dark, width=int(1.5*f))
    for dy in [-10*f, -4*f, 2*f, 8*f]:
        draw.line([deck_m + 2*f, cy + dy, sw - deck_m - 2*f, cy + dy], fill=c_wood_dark, width=int(1.0*f))

    # 3. Turret Ring
    draw.ellipse([cx-15*f, cy-15*f, cx+15*f, cy+15*f], fill=c_stone_dark, outline=c_gold, width=int(2*f))
    draw.ellipse([cx-11*f, cy-11*f, cx+11*f, cy+11*f], fill=(24, 15, 15, 255))

    # 4. 4-Way Piercing Arrow Cross
    arrow_len = 14 * f
    head_size = 5.5 * f
    for i in range(4):
        ang = i * (math.pi / 2.0)
        cos_a, sin_a = math.cos(ang), math.sin(ang)
        tx, ty = cx + cos_a * arrow_len, cy + sin_a * arrow_len
        draw.line([cx, cy, tx, ty], fill=c_gold, width=int(2.5*f))
        head_pts = [
            (tx, ty),
            (tx - cos_a * head_size - sin_a * head_size * 0.55, ty - sin_a * head_size + cos_a * head_size * 0.55),
            (tx - cos_a * head_size + sin_a * head_size * 0.55, ty - sin_a * head_size - cos_a * head_size * 0.55)
        ]
        draw.polygon(head_pts, fill=c_crimson, outline=c_steel, width=int(1.2*f))

    # 5. Central Capstone
    draw.ellipse([cx-4.5*f, cy-4.5*f, cx+4.5*f, cy+4.5*f], fill=c_gold, outline=c_crimson, width=int(1.2*f))
    draw.ellipse([cx-2*f, cy-2*f, cx+2*f, cy+2*f], fill=c_steel)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "archer_tower_piercer.png"), "archer_tower_piercer")

# =========================================================================
# 2. ARROW WALL VARIANTS
# =========================================================================

def gen_arrow_wall_arcane():
    """16x64 Arcane Arrow Wall: violet wood planks, brackets with purple gems, glowing arcane arrow slits."""
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_stone_dark = (20, 22, 34, 255)
    c_stone_mid = (36, 40, 60, 255)
    c_wood_dark = (40, 22, 60, 255)
    c_wood_mid = (75, 40, 105, 255)
    c_metal = (50, 55, 80, 255)
    c_cyan = (0, 235, 255, 255)
    c_purple = (185, 55, 255, 255)
    c_bright = (230, 250, 255, 255)

    # 1. Outer stone frame
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=2 * s, fill=c_stone_dark, outline=(12, 14, 22, 255), width=int(1.2*s))
    draw.rounded_rectangle([1.5 * s, 1.5 * s, sw - 1 - 1.5 * s, sh - 1 - 1.5 * s], radius=1.5 * s, fill=c_wood_mid)

    # Wood plank grain lines
    for dy in [8*s, 16*s, 24*s, 32*s, 40*s, 48*s, 56*s]:
        draw.line([2*s, dy, 14*s, dy], fill=c_wood_dark, width=int(0.8*s))

    # Left reinforced stone spine
    draw.rectangle([1.5*s, 3*s, 4.5*s, 61*s], fill=c_stone_mid, outline=c_stone_dark, width=int(0.8*s))

    # Metal brackets with arcane gems
    for bky in [16*s, 32*s, 48*s]:
        draw.rectangle([1.5*s, bky - 1.5*s, 14.5*s, bky + 1.5*s], fill=c_metal, outline=c_stone_dark, width=int(0.8*s))
        draw.ellipse([3*s, bky - 0.8*s, 4.5*s, bky + 0.8*s], fill=c_cyan)
        draw.ellipse([11.5*s, bky - 0.8*s, 13*s, bky + 0.8*s], fill=c_purple)

    # 4 Arrow Slits
    for sy in [9*s, 24*s, 40*s, 56*s]:
        slit_pts = [
            (5.5*s, sy - 3.2*s),
            (14.5*s, sy - 1.8*s),
            (15*s, sy),
            (14.5*s, sy + 1.8*s),
            (5.5*s, sy + 3.2*s),
            (7*s, sy)
        ]
        draw.polygon(slit_pts, fill=c_stone_dark, outline=c_purple, width=int(0.8*s))
        draw.line([(6*s, sy), (13.5*s, sy)], fill=c_cyan, width=int(1.4*s))
        arrow_tip = [
            (10*s, sy - 1.8*s),
            (15.2*s, sy),
            (10*s, sy + 1.8*s),
            (11*s, sy)
        ]
        draw.polygon(arrow_tip, fill=c_bright, outline=c_purple, width=int(0.6*s))

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "arrow_wall_arcane.png"), "arrow_wall_arcane")

def gen_arrow_wall_piercer():
    """16x64 Piercer Arrow Wall: colors match Archer Tower Piercer with dark red stone, crimson wood deck, gold rivets, and steel/crimson broadheads."""
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_stone_dark = (28, 20, 20, 255)
    c_stone_mid = (50, 36, 36, 255)
    c_wood_dark = (40, 22, 22, 255)
    c_wood_mid = (75, 38, 38, 255)
    c_metal = (60, 48, 48, 255)
    c_crimson = (245, 40, 40, 255)
    c_gold = (255, 200, 40, 255)
    c_steel = (250, 250, 255, 255)

    # 1. Outer red-stone frame
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=2 * s, fill=c_stone_dark, outline=(18, 12, 12, 255), width=int(1.2*s))
    draw.rounded_rectangle([1.5 * s, 1.5 * s, sw - 1 - 1.5 * s, sh - 1 - 1.5 * s], radius=1.5 * s, fill=c_wood_mid)

    # Wood plank grain lines
    for dy in [8*s, 16*s, 24*s, 32*s, 40*s, 48*s, 56*s]:
        draw.line([2*s, dy, 14*s, dy], fill=c_wood_dark, width=int(0.8*s))

    # Left reinforced spine
    draw.rectangle([1.5*s, 3*s, 4.5*s, 61*s], fill=c_stone_mid, outline=c_stone_dark, width=int(0.8*s))

    # Metal reinforcement brackets with gold rivets
    for bky in [16*s, 32*s, 48*s]:
        draw.rectangle([1.5*s, bky - 1.5*s, 14.5*s, bky + 1.5*s], fill=c_metal, outline=c_stone_dark, width=int(0.8*s))
        draw.ellipse([3*s, bky - 0.8*s, 4.5*s, bky + 0.8*s], fill=c_gold)
        draw.ellipse([11.5*s, bky - 0.8*s, 13*s, bky + 0.8*s], fill=c_gold)

    # 4 Piercer Arrow Slits
    for sy in [9*s, 24*s, 40*s, 56*s]:
        slit_pts = [
            (5.5*s, sy - 3.2*s),
            (14.5*s, sy - 1.8*s),
            (15*s, sy),
            (14.5*s, sy + 1.8*s),
            (5.5*s, sy + 3.2*s),
            (7*s, sy)
        ]
        draw.polygon(slit_pts, fill=c_stone_dark, outline=c_gold, width=int(0.8*s))
        draw.line([(6*s, sy), (13.5*s, sy)], fill=c_gold, width=int(1.4*s))
        arrow_tip = [
            (10*s, sy - 1.8*s),
            (15.2*s, sy),
            (10*s, sy + 1.8*s),
            (11*s, sy)
        ]
        draw.polygon(arrow_tip, fill=c_crimson, outline=c_steel, width=int(0.7*s))
        draw.line([(6*s, sy - 1*s), (6*s, sy + 1*s)], fill=c_gold, width=int(0.8*s))

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "arrow_wall_piercer.png"), "arrow_wall_piercer")

# =========================================================================
# WIND WALL VARIANTS
# =========================================================================

def gen_wind_wall_tempest():
    """16x64 Hurricane Force Wind Wall: reinforced gold/bronze housing, electric blue glow, oversized hurricane thrusters."""
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_frame_dark = (26, 22, 14, 255)
    c_frame_mid = (54, 44, 24, 255)
    c_frame_light = (85, 70, 36, 255)
    c_gold = (255, 200, 40, 255)
    c_electric_blue = (0, 225, 255, 255)
    c_lightning_bright = (220, 250, 255, 255)
    c_copper = (210, 120, 45, 255)

    # 1. Fortified gold-trimmed frame
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=2 * s, fill=c_frame_dark, outline=(18, 14, 8, 255), width=int(1.2*s))
    draw.rounded_rectangle([1.5 * s, 1.5 * s, sw - 1 - 1.5 * s, sh - 1 - 1.5 * s], radius=1.5 * s, fill=c_frame_mid)

    # Power conduits
    draw.line([(3.5*s, 4*s), (3.5*s, 60*s)], fill=c_electric_blue, width=int(2.0*s))
    draw.line([(3.5*s, 4*s), (3.5*s, 60*s)], fill=c_lightning_bright, width=int(0.8*s))

    # Heavy gold brackets
    for bky in [4*s, 32*s, 60*s]:
        draw.rectangle([1.5*s, bky - 1.8*s, 14.5*s, bky + 1.8*s], fill=c_gold, outline=c_frame_dark, width=int(0.8*s))
        draw.ellipse([2.5*s, bky - 0.8*s, 4.5*s, bky + 0.8*s], fill=c_lightning_bright)
        draw.ellipse([12*s, bky - 0.8*s, 13.5*s, bky + 0.8*s], fill=c_copper)

    # 2 Oversized Hurricane Thrusters pointing right (+X)
    for ty in [19*s, 45*s]:
        draw.ellipse([3.5*s, ty - 8.5*s, 14.5*s, ty + 8.5*s], fill=c_frame_dark, outline=c_gold, width=int(1.4*s))
        draw.ellipse([5.5*s, ty - 6.5*s, 12.5*s, ty + 6.5*s], fill=c_frame_mid, outline=c_electric_blue, width=int(1.0*s))
        
        # Heavy turbine blades
        for ang in [-45, 0, 45, 90]:
            rad = math.radians(ang)
            dx = math.cos(rad) * 4.5 * s
            dy = math.sin(rad) * 4.5 * s
            draw.line([(9.0*s - dx, ty - dy), (9.0*s + dx, ty + dy)], fill=c_lightning_bright, width=int(1.4*s))
        draw.ellipse([7.5*s, ty - 1.5*s, 10.5*s, ty + 1.5*s], fill=c_gold)

        # Flared nozzle
        nozzle_pts = [
            (12.0*s, ty - 6.5*s),
            (15.5*s, ty - 4.0*s),
            (15.5*s, ty + 4.0*s),
            (12.0*s, ty + 6.5*s)
        ]
        draw.polygon(nozzle_pts, fill=c_frame_light, outline=c_gold, width=int(0.8*s))
        draw.line([(12.5*s, ty), (15.5*s, ty)], fill=c_electric_blue, width=int(1.6*s))

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "wind_wall_tempest.png"), "wind_wall_tempest")

def gen_wind_wall_vortex():
    """16x64 Gale Vortex Wind Wall: dark titanium plating, aerodynamic vortex spirals, glowing teal vacuum conduits."""
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_frame_dark = (16, 26, 24, 255)
    c_frame_mid = (28, 48, 44, 255)
    c_frame_light = (45, 80, 72, 255)
    c_teal_glow = (0, 255, 200, 255)
    c_teal_bright = (190, 255, 240, 255)
    c_steel = (210, 230, 225, 255)

    # 1. Frame
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=2 * s, fill=c_frame_dark, outline=(8, 16, 14, 255), width=int(1.2*s))
    draw.rounded_rectangle([1.5 * s, 1.5 * s, sw - 1 - 1.5 * s, sh - 1 - 1.5 * s], radius=1.5 * s, fill=c_frame_mid)

    # Vacuum lines
    draw.line([(3.5*s, 4*s), (3.5*s, 60*s)], fill=c_teal_glow, width=int(1.6*s))
    draw.line([(3.5*s, 4*s), (3.5*s, 60*s)], fill=c_teal_bright, width=int(0.6*s))

    # Titanium bands
    for bky in [4*s, 24*s, 40*s, 60*s]:
        draw.rectangle([1.5*s, bky - 1.5*s, 14.5*s, bky + 1.5*s], fill=c_frame_light, outline=c_frame_dark, width=int(0.8*s))
        draw.ellipse([2.5*s, bky - 0.8*s, 4.5*s, bky + 0.8*s], fill=c_teal_glow)
        draw.ellipse([12*s, bky - 0.8*s, 13.5*s, bky + 0.8*s], fill=c_steel)

    # 3 Vortex intakes
    for ty in [14*s, 32*s, 50*s]:
        draw.ellipse([4.5*s, ty - 6*s, 14.5*s, ty + 6*s], fill=c_frame_dark, outline=c_teal_glow, width=int(1.2*s))
        draw.ellipse([6.5*s, ty - 4*s, 12.5*s, ty + 4*s], fill=c_frame_mid, outline=c_teal_bright, width=int(0.8*s))
        
        # Spiral swirl lines
        for r_step in range(1, 4):
            r = r_step * 1.3 * s
            draw.arc([9.5*s - r, ty - r, 9.5*s + r, ty + r], start=r_step*60, end=r_step*60 + 160, fill=c_teal_bright, width=int(1.0*s))
        draw.ellipse([8.5*s, ty - 1.0*s, 10.5*s, ty + 1.0*s], fill=c_teal_glow)

        # Aerodynamic vanes
        nozzle_pts = [
            (12.5*s, ty - 4.5*s),
            (15.2*s, ty - 2.0*s),
            (15.2*s, ty + 2.0*s),
            (12.5*s, ty + 4.5*s)
        ]
        draw.polygon(nozzle_pts, fill=c_frame_light, outline=c_teal_glow, width=int(0.6*s))

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "wind_wall_vortex.png"), "wind_wall_vortex")

# =========================================================================
# ACID WALL VARIANTS
# =========================================================================

def gen_acid_wall_vitriol():
    """16x64 Vitriol Melter Acid Wall: acid-etched corroded brass chassis, boiling neon-amber/yellow acid core, high-pressure injectors."""
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_dark_metal = (30, 26, 20, 255)
    c_mid_metal = (55, 48, 36, 255)
    c_brass_etched = (210, 160, 40, 255)
    c_sulfur_yellow = (255, 225, 30, 255)
    c_vitriol_bright = (255, 250, 160, 255)
    c_hazard_orange = (255, 110, 20, 255)

    # 1. Corroded brass casing
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=2 * s, fill=c_dark_metal, outline=(16, 14, 10, 255), width=int(1.2*s))
    draw.rounded_rectangle([1.5 * s, 1.5 * s, sw - 1 - 1.5 * s, sh - 1 - 1.5 * s], radius=1.5 * s, fill=c_mid_metal)

    # Amber hazard accents
    for hy in [3*s, 6*s, 57*s, 60*s]:
        draw.line([(2*s, hy), (7*s, hy)], fill=c_hazard_orange, width=int(1.2*s))

    # Dual Superheated Vitriol Canisters
    draw.rounded_rectangle([3*s, 8*s, 7*s, 30*s], radius=1*s, fill=c_hazard_orange, outline=c_brass_etched, width=int(0.8*s))
    draw.rounded_rectangle([4*s, 10*s, 6*s, 28*s], radius=0.5*s, fill=c_sulfur_yellow)
    draw.line([(5*s, 12*s), (5*s, 26*s)], fill=c_vitriol_bright, width=int(0.8*s))

    draw.rounded_rectangle([3*s, 34*s, 7*s, 56*s], radius=1*s, fill=c_hazard_orange, outline=c_brass_etched, width=int(0.8*s))
    draw.rounded_rectangle([4*s, 36*s, 6*s, 54*s], radius=0.5*s, fill=c_sulfur_yellow)
    draw.line([(5*s, 38*s), (5*s, 52*s)], fill=c_vitriol_bright, width=int(0.8*s))

    # Distribution pipe
    draw.line([(7*s, 19*s), (9*s, 19*s)], fill=c_brass_etched, width=int(1.4*s))
    draw.line([(7*s, 45*s), (9*s, 45*s)], fill=c_brass_etched, width=int(1.4*s))
    draw.line([(9*s, 10*s), (9*s, 54*s)], fill=c_brass_etched, width=int(1.2*s))

    # 4 Superheated injectors
    for ny in [10*s, 24*s, 40*s, 54*s]:
        nozzle_pts = [
            (8.5*s, ny - 3.0*s),
            (14.5*s, ny - 1.5*s),
            (15.2*s, ny),
            (14.5*s, ny + 1.5*s),
            (8.5*s, ny + 3.0*s),
        ]
        draw.polygon(nozzle_pts, fill=c_dark_metal, outline=c_brass_etched, width=int(0.8*s))
        draw.line([(9.5*s, ny), (14.5*s, ny)], fill=c_sulfur_yellow, width=int(1.4*s))
        draw.ellipse([14.0*s, ny - 1.0*s, 15.5*s, ny + 1.0*s], fill=c_vitriol_bright)

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "acid_wall_vitriol.png"), "acid_wall_vitriol")

def gen_acid_wall_sludge():
    """16x64 Caustic Sludge Acid Wall: toxic purple & biohazard green sludge canisters, heavy distribution manifold."""
    width, height, s = 16, 64, 8
    sw, sh = width * s, height * s
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    c_dark_metal = (24, 20, 30, 255)
    c_mid_metal = (44, 34, 56, 255)
    c_purple_toxic = (150, 45, 215, 255)
    c_slime_green = (85, 245, 40, 255)
    c_slime_bright = (185, 255, 130, 255)
    c_hazard_magenta = (230, 60, 160, 255)

    # 1. Dark purple/charcoal frame
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=2 * s, fill=c_dark_metal, outline=(14, 10, 18, 255), width=int(1.2*s))
    draw.rounded_rectangle([1.5 * s, 1.5 * s, sw - 1 - 1.5 * s, sh - 1 - 1.5 * s], radius=1.5 * s, fill=c_mid_metal)

    # Magenta warning stripes
    for hy in [3*s, 6*s, 57*s, 60*s]:
        draw.line([(2*s, hy), (7*s, hy)], fill=c_hazard_magenta, width=int(1.2*s))

    # Toxic Sludge Canisters
    draw.rounded_rectangle([3*s, 8*s, 7*s, 30*s], radius=1*s, fill=c_purple_toxic, outline=c_hazard_magenta, width=int(0.8*s))
    draw.rounded_rectangle([4*s, 10*s, 6*s, 28*s], radius=0.5*s, fill=c_slime_green)
    draw.line([(5*s, 12*s), (5*s, 26*s)], fill=c_slime_bright, width=int(0.8*s))

    draw.rounded_rectangle([3*s, 34*s, 7*s, 56*s], radius=1*s, fill=c_purple_toxic, outline=c_hazard_magenta, width=int(0.8*s))
    draw.rounded_rectangle([4*s, 36*s, 6*s, 54*s], radius=0.5*s, fill=c_slime_green)
    draw.line([(5*s, 38*s), (5*s, 52*s)], fill=c_slime_bright, width=int(0.8*s))

    # Sludge conduits
    draw.line([(7*s, 19*s), (9*s, 19*s)], fill=c_purple_toxic, width=int(1.4*s))
    draw.line([(7*s, 45*s), (9*s, 45*s)], fill=c_purple_toxic, width=int(1.4*s))
    draw.line([(9*s, 10*s), (9*s, 54*s)], fill=c_purple_toxic, width=int(1.2*s))

    # 4 Viscous nozzles
    for ny in [10*s, 24*s, 40*s, 54*s]:
        nozzle_pts = [
            (8.5*s, ny - 3.0*s),
            (14.5*s, ny - 1.5*s),
            (15.2*s, ny),
            (14.5*s, ny + 1.5*s),
            (8.5*s, ny + 3.0*s),
        ]
        draw.polygon(nozzle_pts, fill=c_dark_metal, outline=c_purple_toxic, width=int(0.8*s))
        draw.line([(9.5*s, ny), (14.5*s, ny)], fill=c_slime_green, width=int(1.4*s))
        draw.ellipse([14.0*s, ny - 1.0*s, 15.5*s, ny + 1.0*s], fill=c_slime_bright)

    return save_cropped_sprite(img, (width, height), os.path.join(VARIANTS_DIR, "acid_wall_sludge.png"), "acid_wall_sludge")

# =========================================================================
# 3. ARTILLERY VARIANTS
# =========================================================================

def gen_artillery_thermite():
    """Thermite Carpet Artillery: scorched magma-bronze armor hull, dual flank thermite superheater canisters, glowing molten thermite barrels with yellow heat cores, and flared furnace muzzles."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark_hull = (30, 16, 18, 255)
    c_mid_hull = (54, 26, 30, 255)
    c_metal_hot = (75, 32, 36, 255)
    c_magma_deep = (200, 30, 20, 255)
    c_magma_orange = (255, 100, 15, 255)
    c_magma_yellow = (255, 225, 55, 255)
    c_magma_white = (255, 255, 220, 255)
    c_brass = (245, 180, 45, 255)

    # 1. 64x64 Solid Base with beveled armor corners
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark_hull, outline=(18, 8, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid_hull)

    # 4 Corner Fortification Anchor Lugs with Searing Centers
    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_dark_hull, outline=c_magma_orange, width=int(1.2*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_magma_yellow)

    # 2. Central Swivel Ring
    draw.ellipse([cx - 19*f, cy - 19*f, cx + 19*f, cy + 19*f], fill=c_dark_hull, outline=c_magma_orange, width=int(2*f))
    draw.ellipse([cx - 14*f, cy - 14*f, cx + 14*f, cy + 14*f], fill=c_mid_hull)

    # 3. Dual Flank Thermite Superheater Canisters (Distinctive Incendiary Chemical Pods)
    # Top canister
    draw.rounded_rectangle([cx - 17*f, cy - 23*f, cx + 3*f, cy - 14*f], radius=2.5*f, fill=c_magma_deep, outline=c_brass, width=int(1.5*f))
    draw.line([cx - 15*f, cy - 18.5*f, cx + 1*f, cy - 18.5*f], fill=c_magma_yellow, width=int(1.8*f))
    draw.regular_polygon((cx - 17*f, cy - 18.5*f, 2.5*f), 4, rotation=45, fill=c_brass)
    # Bottom canister
    draw.rounded_rectangle([cx - 17*f, cy + 14*f, cx + 3*f, cy + 23*f], radius=2.5*f, fill=c_magma_deep, outline=c_brass, width=int(1.5*f))
    draw.line([cx - 15*f, cy + 18.5*f, cx + 1*f, cy + 18.5*f], fill=c_magma_yellow, width=int(1.8*f))
    draw.regular_polygon((cx - 17*f, cy + 18.5*f, 2.5*f), 4, rotation=45, fill=c_brass)

    # 4. Rear Ammo Breech Housing with Fiery Thermite Hazard Stripes
    draw.rounded_rectangle([cx - 23*f, cy - 15*f, cx - 4*f, cy + 15*f], radius=3*f, fill=c_dark_hull, outline=c_brass, width=int(1.8*f))
    draw.rounded_rectangle([cx - 21*f, cy - 13*f, cx - 6*f, cy + 13*f], radius=2*f, fill=c_mid_hull)

    for hy in [-10*f, -5*f, 0, 5*f, 10*f]:
        draw.line([cx - 20*f, cy + hy, cx - 7*f, cy + hy], fill=c_magma_orange, width=int(1.6*f))

    # 5. Heavy Twin Glowing Molten Thermite Barrels
    for barrel_y in [-7*f, 7*f]:
        # Recoil Hydraulic Sleeve with Heat Dissipation Rings
        draw.rounded_rectangle([cx - 5*f, cy + barrel_y - 4*f, cx + 9*f, cy + barrel_y + 4*f], radius=2*f, fill=c_metal_hot, outline=c_brass, width=int(1.5*f))
        draw.line([cx - 4*f, cy + barrel_y - 2*f, cx + 8*f, cy + barrel_y - 2*f], fill=c_magma_orange, width=int(1.2*f))
        draw.line([cx - 2*f, cy + barrel_y - 3*f, cx - 2*f, cy + barrel_y + 3*f], fill=c_magma_yellow, width=int(1.0*f))
        draw.line([cx + 4*f, cy + barrel_y - 3*f, cx + 4*f, cy + barrel_y + 3*f], fill=c_magma_yellow, width=int(1.0*f))

        # Glowing Superheated Barrel Tubes (Fiery orange shell + bright yellow/white core)
        draw.rectangle([cx + 8*f, cy + barrel_y - 2.8*f, cx + 25*f, cy + barrel_y + 2.8*f], fill=c_magma_deep, outline=c_magma_orange, width=int(1.2*f))
        draw.line([cx + 8*f, cy + barrel_y, cx + 25*f, cy + barrel_y], fill=c_magma_yellow, width=int(2.2*f))
        draw.line([cx + 10*f, cy + barrel_y, cx + 23*f, cy + barrel_y], fill=c_magma_white, width=int(1.0*f))

        # Flared Heavy Furnace Muzzle Cowl
        muzzle_pts = [
            (cx + 25*f, cy + barrel_y - 5.0*f),
            (cx + 30*f, cy + barrel_y - 4.0*f),
            (cx + 30*f, cy + barrel_y + 4.0*f),
            (cx + 25*f, cy + barrel_y + 5.0*f),
        ]
        draw.polygon(muzzle_pts, fill=c_magma_deep, outline=c_brass, width=int(1.5*f))
        draw.line([cx + 28*f, cy + barrel_y - 4*f, cx + 28*f, cy + barrel_y + 4*f], fill=c_magma_white, width=int(2.0*f))

    # 6. Center Breech Mantlet & Searing Thermal Optic
    draw.polygon([
        (cx - 10*f, cy - 10*f),
        (cx + 7*f, cy - 8*f),
        (cx + 12*f, cy),
        (cx + 7*f, cy + 8*f),
        (cx - 10*f, cy + 10*f),
    ], fill=c_dark_hull, outline=c_magma_orange, width=int(1.8*f))

    # Searing Thermal Eye
    draw.ellipse([cx + 1*f, cy - 4*f, cx + 9*f, cy + 4*f], fill=c_dark_hull, outline=c_brass, width=int(1.2*f))
    draw.ellipse([cx + 2.5*f, cy - 2.5*f, cx + 7.5*f, cy + 2.5*f], fill=c_magma_yellow)
    draw.ellipse([cx + 4.0*f, cy - 1.2*f, cx + 6.5*f, cy + 1.2*f], fill=c_magma_white)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "artillery_thermite.png"), "artillery_thermite")

def gen_artillery_salvo():
    """Heavy Salvo Artillery: maintains full base artillery structure with rapid-feed ammo magazine, twin fluted rapid barrels, vented muzzles, advanced sensor pod."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark_hull = (16, 18, 24, 255)
    c_mid_hull = (28, 36, 48, 255)
    c_metal_light = (65, 85, 110, 255)
    c_metal_highlight = (95, 120, 150, 255)
    c_cyan = (0, 235, 255, 255)
    c_amber = (255, 185, 30, 255)
    c_hazard_yellow = (255, 215, 0, 255)

    # 1. 64x64 Solid Base with beveled armor corners
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark_hull, outline=(10, 12, 16, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid_hull)

    # 4 Corner Fortification Anchor Lugs
    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_dark_hull, outline=c_cyan, width=int(1.2*f))

    # 2. Central Swivel Ring
    draw.ellipse([cx - 19*f, cy - 19*f, cx + 19*f, cy + 19*f], fill=c_dark_hull, outline=c_cyan, width=int(2*f))
    draw.ellipse([cx - 14*f, cy - 14*f, cx + 14*f, cy + 14*f], fill=c_mid_hull)

    # 3. High-Capacity Ammo Drum / Breech Housing with Hazard Stripes
    draw.rounded_rectangle([cx - 23*f, cy - 15*f, cx - 4*f, cy + 15*f], radius=3*f, fill=c_dark_hull, outline=c_amber, width=int(1.8*f))
    draw.rounded_rectangle([cx - 21*f, cy - 13*f, cx - 6*f, cy + 13*f], radius=2*f, fill=c_mid_hull)

    for hy in [-10*f, -5*f, 0, 5*f, 10*f]:
        draw.line([cx - 20*f, cy + hy, cx - 7*f, cy + hy], fill=c_hazard_yellow, width=int(1.6*f))

    # 4. Heavy Twin Rapid-Cycle Artillery Barrels
    for barrel_y in [-7*f, 7*f]:
        # Recoil Hydraulic Sleeve
        draw.rounded_rectangle([cx - 5*f, cy + barrel_y - 4*f, cx + 9*f, cy + barrel_y + 4*f], radius=2*f, fill=c_metal_light, outline=c_dark_hull, width=int(1.5*f))
        draw.line([cx - 4*f, cy + barrel_y - 2*f, cx + 8*f, cy + barrel_y - 2*f], fill=c_metal_highlight, width=int(1.2*f))

        # Main Heavy Barrel Tube with Fluting Lines
        draw.rectangle([cx + 8*f, cy + barrel_y - 2.8*f, cx + 25*f, cy + barrel_y + 2.8*f], fill=c_mid_hull, outline=c_dark_hull, width=int(1.2*f))
        draw.line([cx + 9*f, cy + barrel_y, cx + 24*f, cy + barrel_y], fill=c_cyan, width=int(1.4*f))

        # Flared Muzzle Brake with Gas Vents
        muzzle_pts = [
            (cx + 25*f, cy + barrel_y - 4.5*f),
            (cx + 29*f, cy + barrel_y - 3.5*f),
            (cx + 29*f, cy + barrel_y + 3.5*f),
            (cx + 25*f, cy + barrel_y + 4.5*f),
        ]
        draw.polygon(muzzle_pts, fill=c_metal_light, outline=c_cyan, width=int(1.5*f))
        draw.line([cx + 27*f, cy + barrel_y - 4*f, cx + 27*f, cy + barrel_y + 4*f], fill=c_amber, width=int(1.5*f))

    # 5. Center Breech Mantlet & Sensor Pod
    draw.polygon([
        (cx - 10*f, cy - 10*f),
        (cx + 7*f, cy - 8*f),
        (cx + 12*f, cy),
        (cx + 7*f, cy + 8*f),
        (cx - 10*f, cy + 10*f),
    ], fill=c_dark_hull, outline=c_cyan, width=int(1.8*f))

    # Sensor Eye Lens
    draw.ellipse([cx + 1*f, cy - 4*f, cx + 9*f, cy + 4*f], fill=c_dark_hull, outline=c_amber, width=int(1.2*f))
    draw.ellipse([cx + 3*f, cy - 2.2*f, cx + 7.5*f, cy + 2.2*f], fill=c_cyan)
    draw.ellipse([cx + 4.5*f, cy - 1*f, cx + 6.5*f, cy + 1*f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "artillery_salvo.png"), "artillery_salvo")

# =========================================================================
# 4. BARRICADE VARIANTS
# =========================================================================

def gen_barricade_spikes():
    """Reinforced Barricade (+30% Health): massive reinforced composite armor plating, reinforced corner lugs with steel studs, interlocking blast collar, and heavy faceted blast shield with cross-bracing."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (16, 20, 28, 255)
    c_mid = (30, 38, 52, 255)
    c_steel_dark = (55, 70, 92, 255)
    c_steel_light = (90, 115, 145, 255)
    c_amber_glow = (255, 185, 30, 255)
    c_gold_rivet = (255, 215, 70, 255)

    # 1. Fortified 64x64 solid armor base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(10, 14, 20, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid)

    # Heavy Reinforced Corner Armor Brackets with Steel Studs
    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 5.5*f), 4, rotation=45, fill=c_steel_dark, outline=c_amber_glow, width=int(1.5*f))
        draw.ellipse([cx + ox - 1.8*f, cy + oy - 1.8*f, cx + ox + 1.8*f, cy + oy + 1.8*f], fill=c_gold_rivet)

    # Perimeter Armor Interlocking Plates (Edge reinforcements)
    for px, py in [(cx, 10*f), (cx, sh - 10*f), (10*f, cy), (sw - 10*f, cy)]:
        draw.regular_polygon((px, py, 3.5*f), 4, rotation=45, fill=c_dark, outline=c_steel_light, width=int(1.0*f))

    # 2. Heavy Octagonal Reinforced Blast Bulkhead
    draw.regular_polygon((cx, cy, 18*f), 8, rotation=22.5, fill=c_dark, outline=c_steel_light, width=int(2.2*f))
    draw.regular_polygon((cx, cy, 15*f), 8, rotation=22.5, fill=c_steel_dark, outline=c_amber_glow, width=int(1.2*f))

    # 3. Central Heavy Reinforced Blast Shield Plate (Faceted Diamond with Heavy Cross-Bracing)
    draw.polygon([(cx, cy - 13*f), (cx + 13*f, cy), (cx, cy + 13*f), (cx - 13*f, cy)], fill=c_steel_light, outline=c_dark, width=int(1.5*f))
    draw.polygon([(cx, cy - 11*f), (cx + 11*f, cy), (cx, cy), (cx - 11*f, cy)], fill=(130, 160, 200, 255))
    draw.polygon([(cx, cy), (cx + 11*f, cy), (cx, cy + 11*f), (cx - 11*f, cy)], fill=c_steel_dark)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "barricade_spikes.png"), "barricade_spikes")

def gen_barricade_spectral():
    """Spectral Barrier: maintains full base barricade anatomy with arcane anti-spectral field conduits and ethereal shield."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (16, 20, 32, 255)
    c_mid = (28, 38, 58, 255)
    c_cyan = (0, 245, 255, 255)
    c_magenta = (235, 50, 255, 255)
    c_light = (45, 65, 95, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(8, 12, 20, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid)

    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 5*f), 4, rotation=45, fill=c_dark, outline=c_cyan, width=int(1.5*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_magenta)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "barricade_spectral.png"), "barricade_spectral")

# =========================================================================
# 5. BOMB TOWER VARIANTS
# =========================================================================

def gen_bomb_incendiary():
    """Incendiary Shells Bomb Tower: preserves 4 corner hazard lugs, heavy octagonal mortar breech, concentric dome, and glowing fiery molten plasma bomb core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (22, 16, 18, 255)
    c_base_mid = (38, 26, 30, 255)
    c_turret_dark = (28, 18, 22, 255)
    c_crimson = (245, 40, 30, 255)
    c_neon_orange = (255, 120, 20, 255)
    c_neon_yellow = (255, 230, 60, 255)

    # 1. 64x64 Solid Base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_base_dark, outline=(14, 8, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_base_mid)

    # 4 Corner Hazard Lugs
    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_base_dark, outline=c_crimson, width=int(1.2*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_neon_orange)

    # 2. Heavy Octagonal Mortar Breech
    draw.regular_polygon((cx, cy, 19*f), 8, rotation=22.5, fill=c_base_dark, outline=c_crimson, width=int(2*f))
    draw.ellipse([cx - 13*f, cy - 13*f, cx + 13*f, cy + 13*f], fill=c_turret_dark, outline=(18, 10, 14, 255), width=int(1.5*f))

    # Flame Venting Slits
    for i in range(4):
        ang = (i * 90 + 45) * math.pi / 180.0
        vx, vy = cx + math.cos(ang) * 11 * f, cy + math.sin(ang) * 11 * f
        draw.regular_polygon((vx, vy, 2.0*f), 4, rotation=45, fill=c_neon_orange)

    # 3. Central Heavy Mortar Bore & Glowing Incendiary Shell
    draw.ellipse([cx - 9*f, cy - 9*f, cx + 9*f, cy + 9*f], fill=(12, 6, 8, 255), outline=c_neon_orange, width=int(2*f))
    draw.ellipse([cx - 5.5*f, cy - 5.5*f, cx + 5.5*f, cy + 5.5*f], fill=c_neon_orange)
    draw.ellipse([cx - 2.5*f, cy - 2.5*f, cx + 2.5*f, cy + 2.5*f], fill=c_neon_yellow)
    draw.ellipse([cx - 1.0*f, cy - 1.0*f, cx + 1.0*f, cy + 1.0*f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "bomb_tower_incendiary.png"), "bomb_tower_incendiary")

def gen_bomb_concussion():
    """Heavy Concussion Bomb Tower: preserves 4 corner hazard lugs, heavy octagonal mortar breech, concentric dome, and cyan/white shockwave containment core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (16, 20, 28, 255)
    c_base_mid = (30, 38, 52, 255)
    c_turret_dark = (20, 26, 36, 255)
    c_cyan = (0, 235, 255, 255)
    c_steel = (180, 210, 240, 255)
    c_white = (240, 250, 255, 255)

    # 1. 64x64 Solid Base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_base_dark, outline=(8, 12, 18, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_base_mid)

    # 4 Corner Hazard Lugs
    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_base_dark, outline=c_cyan, width=int(1.2*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_white)

    # 2. Heavy Octagonal Mortar Breech
    draw.regular_polygon((cx, cy, 19*f), 8, rotation=22.5, fill=c_base_dark, outline=c_cyan, width=int(2*f))
    draw.ellipse([cx - 13*f, cy - 13*f, cx + 13*f, cy + 13*f], fill=c_turret_dark, outline=(10, 16, 24, 255), width=int(1.5*f))

    # Shockwave expansion rings
    draw.ellipse([cx - 11*f, cy - 11*f, cx + 11*f, cy + 11*f], outline=c_steel, width=int(1.0*f))

    # 3. Central Heavy Mortar Bore & Shockwave Core
    draw.ellipse([cx - 9*f, cy - 9*f, cx + 9*f, cy + 9*f], fill=(6, 8, 14, 255), outline=c_white, width=int(2*f))
    draw.ellipse([cx - 5.5*f, cy - 5.5*f, cx + 5.5*f, cy + 5.5*f], fill=c_cyan)
    draw.ellipse([cx - 2.5*f, cy - 2.5*f, cx + 2.5*f, cy + 2.5*f], fill=c_white)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "bomb_tower_concussion.png"), "bomb_tower_concussion")

# =========================================================================
# 6. BRIMSTONE VARIANTS
# =========================================================================

def gen_brimstone_hellfire():
    """Hellfire Core: Overclocked incandescent hellstone hearth with accelerated cooling conduits and blistering white-hot reactor core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_frame_dark = (20, 15, 14, 255)
    c_frame_mid = (34, 24, 20, 255)
    c_frame_edge = (12, 8, 6, 255)
    c_gold_heat = (245, 170, 35, 255)

    c_lava_deep = (180, 30, 10, 255)
    c_lava_crimson = (245, 65, 15, 255)
    c_lava_orange = (255, 145, 25, 255)
    c_lava_yellow = (255, 235, 75, 255)
    c_lava_white = (255, 255, 240, 255)

    # 1. Base Chassis
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_frame_dark, outline=c_frame_edge, width=int(2 * f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_frame_mid)

    # 2. 4 Overheated Supercharger Heat-Pipes connecting Core to Corners
    corner_offsets = [(-21 * f, -21 * f), (21 * f, -21 * f), (-21 * f, 21 * f), (21 * f, 21 * f)]
    for ox, oy in corner_offsets:
        # Direct thermal supercharger pipe
        draw.line([cx, cy, cx + ox, cy + oy], fill=c_lava_crimson, width=int(4.2 * f))
        draw.line([cx, cy, cx + ox, cy + oy], fill=c_lava_orange, width=int(2.6 * f))
        draw.line([cx, cy, cx + ox, cy + oy], fill=c_lava_yellow, width=int(1.2 * f))
        # Corner Capacitor / Heat Sink Radiator
        draw.rounded_rectangle([cx + ox - 5 * f, cy + oy - 5 * f, cx + ox + 5 * f, cy + oy + 5 * f], radius=2 * f, fill=(45, 28, 22, 255), outline=c_gold_heat, width=int(1.5 * f))
        draw.ellipse([cx + ox - 2.2 * f, cy + oy - 2.2 * f, cx + ox + 2.2 * f, cy + oy + 2.2 * f], fill=c_lava_yellow, outline=c_lava_orange, width=int(0.8 * f))
        draw.ellipse([cx + ox - 1.2 * f, cy + oy - 1.2 * f, cx + ox + 1.2 * f, cy + oy + 1.2 * f], fill=c_lava_white)

    # 3. Thermal Hazard Rails (bright gold/orange) with chevron indicators
    for ry in [6 * f, sh - 6 * f]:
        draw.line([14 * f, ry, sw - 14 * f, ry], fill=c_gold_heat, width=int(1.8 * f))
        for rx in [-10 * f, -3 * f, 3 * f, 10 * f]:
            draw.line([cx + rx - 1.5 * f, ry - 1 * f, cx + rx + 1.5 * f, ry + 1 * f], fill=c_lava_white, width=int(1 * f))

    # 4. Central Octagonal Crucible
    r_hearth = 21 * f
    draw.regular_polygon((cx, cy, r_hearth), 8, rotation=22.5, fill=c_frame_dark, outline=c_gold_heat, width=int(2 * f))
    draw.regular_polygon((cx, cy, r_hearth - 2 * f), 8, rotation=22.5, fill=(16, 10, 8, 255))

    # White-hot Radiant Underglow
    draw.ellipse([cx - 17 * f, cy - 17 * f, cx + 17 * f, cy + 17 * f], fill=c_lava_deep)
    draw.ellipse([cx - 13 * f, cy - 13 * f, cx + 13 * f, cy + 13 * f], fill=c_lava_crimson)
    draw.ellipse([cx - 9 * f, cy - 9 * f, cx + 9 * f, cy + 9 * f], fill=c_lava_orange)
    draw.ellipse([cx - 6 * f, cy - 6 * f, cx + 6 * f, cy + 6 * f], fill=c_lava_yellow)

    # 5. Overclocked Radiant Thermal Vents in 4 cardinal quadrants
    for sign_y in [-1, 1]:
        for dy in [5 * f, 10 * f, 14 * f]:
            y = cy + sign_y * dy
            span = 12 * f - (dy * 0.45)
            draw.rounded_rectangle([cx - span, y - 1.2 * f, cx + span, y + 1.2 * f], radius=1 * f, fill=c_frame_dark, outline=c_lava_orange, width=int(1 * f))
            draw.line([cx - span + 2 * f, y, cx + span - 2 * f, y], fill=c_lava_white, width=int(1.2 * f))

    for sign_x in [-1, 1]:
        x = cx + sign_x * 12 * f
        draw.rounded_rectangle([x - 1.5 * f, cy - 7 * f, x + 1.5 * f, cy + 7 * f], radius=1 * f, fill=c_frame_dark, outline=c_lava_orange, width=int(1 * f))
        draw.line([x, cy - 5 * f, x, cy + 5 * f], fill=c_lava_white, width=int(1.2 * f))

    # 6. Searing Incandescent Hellfire Reactor Core
    draw.regular_polygon((cx, cy, 8.5 * f), 8, rotation=22.5, fill=c_frame_dark, outline=c_gold_heat, width=int(2 * f))
    draw.ellipse([cx - 6 * f, cy - 6 * f, cx + 6 * f, cy + 6 * f], fill=c_lava_orange)
    draw.ellipse([cx - 4.5 * f, cy - 4.5 * f, cx + 4.5 * f, cy + 4.5 * f], fill=c_lava_yellow)
    draw.ellipse([cx - 3 * f, cy - 3 * f, cx + 3 * f, cy + 3 * f], fill=c_lava_white)
    draw.regular_polygon((cx, cy, 2.2 * f), 4, rotation=45, fill=(255, 255, 255, 255))

    # 4 Cardinal Supercharged Igniter Nodes
    for ox, oy in [(0, -8.5 * f), (0, 8.5 * f), (-8.5 * f, 0), (8.5 * f, 0)]:
        draw.ellipse([cx + ox - 1.8 * f, cy + oy - 1.8 * f, cx + ox + 1.8 * f, cy + oy + 1.8 * f], fill=c_lava_white, outline=c_lava_yellow, width=int(0.8 * f))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "brimstone_hellfire.png"), "brimstone_hellfire")

def gen_brimstone_void():
    """Nether Void: Deep void obsidian chassis with wide-aperture rift nozzles, cosmic magenta inferno underglow, and electric cyan plasma nodes."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_frame_dark = (16, 12, 24, 255)
    c_frame_mid = (26, 18, 38, 255)
    c_frame_edge = (10, 8, 16, 255)
    c_void_bracket = (48, 30, 68, 255)

    c_void_deep = (45, 10, 65, 255)
    c_void_magenta = (185, 30, 220, 255)
    c_void_bright = (235, 65, 255, 255)
    c_cyan_glow = (0, 235, 255, 255)
    c_core_white = (245, 235, 255, 255)

    # 1. Base Chassis
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_frame_dark, outline=c_frame_edge, width=int(2 * f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_frame_mid)

    # 2. 4 Corner Void Rift Crystals / Multi-target Field Projectors
    corner_offsets = [(-21 * f, -21 * f), (21 * f, -21 * f), (-21 * f, 21 * f), (21 * f, 21 * f)]
    for ox, oy in corner_offsets:
        draw.rounded_rectangle([cx + ox - 5 * f, cy + oy - 5 * f, cx + ox + 5 * f, cy + oy + 5 * f], radius=2 * f, fill=c_void_bracket, outline=c_frame_dark, width=int(1.2 * f))
        # Cyan void rune node
        draw.regular_polygon((cx + ox, cy + oy, 3 * f), 4, rotation=45, fill=c_cyan_glow, outline=c_void_bright, width=int(1 * f))
        draw.ellipse([cx + ox - 1 * f, cy + oy - 1 * f, cx + ox + 1 * f, cy + oy + 1 * f], fill=c_core_white)

    # 3. Cyan Void Resonance Rails (top & bottom)
    for ry in [6 * f, sh - 6 * f]:
        draw.line([14 * f, ry, sw - 14 * f, ry], fill=c_cyan_glow, width=int(1.5 * f))
        for rx in [-10 * f, -3 * f, 3 * f, 10 * f]:
            draw.line([cx + rx - 1.5 * f, ry - 1 * f, cx + rx + 1.5 * f, ry + 1 * f], fill=c_void_bright, width=int(1 * f))

    # 4. Central Octagonal Void Hearth
    r_hearth = 21 * f
    draw.regular_polygon((cx, cy, r_hearth), 8, rotation=22.5, fill=c_frame_dark, outline=c_void_bright, width=int(2 * f))
    draw.regular_polygon((cx, cy, r_hearth - 2 * f), 8, rotation=22.5, fill=(14, 8, 20, 255))

    # Cosmic Magenta Netherfire Underglow
    draw.ellipse([cx - 16 * f, cy - 16 * f, cx + 16 * f, cy + 16 * f], fill=c_void_deep)
    draw.ellipse([cx - 12 * f, cy - 12 * f, cx + 12 * f, cy + 12 * f], fill=c_void_magenta)
    draw.ellipse([cx - 8 * f, cy - 8 * f, cx + 8 * f, cy + 8 * f], fill=c_void_bright)

    # 5. 4 Wide-Aperture Multi-Target Void Flame Vents
    # Diagonal energy conduits
    d = 16 * f
    for dx, dy in [(-d, -d), (d, -d), (-d, d), (d, d)]:
        draw.line([cx, cy, cx + dx, cy + dy], fill=c_frame_dark, width=int(3.2 * f))
        draw.line([cx, cy, cx + dx, cy + dy], fill=c_void_magenta, width=int(1.8 * f))
        draw.line([cx, cy, cx + dx, cy + dy], fill=c_cyan_glow, width=int(0.8 * f))

    # 4 Expanded Outer Apertures (North, South, East, West)
    for sign_y in [-1, 1]:
        for dy in [5 * f, 10 * f, 14 * f]:
            y = cy + sign_y * dy
            span = 12 * f - (dy * 0.45)
            draw.rounded_rectangle([cx - span, y - 1.2 * f, cx + span, y + 1.2 * f], radius=1 * f, fill=c_frame_dark, outline=c_void_magenta, width=int(1 * f))
            draw.line([cx - span + 2 * f, y, cx + span - 2 * f, y], fill=c_cyan_glow, width=int(1.2 * f))

    for sign_x in [-1, 1]:
        x = cx + sign_x * 12 * f
        draw.rounded_rectangle([x - 1.5 * f, cy - 7 * f, x + 1.5 * f, cy + 7 * f], radius=1 * f, fill=c_frame_dark, outline=c_void_magenta, width=int(1 * f))
        draw.line([x, cy - 5 * f, x, cy + 5 * f], fill=c_cyan_glow, width=int(1.2 * f))

    # 6. Central Nether Singularity Crucible
    draw.regular_polygon((cx, cy, 7.5 * f), 8, rotation=22.5, fill=c_frame_dark, outline=c_cyan_glow, width=int(1.8 * f))
    draw.ellipse([cx - 5 * f, cy - 5 * f, cx + 5 * f, cy + 5 * f], fill=c_void_magenta)
    draw.ellipse([cx - 3.5 * f, cy - 3.5 * f, cx + 3.5 * f, cy + 3.5 * f], fill=c_cyan_glow)
    draw.regular_polygon((cx, cy, 2.5 * f), 4, rotation=45, fill=c_core_white)

    # 4 Cardinal Void Plasma Nodes
    for ox, oy in [(0, -7.5 * f), (0, 7.5 * f), (-7.5 * f, 0), (7.5 * f, 0)]:
        draw.ellipse([cx + ox - 1.5 * f, cy + oy - 1.5 * f, cx + ox + 1.5 * f, cy + oy + 1.5 * f], fill=c_core_white, outline=c_cyan_glow, width=int(0.8 * f))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "brimstone_void.png"), "brimstone_void")

# =========================================================================
# 7. CORROSIVE VAPOR VARIANTS
# =========================================================================

def gen_corrosive_acid():
    """Concentrated Acid: hazard-striped plate, circular acid chamber, acidic vapor vents."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (16, 24, 14, 255)
    c_plate_mid = (28, 46, 24, 255)
    c_hazard_yellow = (210, 200, 20, 255)
    c_acid = (80, 255, 40, 255)
    c_bright = (220, 255, 120, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_plate_dark, outline=(8, 16, 8, 255), width=int(2*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_plate_mid)
    draw.line([6*f, 8*f, 6*f, sh-8*f], fill=c_hazard_yellow, width=int(2*f))
    draw.line([sw-6*f, 8*f, sw-6*f, sh-8*f], fill=c_hazard_yellow, width=int(2*f))

    draw.ellipse([cx-20*f, cy-20*f, cx+20*f, cy+20*f], fill=c_plate_dark, outline=c_acid, width=int(2*f))

    for vy in [-12*f, -6*f, 0, 6*f, 12*f]:
        span = 14*f if abs(vy) < 8*f else 10*f
        draw.rounded_rectangle([cx-span, cy+vy-1.8*f, cx+span, cy+vy+1.8*f], radius=1.5*f, fill=(0, 0, 0, 255), outline=c_acid, width=int(1.2*f))
        draw.line([cx-span+2*f, cy+vy, cx+span-2*f, cy+vy], fill=c_bright, width=int(1.5*f))

    draw.ellipse([cx-4*f, cy-4*f, cx+4*f, cy+4*f], fill=c_bright)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "corrosive_vapor_acid.png"), "corrosive_vapor_acid")

def gen_corrosive_volatile():
    """Volatile Dispersion: rapid injector vapor grille with high-pressure cyan-lime vents."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (14, 24, 26, 255)
    c_plate_mid = (24, 44, 48, 255)
    c_hazard_yellow = (210, 200, 20, 255)
    c_cyan = (0, 245, 220, 255)
    c_bright = (200, 255, 245, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_plate_dark, outline=(6, 16, 18, 255), width=int(2*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_plate_mid)
    draw.line([6*f, 8*f, 6*f, sh-8*f], fill=c_hazard_yellow, width=int(2*f))
    draw.line([sw-6*f, 8*f, sw-6*f, sh-8*f], fill=c_hazard_yellow, width=int(2*f))

    draw.ellipse([cx-20*f, cy-20*f, cx+20*f, cy+20*f], fill=c_plate_dark, outline=c_cyan, width=int(2*f))

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
    """Spectral Bolt Crossbow: grounded in the base ballista design (8 perimeter lugs, shaded stock, composite limbs with pulleys, bowstring, quarrel) with subtle ethereal cyan/violet rune inlays and a phantom bolt."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (20, 24, 34, 255)
    c_stone_mid = (36, 44, 60, 255)
    c_stone_light = (65, 80, 105, 255)
    c_wood_dark = (35, 30, 48, 255)
    c_wood_mid = (65, 55, 85, 255)
    c_wood_light = (95, 80, 120, 255)
    c_metal = (50, 60, 80, 255)
    c_cyan = (0, 235, 255, 255)
    c_purple = (185, 55, 255, 255)
    c_ghost_white = (230, 250, 255, 255)

    # 1. Foundation Base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(10, 14, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    for ox, oy in [(-22 * f, -22 * f), (22 * f, -22 * f), (-22 * f, 22 * f), (22 * f, 22 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_stone_light, outline=c_stone_dark, width=int(1.2*f))

    # 2. Central Swivel Ring Platform with Wood Inlay
    draw.ellipse([cx - 18*f, cy - 18*f, cx + 18*f, cy + 18*f], fill=c_stone_dark, outline=c_cyan, width=int(2*f))
    draw.ellipse([cx - 13*f, cy - 13*f, cx + 13*f, cy + 13*f], fill=c_wood_mid, outline=c_wood_dark, width=int(1.2*f))

    # 3. Heavy Ballista Chassis / Stock (Pointing +X)
    body_pts = [
        (cx - 18*f, cy - 6*f),
        (cx + 10*f, cy - 6*f),
        (cx + 26*f, cy - 3.5*f),
        (cx + 26*f, cy + 3.5*f),
        (cx + 10*f, cy + 6*f),
        (cx - 18*f, cy + 6*f),
    ]
    draw.polygon(body_pts, fill=c_wood_dark, outline=c_stone_dark, width=int(1.8*f))
    draw.polygon([(cx - 17*f, cy - 5*f), (cx + 10*f, cy - 5*f), (cx + 25*f, cy), (cx - 17*f, cy)], fill=c_wood_light)
    draw.polygon([(cx - 17*f, cy), (cx + 25*f, cy), (cx + 10*f, cy + 5*f), (cx - 17*f, cy + 5*f)], fill=c_wood_mid)
    draw.line([(cx - 14*f, cy), (cx + 25*f, cy)], fill=c_cyan, width=int(2.0*f))

    # 4. Composite Crossbow Limbs with Spectral Rune Inlay
    limb_upper = [
        (cx - 3*f, cy - 5*f),
        (cx + 10*f, cy - 25*f),
        (cx + 17*f, cy - 25*f),
        (cx + 7*f, cy - 5*f),
    ]
    draw.polygon(limb_upper, fill=c_wood_mid, outline=c_metal, width=int(1.8*f))
    draw.polygon([(cx + 2*f, cy - 5*f), (cx + 15*f, cy - 24*f), (cx + 11*f, cy - 24*f), (cx - 1*f, cy - 5*f)], fill=c_wood_light)
    # Subtle rune glow line on upper limb
    draw.line([(cx + 3*f, cy - 7*f), (cx + 12*f, cy - 22*f)], fill=c_cyan, width=int(1.2*f))

    limb_lower = [
        (cx - 3*f, cy + 5*f),
        (cx + 10*f, cy + 25*f),
        (cx + 17*f, cy + 25*f),
        (cx + 7*f, cy + 5*f),
    ]
    draw.polygon(limb_lower, fill=c_wood_dark, outline=c_metal, width=int(1.8*f))
    draw.polygon([(cx + 2*f, cy + 5*f), (cx + 15*f, cy + 24*f), (cx + 11*f, cy + 24*f), (cx - 1*f, cy + 5*f)], fill=c_wood_mid)
    draw.line([(cx + 3*f, cy + 7*f), (cx + 12*f, cy + 22*f)], fill=c_cyan, width=int(1.2*f))

    # Limb tip caps / pulleys
    draw.regular_polygon((cx + 13.5*f, cy - 25*f, 3.2*f), 4, rotation=45, fill=c_cyan, outline=c_stone_dark, width=int(1.2*f))
    draw.regular_polygon((cx + 13.5*f, cy + 25*f, 3.2*f), 4, rotation=45, fill=c_cyan, outline=c_stone_dark, width=int(1.2*f))

    # 5. Spectral Bowstring
    draw.line([(cx + 13.5*f, cy - 24*f), (cx - 6*f, cy)], fill=c_cyan, width=int(2.2*f))
    draw.line([(cx + 13.5*f, cy + 24*f), (cx - 6*f, cy)], fill=c_cyan, width=int(2.2*f))

    # 6. Primed Spectral Quarrel (Ghostly bolt)
    draw.line([(cx - 5*f, cy), (cx + 22*f, cy)], fill=c_cyan, width=int(2.5*f))
    bolt_head = [
        (cx + 29*f, cy),
        (cx + 21*f, cy - 3.5*f),
        (cx + 23*f, cy),
        (cx + 21*f, cy + 3.5*f),
    ]
    draw.polygon(bolt_head, fill=c_ghost_white, outline=c_purple, width=int(1.0*f))

    # Spectral fletching & trigger housing
    draw.polygon([(cx - 5*f, cy - 2.5*f), (cx - 1*f, cy), (cx - 5*f, cy + 2.5*f)], fill=c_purple)
    draw.ellipse([cx - 10*f, cy - 4.5*f, cx - 1*f, cy + 4.5*f], fill=c_stone_dark, outline=c_cyan, width=int(1.2*f))
    draw.ellipse([cx - 7.5*f, cy - 2.5*f, cx - 3.5*f, cy + 2.5*f], fill=c_ghost_white)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "crossbow_spectral.png"), "crossbow_spectral")

def gen_crossbow_windlass():
    """Quick Windlass Crossbow: maintains base ballista foundation, adds high-tension compound dual-pulleys and a mechanical brass spanning winch/windlass assembly at the rear of the stock."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (24, 28, 36, 255)
    c_stone_mid = (42, 50, 62, 255)
    c_stone_light = (70, 82, 100, 255)
    c_wood_dark = (85, 55, 32, 255)
    c_wood_mid = (135, 88, 50, 255)
    c_wood_light = (175, 115, 70, 255)
    c_metal = (55, 62, 75, 255)
    c_metal_light = (90, 105, 125, 255)
    c_brass = (215, 160, 45, 255)
    c_brass_bright = (255, 220, 90, 255)
    c_steel = (245, 250, 255, 255)

    # 1. Foundation Base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(14, 16, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    for ox, oy in [(-22 * f, -22 * f), (22 * f, -22 * f), (-22 * f, 22 * f), (22 * f, 22 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_stone_light, outline=c_stone_dark, width=int(1.2*f))

    # 2. Central Swivel Ring Platform with Wood Inlay
    draw.ellipse([cx - 18*f, cy - 18*f, cx + 18*f, cy + 18*f], fill=c_stone_dark, outline=c_brass, width=int(2*f))
    draw.ellipse([cx - 13*f, cy - 13*f, cx + 13*f, cy + 13*f], fill=c_wood_mid, outline=c_wood_dark, width=int(1.2*f))

    # 3. Heavy Ballista Chassis / Stock (Pointing +X)
    body_pts = [
        (cx - 20*f, cy - 6*f),
        (cx + 10*f, cy - 6*f),
        (cx + 26*f, cy - 3.5*f),
        (cx + 26*f, cy + 3.5*f),
        (cx + 10*f, cy + 6*f),
        (cx - 20*f, cy + 6*f),
    ]
    draw.polygon(body_pts, fill=c_wood_dark, outline=c_stone_dark, width=int(1.8*f))
    draw.polygon([(cx - 19*f, cy - 5*f), (cx + 10*f, cy - 5*f), (cx + 25*f, cy), (cx - 19*f, cy)], fill=c_wood_light)
    draw.polygon([(cx - 19*f, cy), (cx + 25*f, cy), (cx + 10*f, cy + 5*f), (cx - 19*f, cy + 5*f)], fill=c_wood_mid)
    draw.line([(cx - 14*f, cy), (cx + 25*f, cy)], fill=c_metal, width=int(2.0*f))

    # 4. Compound Crossbow Limbs (Reinforced high-tension)
    limb_upper = [
        (cx - 3*f, cy - 5*f),
        (cx + 10*f, cy - 25*f),
        (cx + 17*f, cy - 25*f),
        (cx + 7*f, cy - 5*f),
    ]
    draw.polygon(limb_upper, fill=c_wood_mid, outline=c_metal, width=int(1.8*f))
    draw.polygon([(cx + 2*f, cy - 5*f), (cx + 15*f, cy - 24*f), (cx + 11*f, cy - 24*f), (cx - 1*f, cy - 5*f)], fill=c_wood_light)

    limb_lower = [
        (cx - 3*f, cy + 5*f),
        (cx + 10*f, cy + 25*f),
        (cx + 17*f, cy + 25*f),
        (cx + 7*f, cy + 5*f),
    ]
    draw.polygon(limb_lower, fill=c_wood_dark, outline=c_metal, width=int(1.8*f))
    draw.polygon([(cx + 2*f, cy + 5*f), (cx + 15*f, cy + 24*f), (cx + 11*f, cy + 24*f), (cx - 1*f, cy + 5*f)], fill=c_wood_mid)

    # Compound Dual-Pulley Cams at limb tips
    draw.ellipse([cx + 11*f, cy - 27*f, cx + 16*f, cy - 22*f], fill=c_brass, outline=c_stone_dark, width=int(1.0*f))
    draw.ellipse([cx + 11*f, cy + 22*f, cx + 16*f, cy + 27*f], fill=c_brass, outline=c_stone_dark, width=int(1.0*f))
    draw.ellipse([cx + 12.5*f, cy - 25.5*f, cx + 14.5*f, cy - 23.5*f], fill=c_steel)
    draw.ellipse([cx + 12.5*f, cy + 23.5*f, cx + 14.5*f, cy + 25.5*f], fill=c_steel)

    # 5. Dual High-Tension Bowstrings
    draw.line([(cx + 13.5*f, cy - 24*f), (cx - 6*f, cy)], fill=(225, 230, 240, 255), width=int(2.2*f))
    draw.line([(cx + 13.5*f, cy + 24*f), (cx - 6*f, cy)], fill=(225, 230, 240, 255), width=int(2.2*f))

    # 6. Primed Heavy Armor-Piercing Bolt
    draw.line([(cx - 5*f, cy), (cx + 22*f, cy)], fill=c_wood_light, width=int(2.5*f))
    bolt_head = [
        (cx + 29*f, cy),
        (cx + 21*f, cy - 3.5*f),
        (cx + 23*f, cy),
        (cx + 21*f, cy + 3.5*f),
    ]
    draw.polygon(bolt_head, fill=c_steel, outline=c_stone_dark, width=int(1.0*f))
    draw.polygon([(cx - 5*f, cy - 2.5*f), (cx - 1*f, cy), (cx - 5*f, cy + 2.5*f)], fill=c_brass)

    # 7. Rear Mechanical Windlass Spanning Winch Mechanism
    draw.rounded_rectangle([cx - 24*f, cy - 8*f, cx - 13*f, cy + 8*f], radius=2*f, fill=c_metal, outline=c_stone_dark, width=int(1.2*f))
    # Brass winch spools & dual crank handles
    draw.ellipse([cx - 21*f, cy - 6*f, cx - 15*f, cy + 6*f], fill=c_brass, outline=c_stone_dark, width=int(1.0*f))
    draw.line([cx - 18*f, cy - 10*f, cx - 18*f, cy + 10*f], fill=c_brass_bright, width=int(2.0*f))
    draw.ellipse([cx - 19.5*f, cy - 11.5*f, cx - 16.5*f, cy - 8.5*f], fill=c_metal_light)
    draw.ellipse([cx - 19.5*f, cy + 8.5*f, cx - 16.5*f, cy + 11.5*f], fill=c_metal_light)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "crossbow_windlass.png"), "crossbow_windlass")

# =========================================================================
# 9. DISPLACER VARIANTS
# =========================================================================

def gen_displacer_warp():
    """Warp Vortex: retains base displacer frame, corner nodes, connecting lines, with magenta warp conduits."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (18, 12, 28, 255)
    c_plate_mid = (34, 22, 50, 255)
    c_magenta = (245, 45, 255, 255)
    c_white = (255, 230, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_plate_dark, outline=(10, 6, 16, 255), width=int(2*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_plate_mid)
    draw.ellipse([cx-24*f, cy-24*f, cx+24*f, cy+24*f], fill=c_plate_dark, outline=c_magenta, width=int(2*f))

    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx+ox, cy+oy, 4*f), 4, rotation=45, fill=c_plate_dark, outline=c_magenta, width=int(1.2*f))
        draw.line([cx+ox, cy+oy, cx, cy], fill=c_magenta, width=int(1.2*f))

    draw.ellipse([cx-16*f, cy-16*f, cx+16*f, cy+16*f], outline=c_white, width=int(1.8*f))
    draw.ellipse([cx-9*f, cy-9*f, cx+9*f, cy+9*f], fill=c_plate_dark, outline=c_magenta, width=int(2*f))
    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_white, outline=c_magenta, width=int(1.5*f))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "displacer_warp.png"), "displacer_warp")

def gen_displacer_mass():
    """Mass Repulsor: cyan vortex conduits and high-density repulsor core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_plate_dark = (14, 20, 32, 255)
    c_plate_mid = (24, 36, 56, 255)
    c_cyan = (0, 245, 255, 255)
    c_white = (230, 255, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_plate_dark, outline=(8, 12, 20, 255), width=int(2*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_plate_mid)
    draw.ellipse([cx-24*f, cy-24*f, cx+24*f, cy+24*f], fill=c_plate_dark, outline=c_cyan, width=int(2*f))

    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx+ox, cy+oy, 4*f), 4, rotation=45, fill=c_plate_dark, outline=c_cyan, width=int(1.2*f))
        draw.line([cx+ox, cy+oy, cx, cy], fill=c_cyan, width=int(1.2*f))

    draw.ellipse([cx-16*f, cy-16*f, cx+16*f, cy+16*f], outline=c_cyan, width=int(1.8*f))
    draw.ellipse([cx-9*f, cy-9*f, cx+9*f, cy+9*f], fill=c_plate_dark, outline=c_white, width=int(2*f))
    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_white, outline=c_cyan, width=int(1.5*f))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "displacer_mass.png"), "displacer_mass")

# =========================================================================
# 10. FLAMETHROWER VARIANTS
# =========================================================================

def gen_flamethrower_napalm():
    """Napalm Catalyst: preserves full 8 perimeter hazard nodes, 360-deg turntable, crimson napalm chemical tanks with gold gauge lines and valve caps, 3D shaded cowl with heat vents, and intense white-hot nozzle ignition."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark_hull = (22, 16, 20, 255)
    c_mid_hull = (38, 28, 34, 255)
    c_metal_light = (85, 75, 80, 255)
    c_crimson = (245, 35, 25, 255)
    c_gold = (255, 200, 30, 255)
    c_neon_orange = (255, 120, 20, 255)
    c_white = (255, 255, 255, 255)

    # 1. Full 64x64 solid hull base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark_hull, outline=(14, 8, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid_hull)

    for ox, oy in [(-23 * f, -23 * f), (23 * f, -23 * f), (-23 * f, 23 * f), (23 * f, 23 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_dark_hull, outline=c_crimson, width=int(1.2*f))

    # 2. Central Swivel Turret Ring
    draw.ellipse([cx - 18*f, cy - 18*f, cx + 18*f, cy + 18*f], fill=c_dark_hull, outline=c_crimson, width=int(2*f))
    draw.ellipse([cx - 13*f, cy - 13*f, cx + 13*f, cy + 13*f], fill=c_mid_hull)

    # 3. Dual Napalm Canisters with Gold Level Indicators
    draw.rounded_rectangle([cx - 21*f, cy - 21*f, cx - 2*f, cy - 9*f], radius=3*f, fill=c_crimson, outline=c_dark_hull, width=int(1.8*f))
    draw.line([cx - 19*f, cy - 15*f, cx - 4*f, cy - 15*f], fill=c_gold, width=int(1.8*f))
    draw.regular_polygon((cx - 21*f, cy - 15*f, 2.5*f), 4, rotation=45, fill=c_gold)

    draw.rounded_rectangle([cx - 21*f, cy + 9*f, cx - 2*f, cy + 21*f], radius=3*f, fill=c_crimson, outline=c_dark_hull, width=int(1.8*f))
    draw.line([cx - 19*f, cy + 15*f, cx - 4*f, cy + 15*f], fill=c_gold, width=int(1.8*f))
    draw.regular_polygon((cx - 21*f, cy + 15*f, 2.5*f), 4, rotation=45, fill=c_gold)

    # 4. Projector Cannon Cowl with 3D Bevel Shading and Heat Vents
    cowl_pts = [
        (cx - 14*f, cy - 7.5*f),
        (cx + 8*f, cy - 7.5*f),
        (cx + 22*f, cy - 12*f),
        (cx + 27*f, cy - 12*f),
        (cx + 27*f, cy + 12*f),
        (cx + 22*f, cy + 12*f),
        (cx + 8*f, cy + 7.5*f),
        (cx - 14*f, cy + 7.5*f),
    ]
    draw.polygon(cowl_pts, fill=c_mid_hull, outline=c_dark_hull, width=int(2*f))
    draw.polygon([(cx - 13*f, cy - 6.5*f), (cx + 8*f, cy - 6.5*f), (cx + 22*f, cy - 10.5*f), (cx + 26*f, cy), (cx - 13*f, cy)], fill=c_metal_light)
    draw.polygon([(cx - 13*f, cy), (cx + 26*f, cy), (cx + 22*f, cy + 10.5*f), (cx + 8*f, cy + 6.5*f), (cx - 13*f, cy + 6.5*f)], fill=c_dark_hull)

    for vx in [cx - 6*f, cx, cx + 6*f]:
        draw.line([vx, cy - 5*f, vx, cy + 5*f], fill=c_neon_orange, width=int(1.5*f))

    # 5. Flared Projector Nozzle Core & Searing Ignition Flame
    draw.polygon([(cx + 22*f, cy - 10*f), (cx + 29*f, cy - 8*f), (cx + 29*f, cy + 8*f), (cx + 22*f, cy + 10*f)], fill=c_neon_orange, outline=c_crimson, width=int(1.5*f))
    draw.ellipse([cx + 22*f, cy - 5*f, cx + 30*f, cy + 5*f], fill=c_gold)
    draw.ellipse([cx + 24*f, cy - 2.5*f, cx + 29.5*f, cy + 2.5*f], fill=c_white)

    draw.ellipse([cx - 5*f, cy - 4*f, cx + 3*f, cy + 4*f], fill=c_dark_hull, outline=c_crimson, width=int(1.5*f))
    draw.ellipse([cx - 3*f, cy - 2*f, cx + 1*f, cy + 2*f], fill=c_gold)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "flamethrower_napalm.png"), "flamethrower_napalm")

def gen_flamethrower_turbo():
    """Turbo Compressor: preserves full 8 perimeter hazard nodes, 360-deg turntable, pressurized titanium/cyan fuel tanks, 3D shaded cowl with compressor cooling fins, and boosted ignition electrodes."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark_hull = (16, 20, 26, 255)
    c_mid_hull = (30, 40, 52, 255)
    c_metal_light = (70, 95, 120, 255)
    c_cyan = (0, 235, 255, 255)
    c_neon_orange = (255, 130, 20, 255)
    c_neon_yellow = (255, 220, 50, 255)
    c_white = (255, 255, 255, 255)

    # 1. Full 64x64 solid hull base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark_hull, outline=(10, 12, 18, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid_hull)

    for ox, oy in [(-23 * f, -23 * f), (23 * f, -23 * f), (-23 * f, 23 * f), (23 * f, 23 * f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5 * f), 4, rotation=45, fill=c_dark_hull, outline=c_cyan, width=int(1.2*f))

    # 2. Central Swivel Turret Ring
    draw.ellipse([cx - 18*f, cy - 18*f, cx + 18*f, cy + 18*f], fill=c_dark_hull, outline=c_cyan, width=int(2*f))
    draw.ellipse([cx - 13*f, cy - 13*f, cx + 13*f, cy + 13*f], fill=c_mid_hull)

    # 3. Pressurized Titanium Compressor Tanks with Pressure Gauges
    draw.rounded_rectangle([cx - 21*f, cy - 21*f, cx - 2*f, cy - 9*f], radius=3*f, fill=(35, 50, 68, 255), outline=c_cyan, width=int(1.8*f))
    draw.line([cx - 19*f, cy - 15*f, cx - 4*f, cy - 15*f], fill=c_cyan, width=int(1.8*f))
    draw.regular_polygon((cx - 21*f, cy - 15*f, 2.5*f), 4, rotation=45, fill=c_metal_light)

    draw.rounded_rectangle([cx - 21*f, cy + 9*f, cx - 2*f, cy + 21*f], radius=3*f, fill=(35, 50, 68, 255), outline=c_cyan, width=int(1.8*f))
    draw.line([cx - 19*f, cy + 15*f, cx - 4*f, cy + 15*f], fill=c_cyan, width=int(1.8*f))
    draw.regular_polygon((cx - 21*f, cy + 15*f, 2.5*f), 4, rotation=45, fill=c_metal_light)

    # 4. Projector Cannon Cowl with 3D Bevel Shading & Compressor Intake Fins
    cowl_pts = [
        (cx - 14*f, cy - 7.5*f),
        (cx + 8*f, cy - 7.5*f),
        (cx + 22*f, cy - 12*f),
        (cx + 27*f, cy - 12*f),
        (cx + 27*f, cy + 12*f),
        (cx + 22*f, cy + 12*f),
        (cx + 8*f, cy + 7.5*f),
        (cx - 14*f, cy + 7.5*f),
    ]
    draw.polygon(cowl_pts, fill=c_mid_hull, outline=c_dark_hull, width=int(2*f))
    draw.polygon([(cx - 13*f, cy - 6.5*f), (cx + 8*f, cy - 6.5*f), (cx + 22*f, cy - 10.5*f), (cx + 26*f, cy), (cx - 13*f, cy)], fill=c_metal_light)
    draw.polygon([(cx - 13*f, cy), (cx + 26*f, cy), (cx + 22*f, cy + 10.5*f), (cx + 8*f, cy + 6.5*f), (cx - 13*f, cy + 6.5*f)], fill=c_dark_hull)

    for vx in [cx - 6*f, cx, cx + 6*f]:
        draw.line([vx, cy - 5*f, vx, cy + 5*f], fill=c_cyan, width=int(1.5*f))

    # 5. Flared Projector Nozzle Core & Turbo Ignition Flame
    draw.polygon([(cx + 22*f, cy - 10*f), (cx + 29*f, cy - 8*f), (cx + 29*f, cy + 8*f), (cx + 22*f, cy + 10*f)], fill=c_neon_orange, outline=c_cyan, width=int(1.5*f))
    draw.ellipse([cx + 22*f, cy - 5*f, cx + 30*f, cy + 5*f], fill=c_neon_yellow)
    draw.ellipse([cx + 24*f, cy - 2.5*f, cx + 29.5*f, cy + 2.5*f], fill=c_white)

    draw.ellipse([cx - 5*f, cy - 4*f, cx + 3*f, cy + 4*f], fill=c_dark_hull, outline=c_cyan, width=int(1.5*f))
    draw.ellipse([cx - 3*f, cy - 2*f, cx + 1*f, cy + 2*f], fill=c_neon_yellow)

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "flamethrower_turbo.png"), "flamethrower_turbo")

# =========================================================================
# 11. ICE TRAP VARIANTS
# =========================================================================

def gen_ice_permafrost():
    """Permafrost: deep frost-frame, permafrost ice sheet with needle crystalline structures."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_frame = (10, 20, 32, 255)
    c_ice = (45, 110, 145, 255)
    c_cyan = (0, 245, 245, 255)
    c_white = (240, 255, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_frame, outline=(6, 12, 20, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_ice, outline=c_cyan, width=int(1.8*f))

    for ang in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(ang)
        px = cx + math.cos(rad) * 12 * f
        py = cy + math.sin(rad) * 12 * f
        draw.line([cx, cy, px, py], fill=c_white, width=int(1.5*f))

    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_white, outline=c_cyan, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "ice_trap_permafrost.png"), "ice_trap_permafrost")

def gen_ice_glaze():
    """Glaze Ice: slick mirror-ice surface with prismatic sheen lines."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_frame = (8, 24, 30, 255)
    c_ice = (70, 160, 195, 255)
    c_cyan = (0, 255, 230, 255)
    c_white = (245, 255, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_frame, outline=(4, 14, 18, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_ice, outline=c_cyan, width=int(1.8*f))
    draw.line([11*f, 11*f, sw-11*f, 11*f], fill=c_white, width=int(2.0*f))
    draw.line([11*f, 11*f, 11*f, sh-11*f], fill=c_white, width=int(2.0*f))
    draw.line([14*f, sh-14*f, sw-14*f, 14*f], fill=c_cyan, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "ice_trap_glaze.png"), "ice_trap_glaze")

# =========================================================================
# 12. POISON TRAP VARIANTS
# =========================================================================

def gen_poison_rapid():
    """Rapid Dispersion: toxic chamber with bio-green vents and quick-cycling fume slits."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (16, 20, 18, 255)
    c_purple = (185, 45, 245, 255)
    c_green = (60, 245, 100, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(10, 12, 10, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=(12, 16, 14, 255), outline=c_green, width=int(1.8*f))

    for vy in [-12*f, -4*f, 4*f, 12*f]:
        span = 14*f if abs(vy) < 8*f else 10*f
        draw.rounded_rectangle([cx-span, cy+vy-2*f, cx+span, cy+vy+2*f], radius=1.5*f, fill=c_purple, outline=c_green, width=int(1*f))
        draw.line([cx-span+2*f, cy+vy, cx+span-2*f, cy+vy], fill=(220, 255, 200, 255), width=int(1.2*f))

    draw.regular_polygon((cx, cy, 6*f), 4, rotation=45, fill=c_green, outline=c_purple, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "poison_trap_rapid.png"), "poison_trap_rapid")

def gen_poison_plume():
    """Broad Plume: quad expanded toxin eruption nozzles."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (20, 12, 28, 255)
    c_purple = (220, 45, 255, 255)
    c_bright = (250, 190, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(12, 8, 18, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=(16, 8, 24, 255), outline=c_purple, width=int(1.8*f))

    for ox, oy in [(-8*f, -8*f), (8*f, -8*f), (-8*f, 8*f), (8*f, 8*f)]:
        draw.ellipse([cx+ox-5*f, cy+oy-5*f, cx+ox+5*f, cy+oy+5*f], fill=c_purple, outline=c_bright, width=int(1.2*f))

    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_bright, outline=c_purple, width=int(1.5*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "poison_trap_plume.png"), "poison_trap_plume")

# =========================================================================
# 13. SOUL LANTERN VARIANTS
# =========================================================================

def gen_soul_split():
    """Soul Split: preserves octagonal foundation base, 4 ornate gold filigree corner brackets, mystic well chamber, 4 arched struts, and features an ornate refraction chamber with twin orbiting soul crystals channeling split beams."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (18, 20, 28, 255)
    c_stone_mid = (34, 38, 52, 255)
    c_metal_frame = (50, 58, 72, 255)
    c_gold = (245, 190, 50, 255)
    c_gold_bright = (255, 225, 120, 255)
    c_violet_aura = (90, 45, 140, 255)
    c_violet_deep = (45, 20, 75, 255)
    c_soul_cyan = (0, 235, 255, 255)
    c_soul_magenta = (235, 55, 255, 255)
    c_soul_bright = (220, 255, 255, 255)

    # 0. Background
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(10, 12, 16, 255), width=int(2.5 * f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    # 1. Octagonal foundation base
    r_base = 30 * f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_metal_frame, outline=(12, 14, 20, 255), width=int(2.5*f))
    draw.regular_polygon((cx, cy, r_base - 3.5*f), 8, rotation=22.5, fill=c_stone_mid)

    # 4 Corner Ornate Gold Filigree Brackets
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_stone_dark, outline=c_gold, width=int(1.2*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_gold_bright)

    # 2. Central Mystic Well Chamber
    draw.ellipse([cx - 18*f, cy - 18*f, cx + 18*f, cy + 18*f], fill=c_stone_dark, outline=c_gold, width=int(2*f))
    draw.ellipse([cx - 14*f, cy - 14*f, cx + 14*f, cy + 14*f], fill=c_violet_deep, outline=c_violet_aura, width=int(1.5*f))

    # 4 Arched Lantern Struts
    for i in range(4):
        ang = i * (math.pi / 2.0)
        px1 = cx + math.cos(ang) * 17 * f
        py1 = cy + math.sin(ang) * 17 * f
        px2 = cx + math.cos(ang) * 9 * f
        py2 = cy + math.sin(ang) * 9 * f
        draw.line([px1, py1, px2, py2], fill=c_metal_frame, width=int(3.0*f))
        draw.line([px1, py1, px2, py2], fill=c_gold, width=int(1.2*f))

    # 3. Concentric Split Halo Rings
    draw.ellipse([cx - 10*f, cy - 10*f, cx + 10*f, cy + 10*f], outline=c_soul_cyan, width=int(1.2*f))

    # 4. Twin Orbiting Soul Crystals (Split Refraction Foci)
    for ox in [-5.0 * f, 5.0 * f]:
        draw.regular_polygon((cx + ox, cy, 4.5*f), 4, rotation=45, fill=c_soul_cyan, outline=c_soul_magenta, width=int(1.0*f))
        draw.regular_polygon((cx + ox, cy, 2.5*f), 4, rotation=45, fill=c_soul_bright)
        draw.ellipse([cx + ox - 1.0*f, cy - 1.0*f, cx + ox + 1.0*f, cy + 1.0*f], fill=(255, 255, 255, 255))

    # Refraction bridge arc
    draw.line([cx - 5*f, cy, cx + 5*f, cy], fill=c_soul_bright, width=int(1.2*f))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "soul_lantern_split.png"), "soul_lantern_split")

def gen_soul_focus():
    """Ethereal Focus: preserves octagonal foundation base, 4 ornate gold filigree corner brackets, mystic well chamber, 4 arched struts, and features a gilded heavy focusing collar concentrating an intense pure white-cyan soul beam core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (18, 20, 28, 255)
    c_stone_mid = (34, 38, 52, 255)
    c_metal_frame = (50, 58, 72, 255)
    c_gold = (245, 190, 50, 255)
    c_gold_bright = (255, 225, 120, 255)
    c_violet_aura = (90, 45, 140, 255)
    c_violet_deep = (45, 20, 75, 255)
    c_soul_cyan = (0, 245, 255, 255)
    c_soul_bright = (210, 255, 255, 255)

    # 0. Background
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(10, 12, 16, 255), width=int(2.5 * f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    # 1. Octagonal foundation base
    r_base = 30 * f
    draw.regular_polygon((cx, cy, r_base), 8, rotation=22.5, fill=c_metal_frame, outline=(12, 14, 20, 255), width=int(2.5*f))
    draw.regular_polygon((cx, cy, r_base - 3.5*f), 8, rotation=22.5, fill=c_stone_mid)

    # 4 Corner Ornate Gold Filigree Brackets
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_stone_dark, outline=c_gold, width=int(1.2*f))
        draw.ellipse([cx + ox - 1.5*f, cy + oy - 1.5*f, cx + ox + 1.5*f, cy + oy + 1.5*f], fill=c_violet_aura)

    # 2. Central Mystic Well Chamber
    draw.ellipse([cx - 18*f, cy - 18*f, cx + 18*f, cy + 18*f], fill=c_stone_dark, outline=c_gold, width=int(2*f))
    draw.ellipse([cx - 14*f, cy - 14*f, cx + 14*f, cy + 14*f], fill=c_violet_deep, outline=c_violet_aura, width=int(1.5*f))

    # 4 Arched Lantern Struts
    for i in range(4):
        ang = i * (math.pi / 2.0)
        px1 = cx + math.cos(ang) * 17 * f
        py1 = cy + math.sin(ang) * 17 * f
        px2 = cx + math.cos(ang) * 9 * f
        py2 = cy + math.sin(ang) * 9 * f
        draw.line([px1, py1, px2, py2], fill=c_metal_frame, width=int(3.0*f))
        draw.line([px1, py1, px2, py2], fill=c_gold, width=int(1.2*f))

    # 3. Heavy Gilded Concentric Focusing Collar
    draw.ellipse([cx - 11*f, cy - 11*f, cx + 11*f, cy + 11*f], outline=c_gold, width=int(1.8*f))
    draw.ellipse([cx - 8*f, cy - 8*f, cx + 8*f, cy + 8*f], outline=c_soul_cyan, width=int(1.5*f))

    # 4. Concentrated Soul Laser Core
    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_soul_cyan, outline=(255, 255, 255, 255), width=int(1.5*f))
    draw.regular_polygon((cx, cy, 4.5*f), 4, rotation=0, fill=c_soul_bright)
    draw.ellipse([cx - 2.5*f, cy - 2.5*f, cx + 2.5*f, cy + 2.5*f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "soul_lantern_focus.png"), "soul_lantern_focus")

# =========================================================================
# 14. SPARKLER VARIANTS
# =========================================================================

def gen_sparkler_prismatic():
    """Prismatic Sparkler: preserves solid stone base, 4 corner fortification rivets, turntable ring, dual-layered emitter prongs with multi-hued prismatic emitter tip nodes and prismatic core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (20, 24, 36, 255)
    c_stone_mid = (36, 44, 64, 255)
    c_stone_light = (65, 80, 105, 255)
    c_brass_dark = (110, 80, 40, 255)
    c_brass_mid = (185, 140, 60, 255)
    c_cyan = (0, 245, 255, 255)
    c_magenta = (245, 50, 255, 255)
    c_gold = (255, 215, 40, 255)
    c_amber = (255, 140, 30, 255)

    # 1. Solid fortified stone base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(12, 16, 24, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    # 4 Corner Fortification Rivets / Mounts
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.ellipse([cx + ox - 2.5*f, cy + oy - 2.5*f, cx + ox + 2.5*f, cy + oy + 2.5*f], fill=c_stone_light, outline=c_stone_dark, width=int(1.0*f))

    # 2. Circular Brass Turntable Ring
    draw.ellipse([cx - 16*f, cy - 16*f, cx + 16*f, cy + 16*f], fill=c_stone_dark, outline=c_brass_mid, width=int(2*f))
    draw.ellipse([cx - 12*f, cy - 12*f, cx + 12*f, cy + 12*f], fill=c_stone_mid)

    # 3. 4 Prismatic Spark Emitter Prongs
    colors = [c_cyan, c_magenta, c_gold, c_amber]
    rod_len = 14 * f
    for i, angle_deg in enumerate([45, 135, 225, 315]):
        rad = math.radians(angle_deg)
        rx = cx + math.cos(rad) * rod_len
        ry = cy + math.sin(rad) * rod_len
        draw.line([cx, cy, rx, ry], fill=c_brass_dark, width=int(3.0*f))
        draw.line([cx, cy, rx, ry], fill=colors[i], width=int(1.5*f))
        draw.ellipse([rx - 2.5*f, ry - 2.5*f, rx + 2.5*f, ry + 2.5*f], fill=colors[i], outline=c_brass_dark, width=int(1.0*f))
        draw.ellipse([rx - 1.2*f, ry - 1.2*f, rx + 1.2*f, ry + 1.2*f], fill=(255, 255, 255, 255))

    # 4. Central Prismatic Spark Core
    draw.regular_polygon((cx, cy, 7.5*f), 8, rotation=22.5, fill=c_stone_dark, outline=c_cyan, width=int(1.5*f))
    draw.regular_polygon((cx, cy, 5.0*f), 4, rotation=45, fill=c_gold, outline=(255, 255, 255, 255), width=int(1.0*f))
    draw.ellipse([cx - 2.0*f, cy - 2.0*f, cx + 2.0*f, cy + 2.0*f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "sparkler_prismatic.png"), "sparkler_prismatic")

def gen_sparkler_overcharge():
    """Overcharge Sparkler: preserves solid stone base, 4 corner fortification rivets, turntable ring, dual-layered emitter prongs with gold arc nodes and violet spark core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_stone_dark = (24, 18, 36, 255)
    c_stone_mid = (44, 32, 64, 255)
    c_stone_light = (75, 55, 95, 255)
    c_brass_dark = (110, 75, 30, 255)
    c_brass_mid = (195, 145, 50, 255)
    c_violet = (205, 55, 255, 255)
    c_gold = (255, 215, 50, 255)
    c_bright = (255, 245, 180, 255)

    # 1. Solid fortified stone base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_stone_dark, outline=(14, 10, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_stone_mid)

    # 4 Corner Fortification Rivets / Mounts
    for ox, oy in [(-20*f, -20*f), (20*f, -20*f), (-20*f, 20*f), (20*f, 20*f)]:
        draw.ellipse([cx + ox - 2.5*f, cy + oy - 2.5*f, cx + ox + 2.5*f, cy + oy + 2.5*f], fill=c_stone_light, outline=c_stone_dark, width=int(1.0*f))
        draw.ellipse([cx + ox - 1.0*f, cy + oy - 1.0*f, cx + ox + 1.0*f, cy + oy + 1.0*f], fill=c_gold)

    # 2. Circular Brass Turntable Ring
    draw.ellipse([cx - 16*f, cy - 16*f, cx + 16*f, cy + 16*f], fill=c_stone_dark, outline=c_brass_mid, width=int(2*f))
    draw.ellipse([cx - 12*f, cy - 12*f, cx + 12*f, cy + 12*f], fill=c_stone_mid)

    # 3. 4 Overcharge Spark Emitter Prongs
    rod_len = 14 * f
    for angle_deg in [45, 135, 225, 315]:
        rad = math.radians(angle_deg)
        rx = cx + math.cos(rad) * rod_len
        ry = cy + math.sin(rad) * rod_len
        draw.line([cx, cy, rx, ry], fill=c_brass_dark, width=int(3.0*f))
        draw.line([cx, cy, rx, ry], fill=c_gold, width=int(1.5*f))
        draw.ellipse([rx - 2.5*f, ry - 2.5*f, rx + 2.5*f, ry + 2.5*f], fill=c_gold, outline=c_violet, width=int(1.2*f))
        draw.ellipse([rx - 1.2*f, ry - 1.2*f, rx + 1.2*f, ry + 1.2*f], fill=c_bright)

    # 4. Central Overcharged Spark Core
    draw.regular_polygon((cx, cy, 7.5*f), 8, rotation=22.5, fill=c_stone_dark, outline=c_violet, width=int(1.5*f))
    draw.regular_polygon((cx, cy, 5.0*f), 4, rotation=45, fill=c_gold, outline=c_violet, width=int(1.0*f))
    draw.ellipse([cx - 2.0*f, cy - 2.0*f, cx + 2.0*f, cy + 2.0*f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "sparkler_overcharge.png"), "sparkler_overcharge")

# =========================================================================
# 15. SPIKE TRAP VARIANTS
# =========================================================================

def gen_spike_serrated():
    """Serrated Spikes: reinforced frame, pit grating, 4x4 razor steel spikes with crimson serrations."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (28, 20, 20, 255)
    c_mid = (46, 32, 32, 255)
    c_crimson = (245, 40, 40, 255)
    c_steel = (245, 250, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(16, 10, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid)
    draw.rounded_rectangle([9*f, 9*f, sw-9*f, sh-9*f], radius=2*f, fill=(18, 12, 12, 255), outline=c_crimson, width=int(1.5*f))

    for sx in [-13*f, -4.5*f, 4.5*f, 13*f]:
        for sy in [-13*f, -4.5*f, 4.5*f, 13*f]:
            spx, spy = cx + sx, cy + sy
            draw.polygon([(spx, spy-4*f), (spx+4*f, spy), (spx, spy+4*f), (spx-4*f, spy)], fill=c_crimson, outline=c_steel, width=int(0.8*f))
            draw.ellipse([spx-0.8*f, spy-0.8*f, spx+0.8*f, spy+0.8*f], fill=(255, 255, 255, 255))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "spike_trap_serrated.png"), "spike_trap_serrated")

def gen_spike_hydraulic():
    """Hydraulic Spikes: reinforced frame, pit grating, 4x4 high-pressure golden steel spikes."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (24, 22, 18, 255)
    c_mid = (42, 38, 30, 255)
    c_gold = (245, 190, 40, 255)
    c_steel = (240, 245, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(14, 12, 10, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_mid)
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
    """Hex Tar: dark polymer pad with arcane binding runes and stasis purple glow."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (18, 14, 26, 255)
    c_tar = (24, 18, 38, 255)
    c_purple = (195, 55, 255, 255)
    c_cyan = (0, 235, 255, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(10, 8, 16, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_tar, outline=c_purple, width=int(1.8*f))
    draw.rounded_rectangle([10*f, 10*f, sw-10*f, sh-10*f], radius=1.5*f, fill=(32, 22, 50, 255))

    draw.ellipse([cx-12*f, cy-12*f, cx+12*f, cy+12*f], outline=c_purple, width=int(1.5*f))
    draw.regular_polygon((cx, cy, 7*f), 4, rotation=45, fill=c_purple, outline=c_cyan, width=int(1.2*f))
    draw.ellipse([cx-2.5*f, cy-2.5*f, cx+2.5*f, cy+2.5*f], fill=c_cyan)
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "tar_trap_hex.png"), "tar_trap_hex")

def gen_tar_acid():
    """Acidic Tar: dark polymer pad with caustic bubbling green acid wells."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_dark = (16, 20, 14, 255)
    c_tar = (20, 32, 18, 255)
    c_acid = (80, 255, 40, 255)
    c_bright = (220, 255, 120, 255)

    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_dark, outline=(8, 14, 8, 255), width=int(2*f))
    draw.rounded_rectangle([8*f, 8*f, sw-8*f, sh-8*f], radius=2.5*f, fill=c_tar, outline=c_acid, width=int(1.8*f))
    draw.rounded_rectangle([10*f, 10*f, sw-10*f, sh-10*f], radius=1.5*f, fill=(28, 44, 24, 255))

    for ox, oy, r in [(-8*f, -6*f, 3*f), (7*f, -7*f, 4*f), (-6*f, 8*f, 4.5*f), (8*f, 6*f, 3.5*f), (0, 0, 5*f)]:
        draw.ellipse([cx+ox-r, cy+oy-r, cx+ox+r, cy+oy+r], fill=c_acid, outline=c_bright, width=int(1.2*f))
    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "tar_trap_acid.png"), "tar_trap_acid")

# =========================================================================
# 17. TESLA TOWER VARIANTS
# =========================================================================

def gen_tesla_superconductor():
    """Superconductor Tesla Tower: preserves solid base, 4 Corner Conduit Lugs with 4 connecting lines to the center, conductor ring, 4 radial arc prongs, and cryogenic cyan/white crystalline spire core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (14, 22, 32, 255)
    c_base_mid = (26, 40, 60, 255)
    c_cyan = (0, 245, 255, 255)
    c_core_white = (220, 255, 255, 255)

    # 1. Full 64x64 solid base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_base_dark, outline=(8, 14, 22, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_base_mid)

    # 4 Corner Conduit Lugs with Connecting Power Lines to Center
    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_base_dark, outline=c_cyan, width=int(1.2*f))
        draw.line([cx + ox, cy + oy, cx, cy], fill=c_cyan, width=int(1.2*f))

    # 2. Central Conductor Ring
    draw.ellipse([cx - 17*f, cy - 17*f, cx + 17*f, cy + 17*f], fill=c_base_dark, outline=c_cyan, width=int(2*f))

    # 4 Radial Arc Prongs
    for i in range(4):
        ang = i * (math.pi / 2.0)
        px = cx + math.cos(ang) * 15 * f
        py = cy + math.sin(ang) * 15 * f
        draw.line([cx, cy, px, py], fill=c_core_white, width=int(2.5*f))
        draw.regular_polygon((px, py, 4*f), 4, rotation=45, fill=c_core_white, outline=c_cyan, width=int(1.2*f))

    # Central Spire Diamond Node
    draw.regular_polygon((cx, cy, 8*f), 4, rotation=45, fill=c_cyan, outline=c_core_white, width=int(1.8*f))
    draw.regular_polygon((cx, cy, 4.5*f), 4, rotation=45, fill=c_core_white, outline=c_cyan, width=int(1.2*f))

    return save_cropped_sprite(img, (64, 64), os.path.join(VARIANTS_DIR, "tesla_tower_superconductor.png"), "tesla_tower_superconductor")

def gen_tesla_overcharge():
    """Overcharge Tesla Tower: preserves solid base, 4 Corner Conduit Lugs with 4 connecting lines to the center, conductor ring, 4 radial arc prongs, and high-voltage gold/violet overcharged spire core."""
    img, draw, f, sw, sh = create_canvas(64, 64, 4)
    cx, cy = sw / 2.0, sh / 2.0

    c_base_dark = (22, 14, 32, 255)
    c_base_mid = (40, 24, 58, 255)
    c_violet = (215, 55, 255, 255)
    c_gold = (255, 215, 50, 255)
    c_core_white = (255, 250, 220, 255)

    # 1. Full 64x64 solid base
    draw.rounded_rectangle([0, 0, sw - 1, sh - 1], radius=4 * f, fill=c_base_dark, outline=(14, 8, 20, 255), width=int(2.5*f))
    draw.rounded_rectangle([3 * f, 3 * f, sw - 1 - 3 * f, sh - 1 - 3 * f], radius=3 * f, fill=c_base_mid)

    # 4 Corner Conduit Lugs with Connecting Power Lines to Center
    for ox, oy in [(-21*f, -21*f), (21*f, -21*f), (-21*f, 21*f), (21*f, 21*f)]:
        draw.regular_polygon((cx + ox, cy + oy, 4.5*f), 4, rotation=45, fill=c_base_dark, outline=c_gold, width=int(1.2*f))
        draw.line([cx + ox, cy + oy, cx, cy], fill=c_gold, width=int(1.2*f))

    # 2. Central Conductor Ring
    draw.ellipse([cx - 17*f, cy - 17*f, cx + 17*f, cy + 17*f], fill=c_base_dark, outline=c_violet, width=int(2*f))

    # 4 Radial Arc Prongs
    for i in range(4):
        ang = i * (math.pi / 2.0)
        px = cx + math.cos(ang) * 15 * f
        py = cy + math.sin(ang) * 15 * f
        draw.line([cx, cy, px, py], fill=c_gold, width=int(2.5*f))
        draw.regular_polygon((px, py, 4*f), 4, rotation=45, fill=c_violet, outline=c_gold, width=int(1.2*f))

    # Central Spire Diamond Node
    draw.regular_polygon((cx, cy, 8*f), 4, rotation=45, fill=c_violet, outline=c_gold, width=int(1.8*f))
    draw.regular_polygon((cx, cy, 4.5*f), 4, rotation=45, fill=c_gold, outline=c_core_white, width=int(1.2*f))

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
    gen_wind_wall_tempest()
    gen_wind_wall_vortex()
    gen_acid_wall_vitriol()
    gen_acid_wall_sludge()
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
    print("Successfully generated all 38 tower specialization variants!")

if __name__ == "__main__":
    generate_all_variants()
