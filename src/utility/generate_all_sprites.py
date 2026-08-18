#!/usr/bin/env python3
"""
generate_all_sprites.py
Master runner script that executes all sprite generators and regenerates assets
into their respective res:// directories.

Usage:
    python3 src/utility/generate_all_sprites.py
"""

import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from generate_icons import (
    generate_lives_icon,
    generate_energy_icon,
    generate_build_icon,
    generate_cancel_icon,
    generate_rotate_icon,
    generate_confirm_icon,
)
from generate_tiles import generate_spawner_tile, generate_exit_tile
from generate_enemies import generate_all_enemies
from generate_towers import generate_all_towers
from generate_tower_variants import generate_all_variants
from generate_splash import generate_splash

def main():
    print("========================================")
    print("  Poly Guard - Sprite Generator Suite")
    print("========================================")
    
    print("\n[1/6] Generating HUD & UI Icons...")
    generate_lives_icon()
    generate_energy_icon()
    generate_build_icon()
    generate_cancel_icon()
    generate_rotate_icon()
    generate_confirm_icon()
    
    print("\n[2/6] Generating Map Floor Tiles...")
    generate_spawner_tile()
    generate_exit_tile()
    
    print("\n[3/6] Generating Enemy Sprites...")
    generate_all_enemies()

    print("\n[4/6] Generating Tower Sprites...")
    generate_all_towers()
    
    print("\n[5/6] Generating Tower Variant Sprites...")
    generate_all_variants()
    
    print("\n[6/6] Generating Splash Screen...")
    generate_splash()
    
    print("\nAll assets regenerated successfully!")

if __name__ == "__main__":
    main()
