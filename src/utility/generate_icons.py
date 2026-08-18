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

def generate_cancel_icon(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "icons", "cancel.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    scale = 8
    size = 64 * scale
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    
    arms = [-135, -45, 45, 135]
    L = 20.0 * scale
    W = 4.8 * scale
    tip_bevel = 3.6 * scale
    
    for ang_deg in arms:
        ang = math.radians(ang_deg)
        cos_a, sin_a = math.cos(ang), math.sin(ang)
        
        def transform(lx, ly):
            return (cx + lx * cos_a - ly * sin_a, cy + lx * sin_a + ly * cos_a)
        
        poly_lit = [
            transform(0, 0),
            transform(0, -W),
            transform(L - tip_bevel, -W),
            transform(L, 0)
        ]
        poly_shade = [
            transform(0, 0),
            transform(L, 0),
            transform(L - tip_bevel, W),
            transform(0, W)
        ]
        
        if ang_deg in [-135, -45]:
            draw.polygon(poly_lit, fill=(255, 255, 255, 255))
            draw.polygon(poly_shade, fill=(210, 225, 240, 255))
        else:
            draw.polygon(poly_lit, fill=(235, 245, 255, 255))
            draw.polygon(poly_shade, fill=(190, 210, 230, 255))
            
        draw.polygon(poly_lit + poly_shade[1:], outline=(255, 255, 255, 255), width=int(2 * scale))
        draw.line([transform(0, 0), transform(L, 0)], fill=(255, 255, 255, 255), width=int(1.5 * scale))

    # Center diamond faceted core
    diamond = [
        (cx, cy - 3.5 * scale),
        (cx + 3.5 * scale, cy),
        (cx, cy + 3.5 * scale),
        (cx - 3.5 * scale, cy)
    ]
    draw.polygon(diamond, fill=(255, 255, 255, 255), outline=(255, 255, 255, 255))
    
    out = im.resize((64, 64), Image.Resampling.LANCZOS)
    out.save(output_path)
    print(f"Generated Cancel Icon: {output_path}")
    return output_path

def generate_rotate_icon(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "icons", "rotate.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    scale = 8
    size = 64 * scale
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    
    R_out = 19.0 * scale
    R_mid = 14.5 * scale
    R_in = 10.0 * scale
    
    # Arc angles from -210 deg to 35 deg
    angles = [-210, -165, -120, -75, -30, 10, 35]
    rads = [math.radians(a) for a in angles]
    
    pts_out = [(cx + R_out * math.cos(r), cy + R_out * math.sin(r)) for r in rads]
    pts_mid = [(cx + R_mid * math.cos(r), cy + R_mid * math.sin(r)) for r in rads]
    pts_in = [(cx + R_in * math.cos(r), cy + R_in * math.sin(r)) for r in rads]
    
    for i in range(len(angles) - 1):
        poly_out = [pts_out[i], pts_out[i+1], pts_mid[i+1], pts_mid[i]]
        poly_in = [pts_mid[i], pts_mid[i+1], pts_in[i+1], pts_in[i]]
        
        if angles[i] < -90:
            fill_out = (255, 255, 255, 255)
            fill_in = (210, 230, 245, 255)
        else:
            fill_out = (235, 245, 255, 255)
            fill_in = (185, 215, 240, 255)
            
        draw.polygon(poly_out, fill=fill_out)
        draw.polygon(poly_in, fill=fill_in)
    
    # Arrowhead at end (35 deg) pointing along tangent (down-left)
    head_r = math.radians(35)
    head_cos, head_sin = math.cos(head_r), math.sin(head_r)
    tan_x, tan_y = -head_sin, head_cos
    rad_x, rad_y = head_cos, head_sin
    
    head_base_mid = (cx + R_mid * rad_x, cy + R_mid * rad_y)
    head_base_out = (cx + (R_out + 4.5 * scale) * rad_x, cy + (R_out + 4.5 * scale) * rad_y)
    head_base_in = (cx + (R_in - 4.5 * scale) * rad_x, cy + (R_in - 4.5 * scale) * rad_y)
    head_tip = (head_base_mid[0] + 15 * scale * tan_x, head_base_mid[1] + 15 * scale * tan_y)
    
    poly_head_lit = [head_base_out, head_tip, head_base_mid]
    poly_head_shade = [head_base_mid, head_tip, head_base_in]
    
    draw.polygon(poly_head_lit, fill=(255, 255, 255, 255))
    draw.polygon(poly_head_shade, fill=(190, 220, 245, 255))
    
    # Outlines
    arc_outline = pts_out + [head_base_out, head_tip, head_base_in] + list(reversed(pts_in))
    draw.polygon(arc_outline, outline=(255, 255, 255, 255), width=int(2 * scale))
    
    # Crease lines
    for i in range(len(angles) - 1):
        draw.line([pts_mid[i], pts_mid[i+1]], fill=(255, 255, 255, 255), width=int(1.5 * scale))
    draw.line([head_base_mid, head_tip], fill=(255, 255, 255, 255), width=int(1.5 * scale))
    
    # Beveled tail
    tail_poly = [pts_out[0], (cx + (R_mid + 2 * scale) * math.cos(math.radians(-220)), cy + (R_mid + 2 * scale) * math.sin(math.radians(-220))), pts_in[0]]
    draw.polygon(tail_poly, fill=(255, 255, 255, 255), outline=(255, 255, 255, 255))
    
    out = im.resize((64, 64), Image.Resampling.LANCZOS)
    out.save(output_path)
    print(f"Generated Rotate Icon: {output_path}")
    return output_path

def generate_confirm_icon(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "icons", "confirm.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    scale = 8
    size = 64 * scale
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx, cy = size / 2.0, size / 2.0
    
    v_bot_outer = (cx - 4 * scale, cy + 15 * scale)
    v_inner = (cx - 4 * scale, cy + 5 * scale)
    
    p_left_tip_bot = (cx - 19 * scale, cy)
    p_left_tip_top = (cx - 14 * scale, cy - 5 * scale)
    
    p_right_tip_top = (cx + 15 * scale, cy - 18 * scale)
    p_right_tip_bot = (cx + 20 * scale, cy - 13 * scale)
    
    mid_left = (cx - 16.5 * scale, cy - 2.5 * scale)
    mid_right = (cx + 17.5 * scale, cy - 15.5 * scale)
    mid_center = (cx - 4 * scale, cy + 10 * scale)
    
    poly_left_lit = [p_left_tip_top, v_inner, mid_center, mid_left]
    poly_left_shade = [mid_left, mid_center, v_bot_outer, p_left_tip_bot]
    
    poly_right_lit = [v_inner, p_right_tip_top, mid_right, mid_center]
    poly_right_shade = [mid_center, mid_right, p_right_tip_bot, v_bot_outer]
    
    draw.polygon(poly_left_lit, fill=(255, 255, 255, 255))
    draw.polygon(poly_left_shade, fill=(185, 235, 215, 255))
    draw.polygon(poly_right_lit, fill=(255, 255, 255, 255))
    draw.polygon(poly_right_shade, fill=(185, 235, 215, 255))
    
    outline = [p_left_tip_top, v_inner, p_right_tip_top, p_right_tip_bot, v_bot_outer, p_left_tip_bot]
    draw.polygon(outline, outline=(255, 255, 255, 255), width=int(2 * scale))
    
    draw.line([mid_left, mid_center], fill=(255, 255, 255, 255), width=int(1.5 * scale))
    draw.line([mid_center, mid_right], fill=(255, 255, 255, 255), width=int(1.5 * scale))
    
    out = im.resize((64, 64), Image.Resampling.LANCZOS)
    out.save(output_path)
    print(f"Generated Confirm Icon: {output_path}")
    return output_path

if __name__ == "__main__":
    generate_lives_icon()
    generate_energy_icon()
    generate_build_icon()
    generate_cancel_icon()
    generate_rotate_icon()
    generate_confirm_icon()
