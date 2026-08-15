#!/usr/bin/env python3
"""
generate_icons.py
Generates in-game HUD & UI icons for Poly Guard 2D (Lives, Energy, Build, etc.).
"""

import os
import math
from PIL import Image, ImageDraw

def get_project_root() -> str:
    # 2 levels up from src/utility/ -> project root
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(current_dir, "..", ".."))

def generate_lives_icon(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "icons", "lives.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    scale = 8
    size = 64 * scale
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    
    # Polygonal geometric heart vertices
    pts_left = [
        (cx, cy + 22 * scale),              # bottom tip
        (cx - 22 * scale, cy - 2 * scale),  # bottom-left outer
        (cx - 24 * scale, cy - 14 * scale), # left shoulder
        (cx - 16 * scale, cy - 23 * scale), # top-left peak
        (cx - 6 * scale, cy - 22 * scale),  # top-left inner
        (cx, cy - 12 * scale),              # center top cleft
    ]
    pts_right = [
        (cx, cy - 12 * scale),              # center top cleft
        (cx + 6 * scale, cy - 22 * scale),  # top-right inner
        (cx + 16 * scale, cy - 23 * scale), # top-right peak
        (cx + 24 * scale, cy - 14 * scale), # right shoulder
        (cx + 22 * scale, cy - 2 * scale),  # bottom-right outer
        (cx, cy + 22 * scale),              # bottom tip
    ]
    full_poly = pts_left + pts_right[1:-1]
    
    # Left highlighted facet (Bright Coral / Ruby)
    draw.polygon(pts_left, fill=(255, 65, 90, 255))
    # Right shaded facet (Deep Crimson)
    draw.polygon(pts_right, fill=(205, 30, 60, 255))
    
    # Top-left gleam facet
    inner_hl = [
        (cx - 4 * scale, cy - 12 * scale),
        (cx - 14 * scale, cy - 20 * scale),
        (cx - 20 * scale, cy - 13 * scale),
        (cx - 12 * scale, cy - 4 * scale),
    ]
    draw.polygon(inner_hl, fill=(255, 125, 145, 255))
    
    # Crisp high-contrast neon outline & center spine
    draw.polygon(full_poly, outline=(255, 200, 215, 255), width=int(2 * scale))
    draw.line([(cx, cy - 12 * scale), (cx, cy + 22 * scale)], fill=(255, 160, 180, 255), width=int(1.5 * scale))
    
    out = im.resize((64, 64), Image.Resampling.LANCZOS)
    out.save(output_path)
    print(f"Generated Lives Icon: {output_path}")
    return output_path

def generate_energy_icon(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "icons", "energy.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    scale = 8
    size = 64 * scale
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    
    # Symmetrical, perfectly balanced geometric lightning bolt
    p1 = (38 * scale, 6 * scale)   # Top peak
    p2 = (18 * scale, 30 * scale)  # Left outer corner
    p3 = (32 * scale, 30 * scale)  # Left inner notch
    p4 = (26 * scale, 58 * scale)  # Bottom strike tip
    p5 = (46 * scale, 34 * scale)  # Right outer corner
    p6 = (32 * scale, 34 * scale)  # Right inner notch
    
    poly_left = [p1, p2, p3, p4]
    poly_right = [p1, p4, p5, p6]
    outline = [p1, p2, p3, p4, p5, p6]
    
    # Left face (Bright Electric Cyan)
    draw.polygon(poly_left, fill=(0, 235, 255, 255))
    # Right face (Shaded Deep Cyan)
    draw.polygon(poly_right, fill=(0, 145, 185, 255))
    
    # Crisp high-contrast pale outline
    draw.polygon(outline, outline=(230, 255, 255, 255), width=int(2 * scale))
    # Center spine crease
    draw.line([p1, p4], fill=(255, 255, 255, 255), width=int(1.5 * scale))
    
    out = im.resize((64, 64), Image.Resampling.LANCZOS)
    out.save(output_path)
    print(f"Generated Energy Icon: {output_path}")
    return output_path

def generate_build_icon(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "icons", "build.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    scale = 8
    size = 64 * scale
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    
    ang = math.radians(-45) # 45-degree angle pointing up-right
    cos_a = math.cos(ang)
    sin_a = math.sin(ang)
    
    def rot(lx, ly):
        gx = cx + (lx * cos_a - ly * sin_a) * scale
        gy = cy + (lx * sin_a + ly * cos_a) * scale
        return (gx, gy)
        
    # Handle
    h_top = [rot(-22, -3.5), rot(10, -3.5), rot(10, 0), rot(-22, 0)]
    h_bot = [rot(-22, 0), rot(10, 0), rot(10, 3.5), rot(-22, 3.5)]
    h_grip = [rot(-22, -4.5), rot(-14, -4.5), rot(-14, 4.5), rot(-22, 4.5)]
    
    draw.polygon(h_top, fill=(195, 140, 75, 255))
    draw.polygon(h_bot, fill=(140, 90, 40, 255))
    draw.polygon(h_grip, fill=(60, 65, 75, 255))
    
    # Head
    cap = [rot(2, -18), rot(18, -18), rot(18, -14), rot(2, -14)]
    head_top = [rot(2, -14), rot(10, -14), rot(10, 10), rot(2, 10)]
    head_bot = [rot(10, -14), rot(18, -14), rot(18, 10), rot(10, 10)]
    wedge_top = [rot(2, 10), rot(10, 10), rot(10, 18), rot(6, 18)]
    wedge_bot = [rot(10, 10), rot(18, 10), rot(14, 18), rot(10, 18)]
    
    draw.polygon(cap, fill=(235, 245, 255, 255))
    draw.polygon(head_top, fill=(185, 205, 225, 255))
    draw.polygon(head_bot, fill=(115, 135, 155, 255))
    draw.polygon(wedge_top, fill=(210, 225, 240, 255))
    draw.polygon(wedge_bot, fill=(90, 110, 130, 255))
    
    # Outlines & Creases
    outline_head = [rot(2, -18), rot(18, -18), rot(18, 10), rot(14, 18), rot(6, 18), rot(2, 10)]
    draw.polygon(outline_head, outline=(255, 255, 255, 255), width=int(2 * scale))
    draw.polygon(h_top + h_bot, outline=(255, 255, 255, 255), width=int(1.8 * scale))
    draw.line([rot(10, -14), rot(10, 18)], fill=(255, 255, 255, 255), width=int(1.5 * scale))
    
    out = im.resize((64, 64), Image.Resampling.LANCZOS)
    out.save(output_path)
    print(f"Generated Build Icon: {output_path}")
    return output_path

if __name__ == "__main__":
    generate_lives_icon()
    generate_energy_icon()
    generate_build_icon()
