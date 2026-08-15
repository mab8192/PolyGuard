#!/usr/bin/env python3
"""
generate_towers.py
Generates tower & trap textures for Poly Guard 2D.
"""

import os
from PIL import Image, ImageDraw

def get_project_root() -> str:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(current_dir, "..", ".."))

def generate_arrow_wall_texture(output_path: str = None) -> str:
    """
    Generates a 16x64 thin directional arrow wall barricade texture.
    Faces right (+X direction) with 4 arrow firing embrasures, iron spine,
    and steel reinforcement brackets.
    """
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "towers", "arrow_wall.png")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    width, height = 16, 64
    scale = 8
    sw, sh = width * scale, height * scale

    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Color palette matching Poly Guard 2D wooden & steel structures
    c_wood_dark = (55, 28, 10, 255)
    c_wood_mid = (95, 52, 18, 255)
    c_wood_light = (145, 84, 32, 255)
    c_wood_highlight = (185, 115, 50, 255)

    c_iron_dark = (24, 26, 32, 255)
    c_iron_mid = (45, 50, 60, 255)
    c_iron_light = (90, 100, 120, 255)
    c_iron_highlight = (160, 175, 200, 255)

    c_slit_dark = (12, 12, 16, 255)
    c_arrow_steel = (225, 238, 250, 255)
    c_cyan_accent = (0, 230, 210, 255)

    s = scale

    # 1. Main outer wall body (beveled wood perimeter)
    draw.rounded_rectangle([1 * s, 1 * s, 15 * s - 1, 63 * s - 1], radius=2 * s, fill=c_wood_dark, outline=c_iron_dark, width=int(1.2 * s))
    draw.rounded_rectangle([2 * s, 2 * s, 14 * s - 1, 62 * s - 1], radius=1.5 * s, fill=c_wood_mid)

    # Bevel lighting (top-left light source)
    draw.line([2 * s, 2 * s, 14 * s, 2 * s], fill=c_wood_highlight, width=int(1.5 * s))
    draw.line([2 * s, 2 * s, 2 * s, 62 * s], fill=c_wood_light, width=int(1.5 * s))
    draw.line([2 * s, 62 * s, 14 * s, 62 * s], fill=c_wood_dark, width=int(1.5 * s))

    # 2. Reinforced Iron Spine on back wall (Left, X: 1.5..4.5)
    draw.rectangle([1.5 * s, 4 * s, 4.5 * s, 60 * s], fill=c_iron_mid, outline=c_iron_dark, width=int(0.8 * s))
    draw.line([2 * s, 4 * s, 2 * s, 60 * s], fill=c_iron_light, width=int(0.8 * s))

    # Iron Rivets along the spine
    bolt_ys = [8 * s, 22 * s, 36 * s, 50 * s, 56 * s]
    for by in bolt_ys:
        draw.ellipse([2.5 * s, by - 0.8 * s, 4 * s, by + 0.8 * s], fill=c_iron_highlight)

    # 3. Horizontal Steel Brackets dividing firing tiers
    bracket_ys = [16 * s, 32 * s, 48 * s]
    for bky in bracket_ys:
        draw.rectangle([1.5 * s, bky - 1.2 * s, 14.5 * s, bky + 1.2 * s], fill=c_iron_mid, outline=c_iron_dark, width=int(0.6 * s))
        draw.line([2 * s, bky - 0.6 * s, 14 * s, bky - 0.6 * s], fill=c_iron_light, width=int(0.6 * s))
        draw.ellipse([7 * s, bky - 0.6 * s, 8.5 * s, bky + 0.6 * s], fill=c_iron_highlight)

    # 4. Firing Embrasures / Slits (4 slots pointing +X toward the right)
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
        draw.polygon(slit_pts, fill=c_slit_dark, outline=c_iron_dark, width=int(0.8 * s))

        # Inner shadowed embrasure chamber
        draw.polygon([
            (7 * s, sy - 2 * s),
            (12 * s, sy - 1.2 * s),
            (13 * s, sy),
            (12 * s, sy + 1.2 * s),
            (7 * s, sy + 2 * s),
        ], fill=(0, 0, 0, 255))

        # Primed Arrow Tip emerging toward the right (+X)
        arrow_tip = [
            (9 * s, sy - 1.5 * s),
            (15.2 * s, sy),
            (9 * s, sy + 1.5 * s),
            (10.5 * s, sy),
        ]
        draw.polygon(arrow_tip, fill=c_arrow_steel, outline=c_iron_dark, width=int(0.5 * s))

        # Energy accent
        draw.ellipse([8.5 * s, sy - 1 * s, 11 * s, sy + 1 * s], fill=c_cyan_accent)

    # Lanczos super-sampled downscale to 16x64
    final_img = img.resize((width, height), Image.Resampling.LANCZOS)
    final_img.save(output_path, "PNG")
    print(f"Generated arrow wall texture: {output_path} ({width}x{height})")
    return output_path

def generate_all_towers():
    generate_arrow_wall_texture()

if __name__ == "__main__":
    generate_all_towers()
