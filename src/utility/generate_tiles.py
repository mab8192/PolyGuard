#!/usr/bin/env python3
"""
generate_tiles.py
Generates 64x64 grid-aligned floor tile pads (Spawner, Exit) for Poly Guard 2D.
"""

import os
from PIL import Image, ImageDraw

def get_project_root() -> str:
    current_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(current_dir, "..", ".."))

def generate_spawner_tile(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "utility", "spawner.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    size = 64
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    
    # 1. Full 64x64 square base floor plate
    draw.rectangle([0, 0, 63, 63], fill=(28, 32, 40, 255))
    
    # 2. Beveled tile edge (subtle 3D floor tile bevel)
    draw.line([(0, 0), (63, 0)], fill=(45, 52, 65, 255), width=1)
    draw.line([(0, 0), (0, 63)], fill=(45, 52, 65, 255), width=1)
    draw.line([(63, 0), (63, 63)], fill=(16, 18, 24, 255), width=1)
    draw.line([(0, 63), (63, 63)], fill=(16, 18, 24, 255), width=1)
    
    # 3. Outer hazard boundary line (inset by 4px)
    draw.rectangle([4, 4, 59, 59], outline=(220, 45, 65, 255), width=2)
    
    # 4. Corner hazard accents
    for x0, y0, x1, y1 in [
        (4, 4, 12, 12),
        (51, 4, 59, 12),
        (4, 51, 12, 59),
        (51, 51, 59, 59)
    ]:
        draw.rectangle([x0, y0, x1, y1], fill=(180, 35, 50, 255))
    
    # 5. Middle zone floor pad (concentric square)
    draw.rectangle([16, 16, 47, 47], fill=(42, 18, 24, 255), outline=(255, 65, 85, 255), width=2)
    
    # 6. Inner portal recess
    draw.rectangle([24, 24, 39, 39], fill=(18, 8, 12, 255), outline=(255, 80, 100, 255), width=1)
    
    # 7. Center glyph / cross
    draw.line([(31, 27), (31, 36)], fill=(255, 120, 140, 255), width=2)
    draw.line([(27, 31), (36, 31)], fill=(255, 120, 140, 255), width=2)
    
    im.save(output_path)
    print(f"Generated Spawner Tile: {output_path}")
    return output_path

def generate_exit_tile(output_path: str = None) -> str:
    if output_path is None:
        output_path = os.path.join(get_project_root(), "src", "textures", "utility", "exit.png")
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    size = 64
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    
    # 1. Full 64x64 square base floor plate
    draw.rectangle([0, 0, 63, 63], fill=(24, 32, 42, 255))
    
    # 2. Beveled tile edge (subtle 3D floor tile bevel)
    draw.line([(0, 0), (63, 0)], fill=(40, 52, 68, 255), width=1)
    draw.line([(0, 0), (0, 63)], fill=(40, 52, 68, 255), width=1)
    draw.line([(63, 0), (63, 63)], fill=(14, 18, 26, 255), width=1)
    draw.line([(0, 63), (63, 63)], fill=(14, 18, 26, 255), width=1)
    
    # 3. Outer sanctuary boundary line (inset by 4px)
    draw.rectangle([4, 4, 59, 59], outline=(0, 220, 240, 255), width=2)
    
    # 4. Corner sanctuary node accents
    for x0, y0, x1, y1 in [
        (4, 4, 12, 12),
        (51, 4, 59, 12),
        (4, 51, 12, 59),
        (51, 51, 59, 59)
    ]:
        draw.rectangle([x0, y0, x1, y1], fill=(0, 160, 180, 255))
    
    # 5. Middle zone floor pad (concentric square)
    draw.rectangle([16, 16, 47, 47], fill=(16, 42, 54, 255), outline=(0, 245, 255, 255), width=2)
    
    # 6. Inner sanctuary recess
    draw.rectangle([24, 24, 39, 39], fill=(8, 22, 30, 255), outline=(0, 245, 255, 255), width=1)
    
    # 7. Center glyph / cross
    draw.line([(31, 27), (31, 36)], fill=(200, 255, 255, 255), width=2)
    draw.line([(27, 31), (36, 31)], fill=(200, 255, 255, 255), width=2)
    
    im.save(output_path)
    print(f"Generated Exit Tile: {output_path}")
    return output_path

if __name__ == "__main__":
    generate_spawner_tile()
    generate_exit_tile()
